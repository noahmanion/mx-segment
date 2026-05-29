import {
  to = segment_function.id-dfn_69fba1ebb3063f2216b6280c
  id = "dfn_69fba1ebb3063f2216b6280c"
}

resource "segment_function" "id-dfn_69fba1ebb3063f2216b6280c" {
  code          = "// MX Build · Pipedrive Destination Function\n// Segment → Pipedrive\n// v4 — round robin assignment, Onboarding Completed handler, invoice sent fixes,\n//       company size on identify, days in trial auto-calc, stage 44 hardcoded\n\n// ─── HELPERS ────────────────────────────────────────────────────────────────\n\nasync function findPersonByEmail(email, settings) {\n\tconst res = await fetch(\n\t\t`https://$${settings.pipedriveDomain}/v1/persons/search` +\n\t\t\t`?term=$${encodeURIComponent(email)}&fields=email&exact_match=true` +\n\t\t\t`&api_token=$${settings.pipedriveApiKey}`\n\t);\n\tconst data = await res.json();\n\treturn data?.data?.items?.[0]?.item || null;\n}\n\nasync function findOpenDeal(personId, pipelineId, settings) {\n\tconst res = await fetch(\n\t\t`https://$${settings.pipedriveDomain}/v1/persons/$${personId}/deals` +\n\t\t\t`?status=open&api_token=$${settings.pipedriveApiKey}`\n\t);\n\tconst data = await res.json();\n\treturn data?.data?.find(d => d.pipeline_id === parseInt(pipelineId)) || null;\n}\n\nasync function pipedrivePost(path, payload, settings) {\n\tconst res = await fetch(\n\t\t`https://$${settings.pipedriveDomain}/v1$${path}?api_token=$${settings.pipedriveApiKey}`,\n\t\t{\n\t\t\tmethod: 'POST',\n\t\t\theaders: { 'Content-Type': 'application/json' },\n\t\t\tbody: JSON.stringify(payload)\n\t\t}\n\t);\n\treturn res.json();\n}\n\nasync function pipedrivePut(path, payload, settings) {\n\tconst res = await fetch(\n\t\t`https://$${settings.pipedriveDomain}/v1$${path}?api_token=$${settings.pipedriveApiKey}`,\n\t\t{\n\t\t\tmethod: 'PUT',\n\t\t\theaders: { 'Content-Type': 'application/json' },\n\t\t\tbody: JSON.stringify(payload)\n\t\t}\n\t);\n\treturn res.json();\n}\n\nfunction deriveChannel(utmSource) {\n\tif (!utmSource) return 'Direct';\n\tif (/google|adwords/i.test(utmSource)) return 'Google';\n\tif (/meta|facebook|instagram|fb/i.test(utmSource)) return 'Meta';\n\tif (/referr/i.test(utmSource)) return 'Referral';\n\treturn 'Other';\n}\n\n// Round robin between Diego (24939232) and Andre (24939254).\n// Fetches open deal count per rep and assigns to whoever has fewer.\n// Falls back to timestamp modulo if the API calls fail.\nasync function getRoundRobinUserId(settings) {\n\tconst reps = [24939232, 24939254, 24577134];\n\ttry {\n\t\tconst counts = await Promise.all(\n\t\t\treps.map(async id => {\n\t\t\t\tconst res = await fetch(\n\t\t\t\t\t`https://$${settings.pipedriveDomain}/v1/deals` +\n\t\t\t\t\t\t`?user_id=$${id}&status=open&limit=1&api_token=$${settings.pipedriveApiKey}`\n\t\t\t\t);\n\t\t\t\tconst data = await res.json();\n\t\t\t\treturn {\n\t\t\t\t\tid,\n\t\t\t\t\tcount: data?.additional_data?.pagination?.total_count || 0\n\t\t\t\t};\n\t\t\t})\n\t\t);\n\t\tcounts.sort((a, b) => a.count - b.count);\n\t\treturn counts[0].id;\n\t} catch (_) {\n\t\treturn reps[Date.now() % 2];\n\t}\n}\n\nfunction computeEngagementScore(deal, settings) {\n\tlet score = 1;\n\tif (deal[settings.pdDealActivatedAt]) score += 10;\n\tscore += Math.min((deal[settings.pdDealEstimateCount] || 0) * 5, 25);\n\tscore += Math.min((deal[settings.pdDealInvoiceCount] || 0) * 5, 25);\n\tscore += Math.min((deal[settings.pdDealPaywallViews] || 0) * 3, 15);\n\tif (deal[settings.pdDealPaymentApplicationAt]) score += 15;\n\treturn score;\n}\n\nasync function updateEngagementScore(deal, person, settings) {\n\tconst updatedDeal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.pipedrivePipelineId,\n\t\tsettings\n\t);\n\tif (!updatedDeal) return;\n\tawait pipedrivePut(\n\t\t`/deals/$${updatedDeal.id}`,\n\t\t{\n\t\t\t[settings.pdDealEngagementScore]: computeEngagementScore(\n\t\t\t\tupdatedDeal,\n\t\t\t\tsettings\n\t\t\t)\n\t\t},\n\t\tsettings\n\t);\n}\n\n// ─── IDENTIFY ───────────────────────────────────────────────────────────────\n\nasync function onIdentify(event, settings) {\n\tconst traits = event.traits || {};\n\tconst email = traits.email;\n\tif (!email) return;\n\n\tlet person = await findPersonByEmail(email, settings);\n\n\tconst fullName =\n\t\t[traits.first_name, traits.last_name].filter(Boolean).join(' ') || email;\n\n\tconst personPayload = {\n\t\tname: fullName,\n\t\temail: [{ value: email, primary: true }],\n\t\tphone: traits.phone ? [{ value: traits.phone, primary: true }] : undefined,\n\t\t[settings.pipedriveFieldUtmSource]: traits.utm_source,\n\t\t[settings.pipedriveFieldUtmMedium]: traits.utm_medium,\n\t\t[settings.pipedriveFieldUtmCampaign]: traits.utm_campaign,\n\t\t[settings.pipedriveFieldIndustry]: traits.industry,\n\t\t[settings.pipedriveFieldSignupSource]: traits.signup_source,\n\t\t[settings.pipedriveFieldIsTest]: traits.is_test ? 'Yes' : undefined,\n\t\t[settings.pdPersonGclid]: traits.gclid,\n\t\t[settings.pdPersonCompanySize]: traits.company_size\n\t};\n\n\tlet personId;\n\tif (person) {\n\t\tawait pipedrivePut(`/persons/$${person.id}`, personPayload, settings);\n\t\tpersonId = person.id;\n\t\tconsole.log('PERSON_UPDATED', personId, email);\n\t} else {\n\t\tconst created = await pipedrivePost('/persons', personPayload, settings);\n\t\tpersonId = created?.data?.id;\n\t\tconsole.log('PERSON_CREATED', personId, email);\n\t}\n\n\tif (!personId) {\n\t\tconsole.log('PERSON_FAIL', email);\n\t\treturn;\n\t}\n\n\t// STOPGAP: handleSignedUp can't see email on the track event.\n\t// Create the trial Deal here. Idempotent on open-deal check.\n\t// Remove this block once Signed Up track carries email reliably.\n\tconst existingDeal = await findOpenDeal(\n\t\tpersonId,\n\t\tsettings.pipedrivePipelineId,\n\t\tsettings\n\t);\n\tif (existingDeal) {\n\t\tconsole.log('DEAL_EXISTS', existingDeal.id, email);\n\t\treturn;\n\t}\n\n\tconst assignedUserId = await getRoundRobinUserId(settings);\n\tconst trialStart = new Date().toISOString().split('T')[0];\n\tconst trialEnd = (() => {\n\t\tconst d = new Date();\n\t\td.setDate(d.getDate() + 14);\n\t\treturn d.toISOString().split('T')[0];\n\t})();\n\n\tconst dealResult = await pipedrivePost(\n\t\t'/deals',\n\t\t{\n\t\t\ttitle: `$${fullName} — Trial`,\n\t\t\tperson_id: personId,\n\t\t\tuser_id: assignedUserId,\n\t\t\tstage_id: 40,\n\t\t\tpipeline_id: parseInt(settings.pipedrivePipelineId),\n\t\t\tvalue: 1188,\n\t\t\tcurrency: 'USD',\n\t\t\t[settings.pipedriveDealFieldChannel]: deriveChannel(traits.utm_source),\n\t\t\t[settings.pdDealTrialStartedAt]: trialStart,\n\t\t\t[settings.pdDealTrialEndsAt]: trialEnd\n\t\t},\n\t\tsettings\n\t);\n\n\tconst dealId = dealResult?.data?.id;\n\tif (!dealId) return;\n\n\tawait pipedrivePut(\n\t\t`/deals/$${dealId}`,\n\t\t{\n\t\t\tstage_id: parseInt(settings.pipedriveStageTrialSignup)\n\t\t},\n\t\tsettings\n\t);\n}\n\n// ─── TRACK DISPATCHER ───────────────────────────────────────────────────────\n\nasync function onTrack(event, settings) {\n\tconsole.log(\n\t\t'TRACK_IN',\n\t\tJSON.stringify({\n\t\t\tname: event.event,\n\t\t\temailCtx: event.context?.traits?.email,\n\t\t\temailProp: event.properties?.email,\n\t\t\tmatched: !!{\n\t\t\t\t'Signed Up': 1,\n\t\t\t\t'Signup Form Completed': 1,\n\t\t\t\t'Onboarding Started': 1,\n\t\t\t\t'Onboarding Completed': 1,\n\t\t\t\t'Onboarding Abandoned': 1,\n\t\t\t\t'Estimate Started': 1,\n\t\t\t\t'Estimate Sent': 1,\n\t\t\t\t'Invoice Started': 1,\n\t\t\t\t'Invoice Sent': 1,\n\t\t\t\t'Payment Application': 1,\n\t\t\t\t'Paywall Viewed': 1,\n\t\t\t\t'Subscription Started': 1\n\t\t\t}[event.event]\n\t\t})\n\t);\n\tconst handlers = {\n\t\t'Signed Up': handleSignedUp,\n\t\t'Signup Form Completed': handleSignupFormCompleted,\n\t\t'Onboarding Started': handleOnboardingStarted,\n\t\t'Onboarding Completed': handleOnboardingCompleted,\n\t\t'Onboarding Abandoned': handleOnboardingAbandoned,\n\t\t'Estimate Started': handleEstimateStarted,\n\t\t'Estimate Sent': handleEstimateSent,\n\t\t'Invoice Started': handleInvoiceStarted, // NEW\n\t\t'Invoice Sent': handleInvoiceSent, // NEW\n\t\t'Payment Application': handlePaymentApplication, // NEW\n\t\t'Paywall Viewed': handlePaywallViewed,\n\t\t'Subscription Started': handleSubscriptionStarted\n\t};\n\tconst handler = handlers[event.event];\n\tif (handler) await handler(event, settings);\n}\n\n// ─── TRACK HANDLERS ─────────────────────────────────────────────────────────\n\nasync function handleSignedUp(event, settings) {\n\tconsole.log('SU_ENTER');\n\tconsole.log(\n\t\t'SU_SETTINGS',\n\t\tJSON.stringify({\n\t\t\thasDomain: !!settings.pipedriveDomain,\n\t\t\tdomain: settings.pipedriveDomain,\n\t\t\thasKey: !!settings.pipedriveApiKey,\n\t\t\tkeyLen: (settings.pipedriveApiKey || '').length,\n\t\t\thasPipeline: !!settings.pipedrivePipelineId,\n\t\t\thasStage: !!settings.pipedriveStageTrialSignup\n\t\t})\n\t);\n\n\tconst email = event.context?.traits?.email || event.properties?.email;\n\tif (!email) {\n\t\tconsole.log('SU_NO_EMAIL');\n\t\treturn;\n\t}\n\n\tconsole.log('SU_BEFORE_FETCH', email);\n\tlet person = await findPersonByEmail(email, settings);\n\tconsole.log(\n\t\t'SU_AFTER_FETCH',\n\t\tJSON.stringify({ found: !!person, id: person?.id })\n\t);\n\n\tif (!person) {\n\t\tconst traits = event.context?.traits || {};\n\t\tconst created = await pipedrivePost(\n\t\t\t'/persons',\n\t\t\t{\n\t\t\t\tname:\n\t\t\t\t\t[traits.first_name, traits.last_name].filter(Boolean).join(' ') ||\n\t\t\t\t\temail,\n\t\t\t\temail: [{ value: email, primary: true }],\n\t\t\t\tphone: traits.phone\n\t\t\t\t\t? [{ value: traits.phone, primary: true }]\n\t\t\t\t\t: undefined\n\t\t\t},\n\t\t\tsettings\n\t\t);\n\t\tperson = created?.data;\n\t}\n\n\tif (!person) return;\n\n\tconst assignedUserId = await getRoundRobinUserId(settings);\n\n\tconst trialStart = new Date().toISOString().split('T')[0];\n\tconst trialEnd = (() => {\n\t\tconst d = new Date();\n\t\td.setDate(d.getDate() + 14);\n\t\treturn d.toISOString().split('T')[0];\n\t})();\n\n\t// Create at stage 40 (Lead Incoming) first, then immediately move to 41 (Trial Signup).\n\t// The stage transition is required to trigger Pipedrive automations — deals created\n\t// directly at stage 41 don't fire automation rules since there's no change event.\n\tconst dealResult = await pipedrivePost(\n\t\t'/deals',\n\t\t{\n\t\t\ttitle: `$${person.name || email} — Trial`,\n\t\t\tperson_id: person.id,\n\t\t\tuser_id: assignedUserId,\n\t\t\tstage_id: 40,\n\t\t\tpipeline_id: parseInt(settings.pipedrivePipelineId),\n\t\t\tvalue: 1188,\n\t\t\tcurrency: 'USD',\n\t\t\t[settings.pipedriveDealFieldChannel]: deriveChannel(\n\t\t\t\tevent.properties?.utm_source\n\t\t\t),\n\t\t\t[settings.pdDealTrialStartedAt]: trialStart,\n\t\t\t[settings.pdDealTrialEndsAt]: trialEnd\n\t\t},\n\t\tsettings\n\t);\n\n\tconst dealId = dealResult?.data?.id;\n\tif (!dealId) return;\n\n\tawait pipedrivePut(\n\t\t`/deals/$${dealId}`,\n\t\t{\n\t\t\tstage_id: parseInt(settings.pipedriveStageTrialSignup)\n\t\t},\n\t\tsettings\n\t);\n}\n\nasync function handleSignupFormCompleted(event, settings) {\n\tconst email = event.context?.traits?.email || event.properties?.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) return;\n\n\tawait pipedrivePut(\n\t\t`/persons/$${person.id}`,\n\t\t{\n\t\t\t[settings.pipedriveFieldUtmSource]: event.properties?.utm_source,\n\t\t\t[settings.pipedriveFieldUtmMedium]: event.properties?.utm_medium,\n\t\t\t[settings.pipedriveFieldUtmCampaign]: event.properties?.utm_campaign,\n\t\t\t[settings.pipedriveFieldSignupSource]: event.properties?.source\n\t\t},\n\t\tsettings\n\t);\n\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.pipedrivePipelineId,\n\t\tsettings\n\t);\n\tif (!deal) return;\n\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\t[settings.pipedriveDealFieldChannel]: deriveChannel(\n\t\t\t\tevent.properties?.utm_source\n\t\t\t)\n\t\t},\n\t\tsettings\n\t);\n}\n\nasync function handleOnboardingStarted(event, settings) {\n\tconst email = event.context?.traits?.email || event.properties?.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) return;\n\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.pipedrivePipelineId,\n\t\tsettings\n\t);\n\tif (!deal) return;\n\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\tstage_id: parseInt(settings.pipedriveStageOnboarded)\n\t\t},\n\t\tsettings\n\t);\n\n\tawait updateEngagementScore(deal, person, settings);\n}\n\n// Fires when the user completes the in-app onboarding flow.\n// Moves deal to stage 55 (Onboarding Scheduled). Human-readable name\n// of this stage may change but the ID will not.\nasync function handleOnboardingCompleted(event, settings) {\n\tconst email = event.context?.traits?.email || event.properties?.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) return;\n\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.pipedrivePipelineId,\n\t\tsettings\n\t);\n\tif (!deal) return;\n\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\tstage_id: 55\n\t\t},\n\t\tsettings\n\t);\n\n\tawait updateEngagementScore(deal, person, settings);\n}\n\nasync function handleOnboardingAbandoned(event, settings) {\n\tconst email = event.context?.traits?.email || event.properties?.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) return;\n\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.pipedrivePipelineId,\n\t\tsettings\n\t);\n\tif (!deal) return;\n\n\tawait updateEngagementScore(deal, person, settings);\n}\n\nasync function handleEstimateStarted(event, settings) {\n\tconst email = event.context?.traits?.email || event.properties?.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) return;\n\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.pipedrivePipelineId,\n\t\tsettings\n\t);\n\tif (!deal) return;\n\n\t// Activation: first time only\n\tif (deal[settings.pdDealActivatedAt]) return;\n\n\tconst today = new Date().toISOString().split('T')[0];\n\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\tstage_id: parseInt(settings.pipedriveStageOnboarded),\n\t\t\t[settings.pdDealActivatedAt]: today\n\t\t},\n\t\tsettings\n\t);\n\n\tawait updateEngagementScore(deal, person, settings);\n}\n\nasync function handleEstimateSent(event, settings) {\n\tconst email = event.context?.traits?.email || event.properties?.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) return;\n\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.pipedrivePipelineId,\n\t\tsettings\n\t);\n\tif (!deal) return;\n\n\tconst today = new Date().toISOString().split('T')[0];\n\tconst currentCount = deal[settings.pdDealEstimateCount] || 0;\n\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\t[settings.pdDealLastEstimateAt]: today,\n\t\t\t[settings.pdDealEstimateCount]: currentCount + 1\n\t\t},\n\t\tsettings\n\t);\n\n\tawait updateEngagementScore(deal, person, settings);\n}\n\n// ─── NEW: INVOICE STARTED ────────────────────────────────────────────────────\n// Mirrors Estimate Started logic. Signals the user is exploring invoicing.\n// Does NOT re-fire activation if already set — that belongs to Estimate Started.\n\nasync function handleInvoiceStarted(event, settings) {\n\tconst email = event.context?.traits?.email || event.properties?.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) return;\n\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.pipedrivePipelineId,\n\t\tsettings\n\t);\n\tif (!deal) return;\n\n\tawait updateEngagementScore(deal, person, settings);\n}\n\n// ─── NEW: INVOICE SENT ───────────────────────────────────────────────────────\n// High-intent signal: user has sent an invoice to a real client.\n// Increments counter and updates last sent timestamp.\n\nasync function handleInvoiceSent(event, settings) {\n\tconst email = event.context?.traits?.email || event.properties?.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) return;\n\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.pipedrivePipelineId,\n\t\tsettings\n\t);\n\tif (!deal) return;\n\n\tconst today = new Date().toISOString().split('T')[0];\n\tconst currentCount = deal[settings.pdDealInvoiceCount] || 0;\n\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\t[settings.pdDealLastInvoiceAt]: today,\n\t\t\t[settings.pdDealLastEstimateAt]: today,\n\t\t\t[settings.pdDealInvoiceCount]: currentCount + 1\n\t\t},\n\t\tsettings\n\t);\n\n\tawait updateEngagementScore(deal, person, settings);\n}\n\n// ─── NEW: PAYMENT APPLICATION ────────────────────────────────────────────────\n// Strongest pre-conversion signal. User has submitted payment application.\n// First-fire dedup: if already set, skip to avoid inflating the score.\n\nasync function handlePaymentApplication(event, settings) {\n\tconst email = event.context?.traits?.email || event.properties?.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) return;\n\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.pipedrivePipelineId,\n\t\tsettings\n\t);\n\tif (!deal) return;\n\n\t// Already recorded — skip\n\tif (deal[settings.pdDealPaymentApplicationAt]) return;\n\n\tconst today = new Date().toISOString().split('T')[0];\n\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\t[settings.pdDealPaymentApplicationAt]: today\n\t\t},\n\t\tsettings\n\t);\n\n\tawait updateEngagementScore(deal, person, settings);\n}\n\n// ─── PAYWALL VIEWED ──────────────────────────────────────────────────────────\n\nasync function handlePaywallViewed(event, settings) {\n\tconst email = event.context?.traits?.email || event.properties?.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) return;\n\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.pipedrivePipelineId,\n\t\tsettings\n\t);\n\tif (!deal) return;\n\n\tconst current = deal[settings.pdDealPaywallViews] || 0;\n\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\t[settings.pdDealPaywallViews]: current + 1\n\t\t},\n\t\tsettings\n\t);\n\n\tawait updateEngagementScore(deal, person, settings);\n}\n\n// ─── SUBSCRIPTION STARTED ────────────────────────────────────────────────────\n\nasync function handleSubscriptionStarted(event, settings) {\n\tconst email = event.context?.traits?.email || event.properties?.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) return;\n\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.pipedrivePipelineId,\n\t\tsettings\n\t);\n\tif (!deal) return;\n\n\t// Calculate days in trial from stored start date if not passed in event\n\tlet daysInTrial = event.properties?.days_in_trial_at_conversion;\n\tif (!daysInTrial && deal[settings.pdDealTrialStartedAt]) {\n\t\tconst start = new Date(deal[settings.pdDealTrialStartedAt]);\n\t\tconst now = new Date();\n\t\tdaysInTrial = Math.floor((now - start) / (1000 * 60 * 60 * 24));\n\t}\n\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\tstage_id: 44,\n\t\t\tvalue: (event.properties?.mrr || 99) * 12,\n\t\t\t[settings.pipedriveDealFieldMrr]: event.properties?.mrr,\n\t\t\t[settings.pipedriveDealFieldPlanName]: event.properties?.plan_name,\n\t\t\t[settings.pdDealDaysInTrial]: daysInTrial\n\t\t},\n\t\tsettings\n\t);\n}\n"
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