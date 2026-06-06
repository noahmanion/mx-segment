import {
  to = segment_function.id-dfn_69fba1ebb3063f2216b6280c
  id = "dfn_69fba1ebb3063f2216b6280c"
}

resource "segment_function" "id-dfn_69fba1ebb3063f2216b6280c" {
  code          = "// MX Build · Pipedrive Destination Function\n// Segment → Pipedrive\n// v6 — 2026-06-05\n//   - normalizeCompanyId(): canonicalizes company identifiers to numeric string,\n//     decoding base64 (MTIxOQ== -> 1219) and rejecting UUIDs. This is the fix for\n//     the 6/5 NO_PERSON failures: identify was storing the UUID userId on the\n//     person's company-id field, while server events (Estimate Created,\n//     Subscription Started) search by the numeric companyId. The keys disagreed.\n//   - onIdentify / handleAccountCreated now write the NORMALIZED numeric company\n//     id to pdPersonCompanyId (never the UUID).\n//   - dealForTrackEvent() now tries every company-id-shaped key on the event,\n//     normalized, instead of a single raw value.\n//\n// v5 — 2026-05-29\n//   - clean() guard: an undefined/empty settings key can no longer poison a write\n//   - pdFetch(): every Pipedrive call checks res.ok + body.success and THROWS on\n//     failure, so Segment surfaces errors instead of showing false \"success\"\n//   - ensureTrialDeal(): single idempotent owner of trial-deal creation, called\n//     from Account Created (primary), identify (backstop), and Signed Up (backstop)\n//   - Account Created is the authoritative deal creator (server event, always has email)\n//   - structured logging on every branch; flip LOG=false to silence non-error logs\n//\n// Root-cause notes from the 5/26 outage investigation:\n//   - Signed Up (client) carries NO email, so it can never resolve a person on its own\n//   - identify (client) reliably carries email -> creates/updates the Person\n//   - Account Created (server) reliably carries email + company -> creates the Deal\n//   - deal creation must NOT depend on email being present on the Signed Up track\n//\n// KNOWN GAP (6/5): Business Details Completed carries ONLY the UUID userId, no\n// numeric companyId and no email. It therefore cannot resolve by company id with\n// this patch alone. To fix: add a searchable text PersonField (e.g.\n// pdPersonUserUuid), write event.userId to it in onIdentify, and add it to the\n// candidate list in dealForTrackEvent. Business Details only writes\n// phone/trade/sms_consent, none of which gate the ads relaunch, so it is left as\n// a clean no-op for now.\n\n// Set to false to silence informational logs (errors always log).\nconst LOG = true;\n\n// ─── HELPERS ────────────────────────────────────────────────────────────────\n\nfunction log(...args) {\n\tif (LOG) console.log(...args);\n}\n\n// Normalize a company identifier to its canonical numeric string.\n// Handles three shapes seen in the wild:\n//   \"1219\"        -> \"1219\"   (server events, properties.companyId)\n//   \"MTIxOQ==\"    -> \"1219\"   (identify traits.company_id, base64)\n//   1219          -> \"1219\"\n// Returns null for anything that doesn't resolve to a numeric string (e.g. a\n// UUID), so callers fall through to other keys rather than storing garbage.\nfunction normalizeCompanyId(raw) {\n\tif (raw === undefined || raw === null) return null;\n\tconst s = String(raw).trim();\n\tif (!s) return null;\n\t// already numeric\n\tif (/^\\d+$/.test(s)) return s;\n\t// base64? decode and check it's numeric\n\tif (/^[A-Za-z0-9+/]+={0,2}$/.test(s) && s.length % 4 === 0) {\n\t\ttry {\n\t\t\tconst decoded = Buffer.from(s, 'base64').toString('utf8');\n\t\t\tif (/^\\d+$/.test(decoded.trim())) return decoded.trim();\n\t\t} catch (_) {}\n\t}\n\t// not a company id we can normalize (e.g. a UUID)\n\treturn null;\n}\n\n// Strips keys that are literally \"undefined\"/\"null\"/\"\" (the result of a computed\n// key [settings.foo] where settings.foo was never configured) and drops null/\n// undefined values. This is the guard that prevents a single misconfigured\n// setting from 400-ing an entire create/update.\nfunction clean(obj) {\n\tconst out = {};\n\tfor (const [k, v] of Object.entries(obj)) {\n\t\tif (k === 'undefined' || k === 'null' || k === '') continue;\n\t\tif (v === undefined || v === null) continue;\n\t\tout[k] = v;\n\t}\n\treturn out;\n}\n\n// Single fetch wrapper. Throws on non-2xx or body.success === false so Segment\n// marks the invocation failed and retries, instead of silently swallowing the\n// error (which is how the 5/26 outage stayed invisible for days).\nasync function pdFetch(url, opts, label) {\n\tconst res = await fetch(url, opts);\n\tlet body = {};\n\ttry {\n\t\tbody = await res.json();\n\t} catch (_) {\n\t\tbody = {};\n\t}\n\tif (!res.ok || body.success === false) {\n\t\tconst err = body.error || body.error_info || `HTTP $${res.status}`;\n\t\tconsole.error(\n\t\t\t'PD_FAIL',\n\t\t\tlabel || '',\n\t\t\tres.status,\n\t\t\ttypeof err === 'string' ? err : JSON.stringify(err)\n\t\t);\n\t\tthrow new Error(`Pipedrive $${label || ''} failed: $${res.status} $${err}`);\n\t}\n\treturn body;\n}\n\nfunction pdUrl(path, settings, query = '') {\n\tconst sep = query ? '&' : '';\n\treturn (\n\t\t`https://$${settings.pipedriveDomain}/v1$${path}` +\n\t\t`?api_token=$${settings.pipedriveApiKey}$${sep}$${query}`\n\t);\n}\n\nasync function findPersonByEmail(email, settings) {\n\tif (!email) return null;\n\tconst body = await pdFetch(\n\t\tpdUrl(\n\t\t\t'/persons/search',\n\t\t\tsettings,\n\t\t\t`term=$${encodeURIComponent(email)}&fields=email&exact_match=true`\n\t\t),\n\t\t{ method: 'GET' },\n\t\t'findPersonByEmail'\n\t);\n\treturn body?.data?.items?.[0]?.item || null;\n}\n\nasync function findOpenDeal(personId, pipelineId, settings) {\n\tconst body = await pdFetch(\n\t\tpdUrl(`/persons/$${personId}/deals`, settings, 'status=open'),\n\t\t{ method: 'GET' },\n\t\t'findOpenDeal'\n\t);\n\treturn body?.data?.find(d => d.pipeline_id === parseInt(pipelineId)) || null;\n}\n\nasync function pipedrivePost(path, payload, settings, label) {\n\treturn pdFetch(\n\t\tpdUrl(path, settings),\n\t\t{\n\t\t\tmethod: 'POST',\n\t\t\theaders: { 'Content-Type': 'application/json' },\n\t\t\tbody: JSON.stringify(clean(payload))\n\t\t},\n\t\tlabel || `POST $${path}`\n\t);\n}\n\nasync function pipedrivePut(path, payload, settings, label) {\n\treturn pdFetch(\n\t\tpdUrl(path, settings),\n\t\t{\n\t\t\tmethod: 'PUT',\n\t\t\theaders: { 'Content-Type': 'application/json' },\n\t\t\tbody: JSON.stringify(clean(payload))\n\t\t},\n\t\tlabel || `PUT $${path}`\n\t);\n}\n\nfunction deriveChannel(utmSource) {\n\tif (!utmSource) return 'Direct';\n\tif (/google|adwords/i.test(utmSource)) return 'Google';\n\tif (/meta|facebook|instagram|fb/i.test(utmSource)) return 'Meta';\n\tif (/referr/i.test(utmSource)) return 'Referral';\n\treturn 'Other';\n}\n\n// Round robin between the configured reps by open-deal count. Falls back to the\n// first rep if the count lookups fail, rather than throwing (assignment is not\n// worth failing the whole deal create over).\nasync function getRoundRobinUserId(settings) {\n\tconst reps = [24939232, 24939254, 24577134];\n\ttry {\n\t\tconst counts = await Promise.all(\n\t\t\treps.map(async id => {\n\t\t\t\tconst body = await pdFetch(\n\t\t\t\t\tpdUrl('/deals', settings, `user_id=$${id}&status=open&limit=1`),\n\t\t\t\t\t{ method: 'GET' },\n\t\t\t\t\t'roundRobinCount'\n\t\t\t\t);\n\t\t\t\treturn {\n\t\t\t\t\tid,\n\t\t\t\t\tcount: body?.additional_data?.pagination?.total_count || 0\n\t\t\t\t};\n\t\t\t})\n\t\t);\n\t\tcounts.sort((a, b) => a.count - b.count);\n\t\treturn counts[0].id;\n\t} catch (e) {\n\t\tconsole.error('ROUND_ROBIN_FAIL', e.message);\n\t\treturn reps[0];\n\t}\n}\n\nfunction computeEngagementScore(deal, settings) {\n\tlet score = 1;\n\tif (deal[settings.pdDealActivatedAt]) score += 10;\n\tscore += Math.min((deal[settings.pdDealEstimateCount] || 0) * 5, 25);\n\tscore += Math.min((deal[settings.pdDealInvoiceCount] || 0) * 5, 25);\n\tscore += Math.min((deal[settings.pdDealPaywallViews] || 0) * 3, 15);\n\tif (deal[settings.pdDealPaymentApplicationAt]) score += 15;\n\treturn score;\n}\n\nasync function updateEngagementScore(personId, settings) {\n\tconst deal = await findOpenDeal(\n\t\tpersonId,\n\t\tsettings.pipedrivePipelineId,\n\t\tsettings\n\t);\n\tif (!deal) return;\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\t[settings.pdDealEngagementScore]: computeEngagementScore(deal, settings)\n\t\t},\n\t\tsettings,\n\t\t'updateEngagementScore'\n\t);\n}\n\n// ─── PERSON RESOLUTION ──────────────────────────────────────────────────────\n\n// Resolve a Person by email, creating one if absent. Returns the person object\n// (with .id) or null. Accepts a flat traits-like object for the create payload.\n// NOTE: traits.company_id is expected to already be normalized numeric by the\n// caller (see handleAccountCreated). resolvePerson does not normalize.\nasync function resolvePerson(email, traits, settings, tag) {\n\tlet person = await findPersonByEmail(email, settings);\n\tif (person) {\n\t\tlog('PERSON_FOUND', person.id, email, tag);\n\t\treturn person;\n\t}\n\tconst created = await pipedrivePost(\n\t\t'/persons',\n\t\t{\n\t\t\tname:\n\t\t\t\t[traits.first_name, traits.last_name].filter(Boolean).join(' ') ||\n\t\t\t\temail,\n\t\t\temail: [{ value: email, primary: true }],\n\t\t\tphone: traits.phone\n\t\t\t\t? [{ value: traits.phone, primary: true }]\n\t\t\t\t: undefined,\n\t\t\t[settings.pipedriveFieldUtmSource]: traits.utm_source,\n\t\t\t[settings.pipedriveFieldUtmMedium]: traits.utm_medium,\n\t\t\t[settings.pipedriveFieldUtmCampaign]: traits.utm_campaign,\n\t\t\t[settings.pipedriveFieldSignupSource]: traits.signup_source,\n\t\t\t[settings.pdPersonGclid]: traits.gclid,\n\t\t\t[settings.pdPersonCompanyId]: traits.company_id\n\t\t},\n\t\tsettings,\n\t\t'createPerson'\n\t);\n\tperson = created?.data || null;\n\tlog('PERSON_CREATED', person?.id, email, tag);\n\treturn person;\n}\n\n// Resolve a Person by the numeric company id stored on pdPersonCompanyId.\n// Searches custom fields via /persons/search (wrapper of /v1/itemSearch).\n// Only works if pdPersonCompanyId is a searchable field type\n// (address, varchar, text, varchar_auto, double, monetary, phone).\nasync function findPersonByCompanyId(companyId, settings) {\n\tif (!companyId) return null;\n\tconst body = await pdFetch(\n\t\tpdUrl(\n\t\t\t'/persons/search',\n\t\t\tsettings,\n\t\t\t`term=$${encodeURIComponent(companyId)}&fields=custom_fields&exact_match=true`\n\t\t),\n\t\t{ method: 'GET' },\n\t\t'findPersonByCompanyId'\n\t);\n\treturn body?.data?.items?.[0]?.item || null;\n}\n\n// ─── DEAL CREATION (single owner, idempotent) ───────────────────────────────\n\nasync function ensureTrialDeal(person, attribution, settings, tag) {\n\tif (!person?.id) {\n\t\tlog('DEAL_SKIP_NO_PERSON', tag);\n\t\treturn null;\n\t}\n\tconst label = person.primary_email || person.id;\n\tconst dealTitle = attribution.company_name || person.name || label;\n\n\tconst existing = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.pipedrivePipelineId,\n\t\tsettings\n\t);\n\tif (existing) {\n\t\tlog('DEAL_EXISTS', existing.id, label, tag);\n\t\treturn existing;\n\t}\n\n\tconst assignedUserId = await getRoundRobinUserId(settings);\n\n\tconst trialStart = new Date().toISOString().split('T')[0];\n\tconst trialEnd = (() => {\n\t\tconst d = new Date();\n\t\td.setDate(d.getDate() + 14);\n\t\treturn d.toISOString().split('T')[0];\n\t})();\n\n\tconst created = await pipedrivePost(\n\t\t'/deals',\n\t\t{\n\t\t\ttitle: `$${dealTitle}`,\n\t\t\tperson_id: person.id,\n\t\t\tuser_id: assignedUserId,\n\t\t\tstage_id: 40,\n\t\t\tpipeline_id: parseInt(settings.pipedrivePipelineId),\n\t\t\tvalue: 1188,\n\t\t\tcurrency: 'USD',\n\t\t\t[settings.pipedriveDealFieldChannel]: deriveChannel(\n\t\t\t\tattribution.utm_source\n\t\t\t),\n\t\t\t[settings.pdDealCompanySize]: attribution.company_size,\n\t\t\t[settings.pdDealTrialStartedAt]: trialStart,\n\t\t\t[settings.pdDealTrialEndsAt]: trialEnd,\n\t\t\t// UTM fields — safe no-op if settings keys aren't configured yet\n\t\t\t...(attribution.utm_source && settings.dealFieldUtmSource\n\t\t\t\t? { [settings.dealFieldUtmSource]: attribution.utm_source }\n\t\t\t\t: {}),\n\t\t\t...(attribution.utm_medium && settings.dealFieldUtmMedium\n\t\t\t\t? { [settings.dealFieldUtmMedium]: attribution.utm_medium }\n\t\t\t\t: {}),\n\t\t\t...(attribution.utm_campaign && settings.dealFieldUtmCampaign\n\t\t\t\t? { [settings.dealFieldUtmCampaign]: attribution.utm_campaign }\n\t\t\t\t: {}),\n\t\t\t...(attribution.utm_content && settings.dealFieldUtmContent\n\t\t\t\t? { [settings.dealFieldUtmContent]: attribution.utm_content }\n\t\t\t\t: {}),\n\t\t\t...(attribution.landing_page && settings.dealFieldLandingPage\n\t\t\t\t? { [settings.dealFieldLandingPage]: attribution.landing_page }\n\t\t\t\t: {})\n\t\t},\n\t\tsettings,\n\t\t'createDeal'\n\t);\n\n\tconst dealId = created?.data?.id;\n\tif (!dealId) {\n\t\tconsole.error('DEAL_CREATE_NO_ID', label, tag, JSON.stringify(created));\n\t\treturn null;\n\t}\n\tlog('DEAL_CREATED', dealId, label, tag);\n\n\tawait pipedrivePut(\n\t\t`/deals/$${dealId}`,\n\t\t{ stage_id: parseInt(settings.pipedriveStageTrialSignup) },\n\t\tsettings,\n\t\t'dealStageTransition'\n\t);\n\n\treturn created.data;\n}\n\n// ─── IDENTIFY ───────────────────────────────────────────────────────────────\n\nasync function onIdentify(event, settings) {\n\tconst traits = event.traits || {};\n\tconst email = traits.email;\n\tlog('IDENTIFY_IN', JSON.stringify({ email, userId: event.userId }));\n\tif (!email) {\n\t\tlog('IDENTIFY_NO_EMAIL');\n\t\treturn;\n\t}\n\n\tconst person = await findPersonByEmail(email, settings);\n\n\t// Store the NORMALIZED numeric company id. traits.company_id is the base64\n\t// form (MTIxOQ== -> 1219). event.userId is a UUID on client identify and will\n\t// not normalize, so it is intentionally NOT written here — writing it was the\n\t// 6/5 bug that left server events unable to resolve the person.\n\tconst normalizedCompanyId =\n\t\tnormalizeCompanyId(traits.company_id) ||\n\t\tnormalizeCompanyId(event.userId) ||\n\t\tundefined;\n\n\tconst personPayload = {\n\t\tname:\n\t\t\t[traits.first_name, traits.last_name].filter(Boolean).join(' ') || email,\n\t\temail: [{ value: email, primary: true }],\n\t\tphone: traits.phone ? [{ value: traits.phone, primary: true }] : undefined,\n\t\t[settings.pipedriveFieldUtmSource]: traits.utm_source,\n\t\t[settings.pipedriveFieldUtmMedium]: traits.utm_medium,\n\t\t[settings.pipedriveFieldUtmCampaign]: traits.utm_campaign,\n\t\t[settings.pipedriveFieldIndustry]: traits.industry,\n\t\t[settings.pipedriveFieldSignupSource]: traits.signup_source,\n\t\t[settings.pipedriveFieldIsTest]: traits.is_test ? 'Yes' : undefined,\n\t\t[settings.pdPersonCompanyId]: normalizedCompanyId,\n\t\t[settings.pdPersonGclid]: traits.gclid\n\t\t// NOTE: company_size is a DEAL field (pdDealCompanySize), not a Person\n\t\t// field. Do NOT add pdPersonCompanySize here — that key does not exist and\n\t\t// was the cause of the identify-side breakage. company_size is written on\n\t\t// the deal in ensureTrialDeal().\n\t};\n\n\tlet personId;\n\tif (person) {\n\t\tawait pipedrivePut(\n\t\t\t`/persons/$${person.id}`,\n\t\t\tpersonPayload,\n\t\t\tsettings,\n\t\t\t'updatePerson'\n\t\t);\n\t\tpersonId = person.id;\n\t\tlog('PERSON_UPDATED', personId, email);\n\t} else {\n\t\tconst created = await pipedrivePost(\n\t\t\t'/persons',\n\t\t\tpersonPayload,\n\t\t\tsettings,\n\t\t\t'createPerson'\n\t\t);\n\t\tpersonId = created?.data?.id;\n\t\tlog('PERSON_CREATED', personId, email);\n\t}\n\n\tif (!personId) {\n\t\tconsole.error('PERSON_FAIL', email);\n\t\treturn;\n\t}\n\n\t// Backstop: Account Created is the primary deal creator, but if identify\n\t// fires first (or Account Created never arrives), create here. Idempotent.\n\tawait ensureTrialDeal(\n\t\t{ id: personId, name: personPayload.name, primary_email: email },\n\t\t{ utm_source: traits.utm_source, company_size: traits.company_size },\n\t\tsettings,\n\t\t'identify'\n\t);\n}\n\n// ─── TRACK DISPATCHER ───────────────────────────────────────────────────────\n\nconst TRACK_HANDLERS = {\n\t'Account Created': handleAccountCreated,\n\t'Signed Up': handleSignedUp,\n\t'Signup Form Completed': handleSignupFormCompleted,\n\t'Onboarding Started': handleOnboardingStarted,\n\t'Onboarding Completed': handleOnboardingCompleted,\n\t'Onboarding Abandoned': handleOnboardingAbandoned,\n\t'Estimate Started': handleEstimateStarted,\n\t'Estimate Created': handleEstimateStarted,\n\t'Business Details Completed': handleBusinessDetailsCompleted,\n\t'Estimate Sent': handleEstimateSent,\n\t'Invoice Started': handleInvoiceStarted,\n\t'Invoice Sent': handleInvoiceSent,\n\t'Payment Application': handlePaymentApplication,\n\t'Paywall Viewed': handlePaywallViewed,\n\t'Subscription Started': handleSubscriptionStarted\n};\n\nasync function onTrack(event, settings) {\n\tconst name = event.event;\n\tconst handler = TRACK_HANDLERS[name];\n\tlog(\n\t\t'TRACK_IN',\n\t\tJSON.stringify({\n\t\t\tname,\n\t\t\tmatched: !!handler,\n\t\t\temailCtx: event.context?.traits?.email,\n\t\t\temailProp: event.properties?.email\n\t\t})\n\t);\n\tif (handler) await handler(event, settings);\n}\n\n// helper: pull email from a track event (properties first for server events)\nfunction trackEmail(event) {\n\treturn event.properties?.email || event.context?.traits?.email || null;\n}\n\nasync function dealForTrackEvent(event, settings, tag) {\n\tconst email = trackEmail(event);\n\n\tlet person = null;\n\n\tif (email) {\n\t\tperson = await findPersonByEmail(email, settings);\n\t}\n\n\tif (!person) {\n\t\t// Try every company-id-shaped key on the event, normalized to numeric.\n\t\tconst candidates = [\n\t\t\tnormalizeCompanyId(event.properties?.companyId),\n\t\t\tnormalizeCompanyId(event.userId),\n\t\t\tnormalizeCompanyId(event.properties?.company_id)\n\t\t].filter(Boolean);\n\t\t// de-dupe while preserving order\n\t\tconst keys = [...new Set(candidates)];\n\t\tfor (const key of keys) {\n\t\t\tlog(`$${tag}_FALLBACK_COMPANY_ID`, key);\n\t\t\tperson = await findPersonByCompanyId(key, settings);\n\t\t\tif (person) break;\n\t\t}\n\t}\n\n\tif (!person) {\n\t\tlog(\n\t\t\t`$${tag}_NO_PERSON`,\n\t\t\temail || event.properties?.companyId || event.userId\n\t\t);\n\t\treturn { email, person: null, deal: null };\n\t}\n\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.pipedrivePipelineId,\n\t\tsettings\n\t);\n\tif (!deal) {\n\t\tlog(`$${tag}_NO_DEAL`, email || person.id);\n\t\treturn { email, person, deal: null };\n\t}\n\treturn { email, person, deal };\n}\n\n// ─── TRACK HANDLERS ─────────────────────────────────────────────────────────\n\n// PRIMARY deal creator. Server event, always carries email + company.\nasync function handleAccountCreated(event, settings) {\n\tconst p = event.properties || {};\n\tconst email = trackEmail(event);\n\tif (!email) {\n\t\tlog('AC_NO_EMAIL');\n\t\treturn;\n\t}\n\tconst person = await resolvePerson(\n\t\temail,\n\t\t{\n\t\t\tfirst_name: p.first_name,\n\t\t\tlast_name: p.last_name,\n\t\t\tphone: p.phone,\n\t\t\tutm_source: p.utm_source,\n\t\t\tutm_medium: p.utm_medium,\n\t\t\tutm_campaign: p.utm_campaign,\n\t\t\tsignup_source: p.source,\n\t\t\tcompany_id:\n\t\t\t\tnormalizeCompanyId(p.companyId) || normalizeCompanyId(event.userId),\n\t\t\tgclid: p.gclid\n\t\t},\n\t\tsettings,\n\t\t'AC'\n\t);\n\tif (!person?.id) {\n\t\tconsole.error('AC_PERSON_FAIL', email);\n\t\treturn;\n\t}\n\t// If the person already existed (e.g. created by identify) make sure the\n\t// normalized company id is actually on the record. resolvePerson only writes\n\t// company_id on CREATE, so backfill it on the found path too.\n\tconst normalizedCompanyId =\n\t\tnormalizeCompanyId(p.companyId) || normalizeCompanyId(event.userId);\n\tif (normalizedCompanyId) {\n\t\tawait pipedrivePut(\n\t\t\t`/persons/$${person.id}`,\n\t\t\t{ [settings.pdPersonCompanyId]: normalizedCompanyId },\n\t\t\tsettings,\n\t\t\t'AC backfillCompanyId'\n\t\t);\n\t}\n\tawait ensureTrialDeal(\n\t\tperson,\n\t\t{\n\t\t\tutm_source: p.utm_source,\n\t\t\tcompany_size: p.company_size,\n\t\t\tcompany_name: p.companyName\n\t\t},\n\t\tsettings,\n\t\t'AccountCreated'\n\t);\n}\n\n// Backstop only. The client Signed Up event has historically NOT carried email.\n// If email is present, behaves like Account Created; if not, no-ops cleanly.\nasync function handleSignedUp(event, settings) {\n\tconst email = trackEmail(event);\n\tif (!email) {\n\t\tlog('SU_NO_EMAIL (expected for client Signed Up)');\n\t\treturn;\n\t}\n\tconst p = event.properties || {};\n\tconst campaign = event.context?.campaign || {};\n\n\tconst person = await resolvePerson(\n\t\temail,\n\t\t{\n\t\t\tfirst_name: p.first_name || event.context?.traits?.first_name,\n\t\t\tlast_name: p.last_name || event.context?.traits?.last_name,\n\t\t\tphone: p.phone,\n\t\t\tutm_source: p.utm_source,\n\t\t\tutm_medium: p.utm_medium,\n\t\t\tutm_campaign: p.utm_campaign,\n\t\t\tsignup_source: p.source\n\t\t},\n\t\tsettings,\n\t\t'SU'\n\t);\n\tif (!person?.id) {\n\t\tconsole.error('SU_PERSON_FAIL', email);\n\t\treturn;\n\t}\n\tawait ensureTrialDeal(\n\t\tperson,\n\t\t{\n\t\t\tutm_source: p.utm_source || campaign.source,\n\t\t\tutm_medium: p.utm_medium || campaign.medium,\n\t\t\tutm_campaign: p.utm_campaign || campaign.name,\n\t\t\tutm_content: p.utm_content || campaign.content,\n\t\t\tlanding_page: event.context?.page?.url || p.landing_page,\n\t\t\tcompany_size: p.company_size\n\t\t},\n\t\tsettings,\n\t\t'SignedUp'\n\t);\n}\n\nasync function handleSignupFormCompleted(event, settings) {\n\tconst email = trackEmail(event);\n\tif (!email) {\n\t\tlog('SFC_NO_EMAIL');\n\t\treturn;\n\t}\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) {\n\t\tlog('SFC_NO_PERSON', email);\n\t\treturn;\n\t}\n\tawait pipedrivePut(\n\t\t`/persons/$${person.id}`,\n\t\t{\n\t\t\t[settings.pipedriveFieldUtmSource]: event.properties?.utm_source,\n\t\t\t[settings.pipedriveFieldUtmMedium]: event.properties?.utm_medium,\n\t\t\t[settings.pipedriveFieldUtmCampaign]: event.properties?.utm_campaign,\n\t\t\t[settings.pipedriveFieldSignupSource]: event.properties?.source\n\t\t},\n\t\tsettings,\n\t\t'SFC updatePerson'\n\t);\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.pipedrivePipelineId,\n\t\tsettings\n\t);\n\tif (!deal) {\n\t\tlog('SFC_NO_DEAL', email);\n\t\treturn;\n\t}\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\t[settings.pipedriveDealFieldChannel]: deriveChannel(\n\t\t\t\tevent.properties?.utm_source\n\t\t\t)\n\t\t},\n\t\tsettings,\n\t\t'SFC updateDeal'\n\t);\n\tlog('SFC_DONE', deal.id, email);\n}\n\n// handler for data from the 2nd onboarding page.\n// NOTE (6/5): this event carries only the UUID userId, no numeric companyId and\n// no email, so dealForTrackEvent cannot resolve it by company id with the v6\n// patch. It will log BDC_NO_PERSON until a UUID person field is added. See the\n// KNOWN GAP note at the top of the file.\nasync function handleBusinessDetailsCompleted(event, settings) {\n\tconst { email, person, deal } = await dealForTrackEvent(\n\t\tevent,\n\t\tsettings,\n\t\t'BDC'\n\t);\n\tif (!person) return;\n\tconst p = event.properties || {};\n\n\tawait pipedrivePut(\n\t\t`/persons/$${person.id}`,\n\t\t{\n\t\t\tphone: p.phone ? [{ value: p.phone, primary: true }] : undefined,\n\t\t\t[settings.pipedriveFieldIndustry]: p.trade,\n\t\t\t[settings.pdPersonSmsConsent]: p.sms_consent ? 'Yes' : undefined\n\t\t},\n\t\tsettings,\n\t\t'BDC updatePerson'\n\t);\n\n\tif (deal && p.business_name) {\n\t\tawait pipedrivePut(\n\t\t\t`/deals/$${deal.id}`,\n\t\t\t{ title: `$${p.business_name} — Trial` },\n\t\t\tsettings,\n\t\t\t'BDC updateDealTitle'\n\t\t);\n\t}\n\n\tlog('BDC_DONE', person.id, email);\n}\n\nasync function handleOnboardingStarted(event, settings) {\n\tconst { person, deal } = await dealForTrackEvent(event, settings, 'OBS');\n\tif (!deal) return;\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{ stage_id: parseInt(settings.pipedriveStageOnboarded) },\n\t\tsettings,\n\t\t'OBS stage'\n\t);\n\tawait updateEngagementScore(person.id, settings);\n\tlog('OBS_DONE', deal.id);\n}\n\nasync function handleOnboardingCompleted(event, settings) {\n\tconst { person, deal } = await dealForTrackEvent(event, settings, 'OBC');\n\tif (!deal) return;\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{ stage_id: 55 },\n\t\tsettings,\n\t\t'OBC stage'\n\t);\n\tawait updateEngagementScore(person.id, settings);\n\tlog('OBC_DONE', deal.id);\n}\n\nasync function handleOnboardingAbandoned(event, settings) {\n\tconst { person, deal } = await dealForTrackEvent(event, settings, 'OBA');\n\tif (!deal) return;\n\tawait updateEngagementScore(person.id, settings);\n\tlog('OBA_DONE', deal.id);\n}\n\nasync function handleEstimateStarted(event, settings) {\n\tconst { person, deal } = await dealForTrackEvent(event, settings, 'ES');\n\tif (!deal) return;\n\tif (deal[settings.pdDealActivatedAt]) {\n\t\tlog('ES_ALREADY_ACTIVATED', deal.id);\n\t\treturn;\n\t}\n\tconst today = new Date().toISOString().split('T')[0];\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\tstage_id: parseInt(settings.pipedriveStageOnboarded),\n\t\t\t[settings.pdDealActivatedAt]: today\n\t\t},\n\t\tsettings,\n\t\t'ES activate'\n\t);\n\tawait updateEngagementScore(person.id, settings);\n\tlog('ES_DONE', deal.id);\n}\n\nasync function handleEstimateSent(event, settings) {\n\tconst { person, deal } = await dealForTrackEvent(event, settings, 'ESENT');\n\tif (!deal) return;\n\tconst today = new Date().toISOString().split('T')[0];\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\t[settings.pdDealLastEstimateAt]: today,\n\t\t\t[settings.pdDealEstimateCount]:\n\t\t\t\t(deal[settings.pdDealEstimateCount] || 0) + 1\n\t\t},\n\t\tsettings,\n\t\t'ESENT count'\n\t);\n\tawait updateEngagementScore(person.id, settings);\n\tlog('ESENT_DONE', deal.id);\n}\n\nasync function handleInvoiceStarted(event, settings) {\n\tconst { person, deal } = await dealForTrackEvent(event, settings, 'IS');\n\tif (!deal) return;\n\tawait updateEngagementScore(person.id, settings);\n\tlog('IS_DONE', deal.id);\n}\n\nasync function handleInvoiceSent(event, settings) {\n\tconst { person, deal } = await dealForTrackEvent(event, settings, 'ISENT');\n\tif (!deal) return;\n\tconst today = new Date().toISOString().split('T')[0];\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\t[settings.pdDealLastInvoiceAt]: today,\n\t\t\t[settings.pdDealLastEstimateAt]: today,\n\t\t\t[settings.pdDealInvoiceCount]:\n\t\t\t\t(deal[settings.pdDealInvoiceCount] || 0) + 1\n\t\t},\n\t\tsettings,\n\t\t'ISENT count'\n\t);\n\tawait updateEngagementScore(person.id, settings);\n\tlog('ISENT_DONE', deal.id);\n}\n\nasync function handlePaymentApplication(event, settings) {\n\tconst { person, deal } = await dealForTrackEvent(event, settings, 'PA');\n\tif (!deal) return;\n\tif (deal[settings.pdDealPaymentApplicationAt]) {\n\t\tlog('PA_ALREADY_SET', deal.id);\n\t\treturn;\n\t}\n\tconst today = new Date().toISOString().split('T')[0];\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{ [settings.pdDealPaymentApplicationAt]: today },\n\t\tsettings,\n\t\t'PA set'\n\t);\n\tawait updateEngagementScore(person.id, settings);\n\tlog('PA_DONE', deal.id);\n}\n\nasync function handlePaywallViewed(event, settings) {\n\tconst { person, deal } = await dealForTrackEvent(event, settings, 'PV');\n\tif (!deal) return;\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\t[settings.pdDealPaywallViews]:\n\t\t\t\t(deal[settings.pdDealPaywallViews] || 0) + 1\n\t\t},\n\t\tsettings,\n\t\t'PV count'\n\t);\n\tawait updateEngagementScore(person.id, settings);\n\tlog('PV_DONE', deal.id);\n}\n\nasync function handleSubscriptionStarted(event, settings) {\n\tconst { deal } = await dealForTrackEvent(event, settings, 'SS');\n\tif (!deal) return;\n\n\tlet daysInTrial = event.properties?.days_in_trial_at_conversion;\n\tif (!daysInTrial && deal[settings.pdDealTrialStartedAt]) {\n\t\tconst start = new Date(deal[settings.pdDealTrialStartedAt]);\n\t\tconst now = new Date();\n\t\tdaysInTrial = Math.floor((now - start) / (1000 * 60 * 60 * 24));\n\t}\n\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\tstage_id: 44,\n\t\t\tvalue: (event.properties?.mrr || 99) * 12,\n\t\t\t[settings.pipedriveDealFieldMrr]: event.properties?.mrr,\n\t\t\t[settings.pipedriveDealFieldPlanName]: event.properties?.plan_name,\n\t\t\t[settings.pdDealDaysInTrial]: daysInTrial\n\t\t},\n\t\tsettings,\n\t\t'SS convert'\n\t);\n\tlog('SS_DONE', deal.id);\n}\n"
  description   = null
  display_name  = null
  logo_url      = "https://cdn.filepicker.io/api/file/RmPmpcBTQZKaFeGQrdG5"
  resource_type = "DESTINATION"
  settings = [
    {
      description = ""
      label       = "pdDealChecklistCompleted"
      name        = "pdDealChecklistCompleted"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = ""
      label       = "pdDealCompanySize"
      name        = "pdDealCompanySize"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = ""
      label       = "pdDealEngagementScore"
      name        = "pdDealEngagementScore"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = ""
      label       = "pdDealInvoiceCount"
      name        = "pdDealInvoiceCount"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = ""
      label       = "pdDealLastInvoiceAt"
      name        = "pdDealLastInvoiceAt"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = ""
      label       = "pdDealPaymentApplicationAt"
      name        = "pdDealPaymentApplicationAt"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = ""
      label       = "pdDealRevenueBand"
      name        = "4Ee97B19E76069978C469661Ce39B5"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = ""
      label       = "pdDealScoreTier"
      name        = "pdDealScoreTier"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = ""
      label       = "pdPersonCompanyId"
      name        = "pdPersonCompanyId"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = ""
      label       = "pdPersonGclid"
      name        = "pdPersonGclid"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "40"
      label       = "pipedriveStageLeadIncoming"
      name        = "pipedriveStageLeadIncoming"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Account Setup pipeline ID = 8"
      label       = "Pipeline ID (Account Setup)"
      name        = "pipedrivePipelineId"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Churn Detected stage ID = 45 (Re-Engagement pipeline)"
      label       = "Stage: Churn Detected"
      name        = "pipedriveStageChurnDetected"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Lead Incoming / Qualification stage ID = 40"
      label       = "Stage: Lead Qualification"
      name        = "pipedriveStageQualification"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Onboarded stage ID = 42"
      label       = "Stage: Onboarded"
      name        = "pipedriveStageOnboarded"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Onboarding Scheduled stage ID = 55"
      label       = "Stage: Onboarding Scheduled"
      name        = "pipedriveOnboardingScheduled"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Paid Activation stage ID = 44"
      label       = "Stage: Paid Activation"
      name        = "pipedriveStagePaid"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Personal API token from Pipedrive → Personal preferences → API tab"
      label       = "Pipedrive API Key"
      name        = "pipedriveApiKey"
      required    = true
      sensitive   = true
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for Account Created Date deal field"
      label       = "Deal Field: Trial Started At"
      name        = "pdDealTrialStartedAt"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for Activated At org field — create field first then add hash"
      label       = "Org Field: Activated At"
      name        = "pdOrgActivatedAt"
      required    = false
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for Free Trial End Date deal field"
      label       = "Deal Field: Trial Ends At"
      name        = "pdDealTrialEndsAt"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for MRR deal field — create field first then add hash"
      label       = "Deal Field: MRR"
      name        = "pipedriveDealFieldMrr"
      required    = false
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for MRR org field"
      label       = "Org Field: MRR"
      name        = "pipedriveOrgFieldMrr"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for MXB Subscription Plan deal field"
      label       = "Deal Field: Plan Name"
      name        = "pipedriveDealFieldPlanName"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for Plan org field"
      label       = "Org Field: Plan"
      name        = "pipedriveOrgFieldPlan"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for Segment Company ID org field"
      label       = "Org Field: Segment Company ID"
      name        = "pdOrgSegmentCoId"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for Signup Initiated From deal field"
      label       = "Deal Field: Channel"
      name        = "pipedriveDealFieldChannel"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for Trial Ends At org field"
      label       = "Org Field: Trial Ends At"
      name        = "pdOrgTrialEndsAt"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for Trial Started At org field"
      label       = "Org Field: Trial Started At"
      name        = "pdOrgTrialStartedAt"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for UTM Campaign person field"
      label       = "Person Field: UTM Campaign"
      name        = "pipedriveFieldUtmCampaign"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for UTM Medium person field"
      label       = "Person Field: UTM Medium"
      name        = "pipedriveFieldUtmMedium"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for UTM Source person field"
      label       = "Person Field: UTM Source"
      name        = "pipedriveFieldUtmSource"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for days_in_trial deal field — create field first then add hash"
      label       = "Deal Field: Days In Trial"
      name        = "pdDealDaysInTrial"
      required    = false
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for has_referral_code person field — create field first then add hash"
      label       = "Person Field: Has Referral Code"
      name        = "pdFieldHasReferralCode"
      required    = false
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for industry person field"
      label       = "Person Field: Industry"
      name        = "pipedriveFieldIndustry"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for is_test person field — create field first then add hash"
      label       = "Person Field: Is Test"
      name        = "pipedriveFieldIsTest"
      required    = false
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for referrer_url person field"
      label       = "Person Field: Referrer URL"
      name        = "pipedriveFieldReferrerUrl"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for signup_source person field"
      label       = "Person Field: Signup Source"
      name        = "pipedriveFieldSignupSource"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for the Activated At deal field"
      label       = "Deal Field: Activated At"
      name        = "pdDealActivatedAt"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for the Estimate Count deal field"
      label       = "Deal Field: Estimate Count"
      name        = "pdDealEstimateCount"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for the Last Estimate At deal field"
      label       = "Deal Field: Last Estimate At"
      name        = "pdDealLastEstimateAt"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for the Paywall Views deal field"
      label       = "Deal Field: Paywall Views"
      name        = "pdDealPaywallViews"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Re-Engagement / Churn Recovery pipeline ID = 9"
      label       = "Pipeline: Re-Engagement"
      name        = "pdPipelineReengagement"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Trial Activation / Signup stage ID = 41"
      label       = "Stage: Trial Signup"
      name        = "pipedriveStageTrialSignup"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Trial Ending stage ID = 43"
      label       = "Stage: Trial Ending"
      name        = "pipedriveStageTrialEnding"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Trial Expired stage ID = 54"
      label       = "Stage: Trial Expired"
      name        = "pipedriveStageTrialExpired"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Your Pipedrive subdomain, e.g. mxbuild.pipedrive.com"
      label       = "Pipedrive Domain"
      name        = "pipedriveDomain"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
  ]
}