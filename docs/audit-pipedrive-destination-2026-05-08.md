# Pipedrive Destination Function — Audit & Change Report

**Date:** 2026-05-08  
**File:** `functions/dfn_69fba1ebb3063f2216b6280c.tf`  
**Scope:** Segment → Pipedrive destination function used by the MX Build Account Setup pipeline

---

## Background

The destination function receives Segment track and identify events from MX Build and writes to Pipedrive deals and persons via the Pipedrive REST API. It supports the sales workflow: trial signup → rep assignment → engagement scoring → qualification → conversion.

This audit compared the existing function against the full requirements spec and implemented all gaps in a single pass.

---

## What Was Already Working

The following handlers and helpers were present and functioning correctly. No changes were made to their core logic.

| Component | Status |
|---|---|
| `findPersonByEmail` | Correct — searches by email with exact match |
| `findOpenDeal` | Correct — filters open deals by pipeline ID |
| `pipedrivePost` / `pipedrivePut` | Correct — standard REST wrappers |
| `deriveChannel` | Correct — maps UTM source to channel label |
| `onIdentify` | Correct — upserts person with UTM and trait fields |
| `Signed Up` handler | Partially correct — see gap #4 and #5 below |
| `Signup Form Completed` handler | Partially correct — see gap #7 below |
| `Onboarding Started` handler | Correct — advances deal to stage 42 |
| `Estimate Sent` handler | Partially correct — see gap #2 below |
| `Paywall Viewed` handler | Partially correct — see gap #2 below |
| `Subscription Started` handler | Correct — advances to stage 44, writes MRR and plan |

---

## Gaps Found and Changes Made

### Gap 1 — Missing handlers: Invoice Created, Checklist Completed

**What was missing:** Neither event had a handler function, and neither was registered in the `onTrack` dispatcher. Any `Invoice Created` or `Checklist Completed` event fired by Segment was silently dropped.

**What was added:**

`handleInvoiceCreated`
- Looks up person by email → finds open deal in pipeline
- Reads `PD_DEAL_INVOICE_COUNT` from the deal (defaults to 0)
- Increments and writes the count back via PUT
- If this is the first invoice AND within 24hrs of signup, calls `updateEngagementScore` with +2 points

`handleChecklistCompleted`
- Looks up person by email → finds open deal in pipeline
- Reads `PD_DEAL_CHECKLIST_COMPLETED` from the deal
- Sets the field to `true` via PUT
- If not already completed AND within 24hrs of signup, calls `updateEngagementScore` with +2 points

Both events registered in the `onTrack` dispatcher map.

---

### Gap 2 — No engagement scoring logic

**What was missing:** The function had no concept of engagement scoring. `PD_DEAL_ENGAGEMENT_SCORE` and `PD_DEAL_SCORE_TIER` were never written anywhere. There was no 24-hour window check. Scoring signals from `Estimate Sent` and `Paywall Viewed` were being silently discarded.

**What was added:**

Four new pure functions:

```
computeScoreTier(score)
  0       → "low"
  1–3     → "mid"
  4+      → "high"

isWithin24Hours(trialStartedAt)
  Returns true if (now - trialStartedAt) < 86,400,000ms
  trialStartedAt is the date string stored in PD_DEAL_TRIAL_STARTED_AT

isHighRevenueBand(band)
  Parses the first "$XK" or "$XM" value from the revenue band string
  Returns true if the parsed value is ≥ $50K
  Explicitly handles "Under $50K" prefix as false

updateEngagementScore(deal, email, additionalPoints, settings)
  Reads current PD_DEAL_ENGAGEMENT_SCORE from the cached deal object
  Adds additionalPoints
  Writes updated score and recomputed tier to Pipedrive via PUT
  Then calls loopsPatch to sync score_tier to the Loops contact
```

Scoring hooks wired into each handler (first-occurrence only):

| Event | Points | Condition |
|---|---|---|
| Estimate Sent | +3 | First estimate AND within 24hrs |
| Invoice Created | +2 | First invoice AND within 24hrs |
| Checklist Completed | +2 | Not previously completed AND within 24hrs |
| Paywall Viewed | +1 | First view AND within 24hrs |
| Revenue band ≥$50K | +1 | Applied in `handleSignupFormCompleted` — always within 24hrs at that point |

Scoring is **incremental**: each event reads the current score from the deal object returned by `findOpenDeal`, adds its points, and writes back. Pipedrive is the accumulator. Score and tier are always recomputed and written together in a single PUT.

---

### Gap 3 — No Loops sync for score_tier

**What was missing:** There was no `loopsPatch` helper and `score_tier` was never sent to Loops. Loops had no way to route contacts into the correct email sequence based on engagement tier.

**What was added:**

```
loopsPatch(email, properties, settings)
  Guards on LOOPS_API_KEY and email presence
  PUT https://app.loops.so/api/v1/contacts/update
  Authorization: Bearer <LOOPS_API_KEY>
  Body: { email, ...properties }
```

Called from `updateEngagementScore` after every score change, and directly from `handleSignupFormCompleted` when the revenue band score point is applied. In both cases the payload is `{ score_tier: "low" | "mid" | "high" }`.

New setting added: `loopsApiKey` (sensitive).

---

### Gap 4 — No round robin rep assignment

**What was missing:** Deals were created with no `user_id`, so Pipedrive defaulted ownership to the account associated with the API token. All deals went to the same person.

**What was added:**

```
getNextRepId(settings)
  Reads PIPEDRIVE_REP_IDS — comma-separated list of Pipedrive user IDs
  If only one rep, always returns that rep
  Otherwise: fetches the 50 most recent open deals in the pipeline (sorted by add_time DESC)
  Iterates until it finds a deal whose user_id is in the rep list
  Returns repIds[(foundIndex + 1) % repIds.length]
  Falls back to repIds[0] if no prior rep-owned deals exist yet
```

