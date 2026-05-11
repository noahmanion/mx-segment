import {
  to = segment_function.id-dfn_69fba1ebb3063f2216b6280c
  id = "dfn_69fba1ebb3063f2216b6280c"
}

resource "segment_function" "id-dfn_69fba1ebb3063f2216b6280c" {
  code          = "// MX Build · Pipedrive Destination Function\n// Segment → Pipedrive\n// Connect to both JS and .NET sources\n\n// ─── HELPERS ────────────────────────────────────────────────────────────────\n\nasync function findPersonByEmail(email, settings) {\n\tconst res = await fetch(\n\t\t`https://$${settings.PIPEDRIVE_DOMAIN}/api/v1/persons/search` +\n\t\t\t`?term=$${encodeURIComponent(email)}&fields=email&exact_match=true` +\n\t\t\t`&api_token=$${settings.PIPEDRIVE_API_KEY}`\n\t);\n\tconst data = await res.json();\n\treturn data?.data?.items?.[0]?.item || null;\n}\n\nasync function findOpenDeal(personId, pipelineId, settings) {\n\tconst res = await fetch(\n\t\t`https://$${settings.PIPEDRIVE_DOMAIN}/api/v1/persons/$${personId}/deals` +\n\t\t\t`?status=open&api_token=$${settings.PIPEDRIVE_API_KEY}`\n\t);\n\tconst data = await res.json();\n\treturn data?.data?.find(d => d.pipeline_id === parseInt(pipelineId)) || null;\n}\n\nasync function pipedrivePost(path, payload, settings) {\n\tconst res = await fetch(\n\t\t`https://$${settings.PIPEDRIVE_DOMAIN}/api/v1$${path}?api_token=$${settings.PIPEDRIVE_API_KEY}`,\n\t\t{\n\t\t\tmethod: 'POST',\n\t\t\theaders: { 'Content-Type': 'application/json' },\n\t\t\tbody: JSON.stringify(payload)\n\t\t}\n\t);\n\treturn res.json();\n}\n\nasync function pipedrivePut(path, payload, settings) {\n\tconst res = await fetch(\n\t\t`https://$${settings.PIPEDRIVE_DOMAIN}/api/v1$${path}?api_token=$${settings.PIPEDRIVE_API_KEY}`,\n\t\t{\n\t\t\tmethod: 'PUT',\n\t\t\theaders: { 'Content-Type': 'application/json' },\n\t\t\tbody: JSON.stringify(payload)\n\t\t}\n\t);\n\treturn res.json();\n}\n\nfunction deriveChannel(utmSource) {\n\tif (!utmSource) return 'Direct';\n\tif (/google|adwords/i.test(utmSource)) return 'Google';\n\tif (/meta|facebook|instagram|fb/i.test(utmSource)) return 'Meta';\n\tif (/referr/i.test(utmSource)) return 'Referral';\n\treturn 'Other';\n}\n\n// ─── IDENTIFY ───────────────────────────────────────────────────────────────\n\nasync function onIdentify(event, settings) {\n\tconst traits = event.traits || {};\n\tconst email = traits.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\n\tconst personPayload = {\n\t\tname:\n\t\t\t[traits.first_name, traits.last_name].filter(Boolean).join(' ') || email,\n\t\temail: [{ value: email, primary: true }],\n\t\tphone: traits.phone ? [{ value: traits.phone, primary: true }] : undefined,\n\t\t[settings.PIPEDRIVE_FIELD_UTM_SOURCE]: traits.utm_source,\n\t\t[settings.PIPEDRIVE_FIELD_UTM_MEDIUM]: traits.utm_medium,\n\t\t[settings.PIPEDRIVE_FIELD_UTM_CAMPAIGN]: traits.utm_campaign,\n\t\t[settings.PIPEDRIVE_FIELD_INDUSTRY]: traits.industry,\n\t\t[settings.PIPEDRIVE_FIELD_SIGNUP_SOURCE]: traits.signup_source,\n\t\t[settings.PIPEDRIVE_FIELD_IS_TEST]: traits.is_test ? 'Yes' : undefined\n\t};\n\n\tif (person) {\n\t\tawait pipedrivePut(`/persons/$${person.id}`, personPayload, settings);\n\t} else {\n\t\tawait pipedrivePost('/persons', personPayload, settings);\n\t}\n}\n\n// ─── TRACK DISPATCHER ───────────────────────────────────────────────────────\n\nasync function onTrack(event, settings) {\n\tconst handlers = {\n\t\t'Signed Up': handleSignedUp,\n\t\t'Signup Form Completed': handleSignupFormCompleted,\n\t\t'Onboarding Started': handleOnboardingStarted,\n\t\t'Onboarding Abandoned': handleOnboardingAbandoned,\n\t\t'Estimate Sent': handleEstimateSent,\n\t\t'Paywall Viewed': handlePaywallViewed,\n\t\t'Subscription Started': handleSubscriptionStarted\n\t};\n\tconst handler = handlers[event.event];\n\tif (handler) await handler(event, settings);\n}\n\n// ─── TRACK HANDLERS ─────────────────────────────────────────────────────────\n\nasync function handleSignedUp(event, settings) {\n\tconst email = event.context?.traits?.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) return;\n\n\t// Guard against duplicate deals\n\tconst existing = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.PIPEDRIVE_PIPELINE_ID,\n\t\tsettings\n\t);\n\tif (existing) return;\n\n\tconst today = new Date();\n\tconst trialEnd = new Date(today);\n\ttrialEnd.setDate(trialEnd.getDate() + 14);\n\n\tawait pipedrivePost(\n\t\t'/deals',\n\t\t{\n\t\t\ttitle: `$${person.name || email} — Trial`,\n\t\t\tperson_id: person.id,\n\t\t\tstage_id: parseInt(settings.PIPEDRIVE_STAGE_TRIAL_SIGNUP), // 41\n\t\t\tpipeline_id: parseInt(settings.PIPEDRIVE_PIPELINE_ID), // 8\n\t\t\tvalue: 1188, // $99/mo x 12 ACV\n\t\t\tcurrency: 'USD',\n\t\t\t[settings.PD_DEAL_TRIAL_STARTED_AT]: today.toISOString().split('T')[0],\n\t\t\t[settings.PD_DEAL_TRIAL_ENDS_AT]: trialEnd.toISOString().split('T')[0]\n\t\t\t// Channel populated in handleSignupFormCompleted\n\t\t},\n\t\tsettings\n\t);\n}\n\nasync function handleSignupFormCompleted(event, settings) {\n\tconst email = event.context?.traits?.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) return;\n\n\t// Update Person with UTM and referrer data\n\tawait pipedrivePut(\n\t\t`/persons/$${person.id}`,\n\t\t{\n\t\t\t[settings.PIPEDRIVE_FIELD_UTM_SOURCE]: event.properties?.utm_source,\n\t\t\t[settings.PIPEDRIVE_FIELD_UTM_MEDIUM]: event.properties?.utm_medium,\n\t\t\t[settings.PIPEDRIVE_FIELD_UTM_CAMPAIGN]: event.properties?.utm_campaign,\n\t\t\t[settings.PIPEDRIVE_FIELD_REFERRER_URL]: event.properties?.referrer,\n\t\t\t[settings.PD_FIELD_HAS_REFERRAL_CODE]: event.properties?.has_referral_code\n\t\t\t\t? 'Yes'\n\t\t\t\t: 'No',\n\t\t\t[settings.PIPEDRIVE_FIELD_SIGNUP_SOURCE]: event.properties?.source\n\t\t},\n\t\tsettings\n\t);\n\n\t// Update Deal channel\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.PIPEDRIVE_PIPELINE_ID,\n\t\tsettings\n\t);\n\tif (!deal) return;\n\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\t[settings.PIPEDRIVE_DEAL_FIELD_CHANNEL]: deriveChannel(\n\t\t\t\tevent.properties?.utm_source\n\t\t\t)\n\t\t},\n\t\tsettings\n\t);\n}\n\nasync function handleOnboardingStarted(event, settings) {\n\tconst email = event.context?.traits?.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) return;\n\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.PIPEDRIVE_PIPELINE_ID,\n\t\tsettings\n\t);\n\tif (!deal) return;\n\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\tstage_id: parseInt(settings.PIPEDRIVE_STAGE_ONBOARDED) // 42\n\t\t},\n\t\tsettings\n\t);\n}\n\nasync function handleOnboardingAbandoned(event, settings) {\n\tconst email = event.context?.traits?.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) return;\n\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.PIPEDRIVE_PIPELINE_ID,\n\t\tsettings\n\t);\n\tif (!deal) return;\n\n\tawait pipedrivePost(\n\t\t'/notes',\n\t\t{\n\t\t\tcontent: `Onboarding abandoned at step: $${event.properties?.last_step_completed || 'unknown'}`,\n\t\t\tdeal_id: deal.id\n\t\t},\n\t\tsettings\n\t);\n}\n\nasync function handleEstimateSent(event, settings) {\n\tconst email = event.context?.traits?.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) return;\n\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.PIPEDRIVE_PIPELINE_ID,\n\t\tsettings\n\t);\n\tif (!deal) return;\n\n\tconst today = new Date().toISOString().split('T')[0];\n\tconst alreadyActivated = deal[settings.PD_DEAL_ACTIVATED_AT];\n\tconst currentCount = deal[settings.PD_DEAL_ESTIMATE_COUNT] || 0;\n\n\tconst updatePayload = {\n\t\t[settings.PD_DEAL_LAST_ESTIMATE_AT]: today,\n\t\t[settings.PD_DEAL_ESTIMATE_COUNT]: currentCount + 1\n\t};\n\n\tif (!alreadyActivated) {\n\t\tupdatePayload.stage_id = parseInt(settings.PIPEDRIVE_STAGE_ONBOARDED); // 42\n\t\tupdatePayload[settings.PD_DEAL_ACTIVATED_AT] = today;\n\t}\n\n\tawait pipedrivePut(`/deals/$${deal.id}`, updatePayload, settings);\n}\n\nasync function handlePaywallViewed(event, settings) {\n\tconst email = event.context?.traits?.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) return;\n\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.PIPEDRIVE_PIPELINE_ID,\n\t\tsettings\n\t);\n\tif (!deal) return;\n\n\tconst current = deal[settings.PD_DEAL_PAYWALL_VIEWS] || 0;\n\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\t[settings.PD_DEAL_PAYWALL_VIEWS]: current + 1\n\t\t},\n\t\tsettings\n\t);\n}\n\nasync function handleSubscriptionStarted(event, settings) {\n\tconst email = event.context?.traits?.email || event.properties?.email;\n\tif (!email) return;\n\n\tconst person = await findPersonByEmail(email, settings);\n\tif (!person) return;\n\n\tconst deal = await findOpenDeal(\n\t\tperson.id,\n\t\tsettings.PIPEDRIVE_PIPELINE_ID,\n\t\tsettings\n\t);\n\tif (!deal) return;\n\n\tawait pipedrivePut(\n\t\t`/deals/$${deal.id}`,\n\t\t{\n\t\t\tstage_id: parseInt(settings.PIPEDRIVE_STAGE_PAID), // 44\n\t\t\tvalue: (event.properties?.mrr || 99) * 12,\n\t\t\t[settings.PIPEDRIVE_DEAL_FIELD_MRR]: event.properties?.mrr,\n\t\t\t[settings.PIPEDRIVE_DEAL_FIELD_PLAN_NAME]: event.properties?.plan_name,\n\t\t\t[settings.PD_DEAL_DAYS_IN_TRIAL]:\n\t\t\t\tevent.properties?.days_in_trial_at_conversion\n\t\t},\n\t\tsettings\n\t);\n}\n"
  description   = null
  display_name  = null
  logo_url      = "https://cdn.filepicker.io/api/file/RmPmpcBTQZKaFeGQrdG5"
  resource_type = "DESTINATION"
  settings = [
    {
      description = ""
      label       = "4ee97b19e76069978c469661ce39b5"
      name        = "4Ee97B19E76069978C469661Ce39B5"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
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
      label       = "pdDealScoreTier"
      name        = "pdDealScoreTier"
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