The pipeline's own deals act as the state store — no external counter or database needed. The rotation is deterministic: as long as reps are assigned consistently, the sequence stays correct across function invocations.

`handleSignedUp` now calls `getNextRepId` before the deal POST and includes `user_id: parseInt(ownerId)` in the payload (omitted if `PIPEDRIVE_REP_IDS` is not set, preserving backwards compatibility).

New setting added: `pipedriveRepIds`.

---

### Gap 5 — Replit deduplication guard incomplete

**What was missing:** The existing guard in `handleSignedUp` called `findOpenDeal` which only searched for deals within the Account Setup pipeline. Deals created by Replit in a different pipeline would not be detected, so Segment would create a second deal for the same person.

**What was changed:**

Replaced the two-fetch pattern (one for Replit check, one for pipeline check) with a single `findAllOpenDeals` call that returns all open deals for the person across all pipelines.

```
findAllOpenDeals(personId, settings)
  Same endpoint as findOpenDeal but returns the full array instead of filtering
```

Logic in `handleSignedUp`:

1. Get all open deals for the person
2. Filter for deals **outside** the Account Setup pipeline
3. If any exist → log a `[WARN]` message with the email, count, and pipeline ID, then return early
4. Check for existing deals **inside** the pipeline (original dedup logic)
5. If none → proceed with deal creation

One fewer API call than before, and the guard now catches cross-pipeline duplicates.

**Important caveat:** This guard will also block deal creation for users who legitimately have an open deal in another pipeline (e.g., a returning churned user in the Re-Engagement pipeline). This is the safest behavior during the Replit transition window. Once Replit is shut off, the guard should be revisited or removed.

---

### Gap 6 — Onboarding Abandoned didn't update deal stage

**What was missing:** The handler wrote a note to the deal but made no stage change. If `handleOnboardingStarted` had already moved the deal to stage 42, the abandonment was invisible in the pipeline view.

**What was changed:**

The handler now fires two Pipedrive API calls concurrently via `Promise.all`:

1. `POST /notes` — note with last step completed (unchanged)
2. `PUT /deals/:id` — sets `stage_id` back to `PIPEDRIVE_STAGE_TRIAL_SIGNUP` (41)

This reverts the deal to the Trial Signup stage, making the abandonment visible to reps in the pipeline view. The two calls are independent and run in parallel.

---

### Gap 7 — Signup Form Completed didn't write classification fields

**What was missing:** `handleSignupFormCompleted` updated UTM fields on the person and the channel field on the deal, but did not write `trade`, `company_size`, or `revenue_band` — the three fields specified for account auto-classification.

**What was changed:**

Person PUT now also includes:
- `PIPEDRIVE_FIELD_INDUSTRY` ← `event.properties.trade` (consistent with how `onIdentify` writes industry)

Deal PUT now also includes:
- `PD_DEAL_REVENUE_BAND` ← `event.properties.revenue_band`
- `PD_DEAL_COMPANY_SIZE` ← `event.properties.company_size`

Additionally, if the revenue band qualifies as high (≥$50K), the +1 engagement score point is applied and synced to Loops in the same handler invocation rather than waiting for a subsequent scoring event.

Two new optional settings added: `pdDealRevenueBand`, `pdDealCompanySize`.

---

### Gap 8 — Six settings entries missing from Terraform

**What was missing:** The `settings` block in the Terraform resource had no entries for any of the new functionality. Deploying the updated code without corresponding settings would result in runtime errors when the function attempts to read `settings.LOOPS_API_KEY`, etc.

**Settings added:**

| HCL name | JS key | Required | Notes |
|---|---|---|---|
| `loopsApiKey` | `LOOPS_API_KEY` | Yes | Marked sensitive |
| `pipedriveRepIds` | `PIPEDRIVE_REP_IDS` | Yes | Comma-separated user IDs |
| `pdDealEngagementScore` | `PD_DEAL_ENGAGEMENT_SCORE` | Yes | Pipedrive field hash |
| `pdDealScoreTier` | `PD_DEAL_SCORE_TIER` | Yes | Pipedrive field hash |
| `pdDealInvoiceCount` | `PD_DEAL_INVOICE_COUNT` | Yes | Pipedrive field hash |
| `pdDealChecklistCompleted` | `PD_DEAL_CHECKLIST_COMPLETED` | Yes | Pipedrive field hash |
| `pdDealRevenueBand` | `PD_DEAL_REVENUE_BAND` | No | Pipedrive field hash |
| `pdDealCompanySize` | `PD_DEAL_COMPANY_SIZE` | No | Pipedrive field hash |

---

## Deployment Checklist

Before applying `terraform apply`, the following Pipedrive custom fields need to exist and their hash values need to be configured in the Segment destination settings:

- [ ] Deal field: Engagement Score (numeric)
- [ ] Deal field: Score Tier (text or single-select: low / mid / high)
- [ ] Deal field: Invoice Count (numeric)
- [ ] Deal field: Checklist Completed (boolean/checkbox)
- [ ] Deal field: Revenue Band (text) — optional but recommended
- [ ] Deal field: Company Size (text) — optional but recommended

The following settings values also need to be populated in Segment:

- [ ] `LOOPS_API_KEY` — from Loops Settings → API Keys
- [ ] `PIPEDRIVE_REP_IDS` — comma-separated Pipedrive user IDs for the rep team

---

## Files Changed

| File | Change |
|---|---|
| `functions/dfn_69fba1ebb3063f2216b6280c.tf` | Full function rewrite + 8 new settings entries |
