import {
  to = segment_function.id-dfn_69fba1ebb3063f2216b6280c
  id = "dfn_69fba1ebb3063f2216b6280c"
}

resource "segment_function" "id-dfn_69fba1ebb3063f2216b6280c" {
  code = <<-EOT
// MX Build · Pipedrive Destination Function
// Segment → Pipedrive

// ─── HELPERS ────────────────────────────────────────────────────────────────

async function findPersonByEmail(email, settings) {
	const res = await fetch(
		`https://$${settings.PIPEDRIVE_DOMAIN}/api/v1/persons/search` +
			`?term=$${encodeURIComponent(email)}&fields=email&exact_match=true` +
			`&api_token=$${settings.PIPEDRIVE_API_KEY}`
	);
	const data = await res.json();
	return data?.data?.items?.[0]?.item || null;
}

async function findOpenDeal(personId, pipelineId, settings) {
	const res = await fetch(
		`https://$${settings.PIPEDRIVE_DOMAIN}/api/v1/persons/$${personId}/deals` +
			`?status=open&api_token=$${settings.PIPEDRIVE_API_KEY}`
	);
	const data = await res.json();
	return data?.data?.find(d => d.pipeline_id === parseInt(pipelineId)) || null;
}

async function findAllOpenDeals(personId, settings) {
	const res = await fetch(
		`https://$${settings.PIPEDRIVE_DOMAIN}/api/v1/persons/$${personId}/deals` +
			`?status=open&api_token=$${settings.PIPEDRIVE_API_KEY}`
	);
	const data = await res.json();
	return data?.data || [];
}

async function pipedrivePost(path, payload, settings) {
	const res = await fetch(
		`https://$${settings.PIPEDRIVE_DOMAIN}/api/v1$${path}?api_token=$${settings.PIPEDRIVE_API_KEY}`,
		{
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(payload)
		}
	);
	return res.json();
}

async function pipedrivePut(path, payload, settings) {
	const res = await fetch(
		`https://$${settings.PIPEDRIVE_DOMAIN}/api/v1$${path}?api_token=$${settings.PIPEDRIVE_API_KEY}`,
		{
			method: 'PUT',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(payload)
		}
	);
	return res.json();
}

async function loopsPatch(email, properties, settings) {
	if (!settings.LOOPS_API_KEY || !email) return;
	await fetch('https://app.loops.so/api/v1/contacts/update', {
		method: 'PUT',
		headers: {
			'Content-Type': 'application/json',
			'Authorization': `Bearer $${settings.LOOPS_API_KEY}`
		},
		body: JSON.stringify({ email, ...properties })
	});
}

async function getNextRepId(settings) {
	if (!settings.PIPEDRIVE_REP_IDS) return undefined;
	const repIds = settings.PIPEDRIVE_REP_IDS.split(',').map(id => id.trim()).filter(Boolean);
	if (repIds.length === 0) return undefined;
	if (repIds.length === 1) return repIds[0];

	const res = await fetch(
		`https://$${settings.PIPEDRIVE_DOMAIN}/api/v1/deals` +
			`?pipeline_id=$${settings.PIPEDRIVE_PIPELINE_ID}&status=open&sort=add_time+DESC&limit=50` +
			`&api_token=$${settings.PIPEDRIVE_API_KEY}`
	);
	const data = await res.json();
	const deals = data?.data || [];

	for (const d of deals) {
		const ownerId = String(d.user_id?.id ?? d.user_id ?? '');
		const idx = repIds.indexOf(ownerId);
		if (idx !== -1) {
			return repIds[(idx + 1) % repIds.length];
		}
	}
	return repIds[0];
}

function deriveChannel(utmSource) {
	if (!utmSource) return 'Direct';
	if (/google|adwords/i.test(utmSource)) return 'Google';
	if (/meta|facebook|instagram|fb/i.test(utmSource)) return 'Meta';
	if (/referr/i.test(utmSource)) return 'Referral';
	return 'Other';
}

function computeScoreTier(score) {
	if (score === 0) return 'low';
	if (score <= 3) return 'mid';
	return 'high';
}

function isWithin24Hours(trialStartedAt) {
	if (!trialStartedAt) return false;
	const start = new Date(trialStartedAt);
	const now = new Date();
	return (now - start) < 24 * 60 * 60 * 1000;
}

function isHighRevenueBand(band) {
	if (!band) return false;
	if (/^under\s*\$50|\bless\s+than\s*\$50/i.test(band)) return false;
	const m = band.match(/\$([\d,]+)\s*([KkMm]?)/);
	if (!m) return false;
	const n = parseFloat(m[1].replace(/,/g, ''));
	const u = m[2].toUpperCase();
	const kValue = u === 'M' ? n * 1000 : u === 'K' ? n : n / 1000;
	return kValue >= 50;
}

async function updateEngagementScore(deal, email, additionalPoints, settings) {
	const currentScore = deal[settings.PD_DEAL_ENGAGEMENT_SCORE] || 0;
	const newScore = currentScore + additionalPoints;
	const tier = computeScoreTier(newScore);
	await pipedrivePut(`/deals/$${deal.id}`, {
		[settings.PD_DEAL_ENGAGEMENT_SCORE]: newScore,
		[settings.PD_DEAL_SCORE_TIER]: tier
	}, settings);
	await loopsPatch(email, { score_tier: tier }, settings);
}

// ─── IDENTIFY ───────────────────────────────────────────────────────────────

async function onIdentify(event, settings) {
	const traits = event.traits || {};
	const email = traits.email;
	if (!email) return;

	const person = await findPersonByEmail(email, settings);

	const personPayload = {
		name: [traits.first_name, traits.last_name].filter(Boolean).join(' ') || email,
		email: [{ value: email, primary: true }],
		phone: traits.phone ? [{ value: traits.phone, primary: true }] : undefined,
		[settings.PIPEDRIVE_FIELD_UTM_SOURCE]: traits.utm_source,
		[settings.PIPEDRIVE_FIELD_UTM_MEDIUM]: traits.utm_medium,
		[settings.PIPEDRIVE_FIELD_UTM_CAMPAIGN]: traits.utm_campaign,
		[settings.PIPEDRIVE_FIELD_INDUSTRY]: traits.industry,
		[settings.PIPEDRIVE_FIELD_SIGNUP_SOURCE]: traits.signup_source,
		[settings.PIPEDRIVE_FIELD_IS_TEST]: traits.is_test ? 'Yes' : undefined
	};

	if (person) {
		await pipedrivePut(`/persons/$${person.id}`, personPayload, settings);
	} else {
		await pipedrivePost('/persons', personPayload, settings);
	}
}

// ─── TRACK DISPATCHER ───────────────────────────────────────────────────────

async function onTrack(event, settings) {
	const handlers = {
		'Signed Up': handleSignedUp,
		'Signup Form Completed': handleSignupFormCompleted,
		'Onboarding Started': handleOnboardingStarted,
		'Onboarding Abandoned': handleOnboardingAbandoned,
		'Estimate Sent': handleEstimateSent,
		'Invoice Created': handleInvoiceCreated,
		'Checklist Completed': handleChecklistCompleted,
		'Paywall Viewed': handlePaywallViewed,
		'Subscription Started': handleSubscriptionStarted
	};
	const handler = handlers[event.event];
	if (handler) await handler(event, settings);
}

// ─── TRACK HANDLERS ─────────────────────────────────────────────────────────

async function handleSignedUp(event, settings) {
	const email = event.context?.traits?.email;
	if (!email) return;

	const person = await findPersonByEmail(email, settings);
	if (!person) return;

	const allOpenDeals = await findAllOpenDeals(person.id, settings);

	// Replit dedup guard: skip if any open deal exists outside our pipeline
	const outsidePipeline = allOpenDeals.filter(
		d => d.pipeline_id !== parseInt(settings.PIPEDRIVE_PIPELINE_ID)
	);
	if (outsidePipeline.length > 0) {
		console.log(`[WARN] Skipping deal creation for $${email}: found $${outsidePipeline.length} open deal(s) outside pipeline $${settings.PIPEDRIVE_PIPELINE_ID}`);
		return;
	}

	// Standard dedup: skip if deal already exists in our pipeline
	const existing = allOpenDeals.find(
		d => d.pipeline_id === parseInt(settings.PIPEDRIVE_PIPELINE_ID)
	);
	if (existing) return;

	const today = new Date();
	const trialEnd = new Date(today);
	trialEnd.setDate(trialEnd.getDate() + 14);

	const ownerId = await getNextRepId(settings);

	await pipedrivePost(
		'/deals',
		{
			title: `$${person.name || email} — Trial`,
			person_id: person.id,
			stage_id: parseInt(settings.PIPEDRIVE_STAGE_TRIAL_SIGNUP),
			pipeline_id: parseInt(settings.PIPEDRIVE_PIPELINE_ID),
			value: 1188,
			currency: 'USD',
			user_id: ownerId ? parseInt(ownerId) : undefined,
			[settings.PD_DEAL_TRIAL_STARTED_AT]: today.toISOString().split('T')[0],
			[settings.PD_DEAL_TRIAL_ENDS_AT]: trialEnd.toISOString().split('T')[0]
		},
		settings
	);
}

async function handleSignupFormCompleted(event, settings) {
	const email = event.context?.traits?.email;
	if (!email) return;

	const person = await findPersonByEmail(email, settings);
	if (!person) return;

	await pipedrivePut(
		`/persons/$${person.id}`,
		{
			[settings.PIPEDRIVE_FIELD_UTM_SOURCE]: event.properties?.utm_source,
			[settings.PIPEDRIVE_FIELD_UTM_MEDIUM]: event.properties?.utm_medium,
			[settings.PIPEDRIVE_FIELD_UTM_CAMPAIGN]: event.properties?.utm_campaign,
			[settings.PIPEDRIVE_FIELD_REFERRER_URL]: event.properties?.referrer,
			[settings.PD_FIELD_HAS_REFERRAL_CODE]: event.properties?.has_referral_code ? 'Yes' : 'No',
			[settings.PIPEDRIVE_FIELD_SIGNUP_SOURCE]: event.properties?.source,
			[settings.PIPEDRIVE_FIELD_INDUSTRY]: event.properties?.trade
		},
		settings
	);

	const deal = await findOpenDeal(person.id, settings.PIPEDRIVE_PIPELINE_ID, settings);
	if (!deal) return;

	const revenueBand = event.properties?.revenue_band || '';
	const highRevenue = isHighRevenueBand(revenueBand);

	const dealUpdate = {
		[settings.PIPEDRIVE_DEAL_FIELD_CHANNEL]: deriveChannel(event.properties?.utm_source),
		[settings.PD_DEAL_REVENUE_BAND]: revenueBand || undefined,
		[settings.PD_DEAL_COMPANY_SIZE]: event.properties?.company_size
	};

	if (highRevenue && settings.PD_DEAL_ENGAGEMENT_SCORE) {
		const currentScore = deal[settings.PD_DEAL_ENGAGEMENT_SCORE] || 0;
		const newScore = currentScore + 1;
		const tier = computeScoreTier(newScore);
		dealUpdate[settings.PD_DEAL_ENGAGEMENT_SCORE] = newScore;
		dealUpdate[settings.PD_DEAL_SCORE_TIER] = tier;
		await pipedrivePut(`/deals/$${deal.id}`, dealUpdate, settings);
		await loopsPatch(email, { score_tier: tier }, settings);
	} else {
		await pipedrivePut(`/deals/$${deal.id}`, dealUpdate, settings);
	}
}

async function handleOnboardingStarted(event, settings) {
	const email = event.context?.traits?.email;
	if (!email) return;

	const person = await findPersonByEmail(email, settings);
	if (!person) return;

	const deal = await findOpenDeal(person.id, settings.PIPEDRIVE_PIPELINE_ID, settings);
	if (!deal) return;

	await pipedrivePut(
		`/deals/$${deal.id}`,
		{ stage_id: parseInt(settings.PIPEDRIVE_STAGE_ONBOARDED) },
		settings
	);
}

async function handleOnboardingAbandoned(event, settings) {
	const email = event.context?.traits?.email;
	if (!email) return;

	const person = await findPersonByEmail(email, settings);
	if (!person) return;

	const deal = await findOpenDeal(person.id, settings.PIPEDRIVE_PIPELINE_ID, settings);
	if (!deal) return;

	await Promise.all([
		pipedrivePost(
			'/notes',
			{
				content: `Onboarding abandoned at step: $${event.properties?.last_step_completed || 'unknown'}`,
				deal_id: deal.id
			},
			settings
		),
		pipedrivePut(
			`/deals/$${deal.id}`,
			{ stage_id: parseInt(settings.PIPEDRIVE_STAGE_TRIAL_SIGNUP) },
			settings
		)
	]);
}

async function handleEstimateSent(event, settings) {
	const email = event.context?.traits?.email;
	if (!email) return;

	const person = await findPersonByEmail(email, settings);
	if (!person) return;

	const deal = await findOpenDeal(person.id, settings.PIPEDRIVE_PIPELINE_ID, settings);
	if (!deal) return;

	const today = new Date().toISOString().split('T')[0];
	const alreadyActivated = deal[settings.PD_DEAL_ACTIVATED_AT];
	const currentCount = deal[settings.PD_DEAL_ESTIMATE_COUNT] || 0;
	const isFirstEstimate = currentCount === 0;

	const updatePayload = {
		[settings.PD_DEAL_LAST_ESTIMATE_AT]: today,
		[settings.PD_DEAL_ESTIMATE_COUNT]: currentCount + 1
	};

	if (!alreadyActivated) {
		updatePayload.stage_id = parseInt(settings.PIPEDRIVE_STAGE_ONBOARDED);
		updatePayload[settings.PD_DEAL_ACTIVATED_AT] = today;
	}

	await pipedrivePut(`/deals/$${deal.id}`, updatePayload, settings);

	if (isFirstEstimate && isWithin24Hours(deal[settings.PD_DEAL_TRIAL_STARTED_AT])) {
		await updateEngagementScore(deal, email, 3, settings);
	}
}

async function handleInvoiceCreated(event, settings) {
	const email = event.context?.traits?.email;
	if (!email) return;

	const person = await findPersonByEmail(email, settings);
	if (!person) return;

	const deal = await findOpenDeal(person.id, settings.PIPEDRIVE_PIPELINE_ID, settings);
	if (!deal) return;

	const currentCount = deal[settings.PD_DEAL_INVOICE_COUNT] || 0;
	const isFirstInvoice = currentCount === 0;

	await pipedrivePut(
		`/deals/$${deal.id}`,
		{ [settings.PD_DEAL_INVOICE_COUNT]: currentCount + 1 },
		settings
	);

	if (isFirstInvoice && isWithin24Hours(deal[settings.PD_DEAL_TRIAL_STARTED_AT])) {
		await updateEngagementScore(deal, email, 2, settings);
	}
}

async function handleChecklistCompleted(event, settings) {
	const email = event.context?.traits?.email;
	if (!email) return;

	const person = await findPersonByEmail(email, settings);
	if (!person) return;

	const deal = await findOpenDeal(person.id, settings.PIPEDRIVE_PIPELINE_ID, settings);
	if (!deal) return;

	const alreadyCompleted = deal[settings.PD_DEAL_CHECKLIST_COMPLETED];

	await pipedrivePut(
		`/deals/$${deal.id}`,
		{ [settings.PD_DEAL_CHECKLIST_COMPLETED]: true },
		settings
	);

	if (!alreadyCompleted && isWithin24Hours(deal[settings.PD_DEAL_TRIAL_STARTED_AT])) {
		await updateEngagementScore(deal, email, 2, settings);
	}
}

async function handlePaywallViewed(event, settings) {
	const email = event.context?.traits?.email;
	if (!email) return;

	const person = await findPersonByEmail(email, settings);
	if (!person) return;

	const deal = await findOpenDeal(person.id, settings.PIPEDRIVE_PIPELINE_ID, settings);
	if (!deal) return;

	const current = deal[settings.PD_DEAL_PAYWALL_VIEWS] || 0;
	const isFirstView = current === 0;

	await pipedrivePut(
		`/deals/$${deal.id}`,
		{ [settings.PD_DEAL_PAYWALL_VIEWS]: current + 1 },
		settings
	);

	if (isFirstView && isWithin24Hours(deal[settings.PD_DEAL_TRIAL_STARTED_AT])) {
		await updateEngagementScore(deal, email, 1, settings);
	}
}

async function handleSubscriptionStarted(event, settings) {
	const email = event.context?.traits?.email || event.properties?.email;
	if (!email) return;

	const person = await findPersonByEmail(email, settings);
	if (!person) return;

	const deal = await findOpenDeal(person.id, settings.PIPEDRIVE_PIPELINE_ID, settings);
	if (!deal) return;

	await pipedrivePut(
		`/deals/$${deal.id}`,
		{
			stage_id: parseInt(settings.PIPEDRIVE_STAGE_PAID),
			value: (event.properties?.mrr || 99) * 12,
			[settings.PIPEDRIVE_DEAL_FIELD_MRR]: event.properties?.mrr,
			[settings.PIPEDRIVE_DEAL_FIELD_PLAN_NAME]: event.properties?.plan_name,
			[settings.PD_DEAL_DAYS_IN_TRIAL]: event.properties?.days_in_trial_at_conversion
		},
		settings
	);
}
EOT
  description   = null
  display_name  = null
  logo_url      = "https://cdn.filepicker.io/api/file/RmPmpcBTQZKaFeGQrdG5"
  resource_type = "DESTINATION"
  settings = [
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
    {
      description = "Loops API key for score_tier contact property sync"
      label       = "Loops API Key"
      name        = "loopsApiKey"
      required    = true
      sensitive   = true
      type        = "STRING"
    },
    {
      description = "Comma-separated Pipedrive user IDs for round robin deal assignment, e.g. 12,34,56"
      label       = "Rep IDs (Round Robin)"
      name        = "pipedriveRepIds"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for numeric engagement score deal field"
      label       = "Deal Field: Engagement Score"
      name        = "pdDealEngagementScore"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for score tier (low/mid/high) deal field"
      label       = "Deal Field: Score Tier"
      name        = "pdDealScoreTier"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for invoice count deal field"
      label       = "Deal Field: Invoice Count"
      name        = "pdDealInvoiceCount"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for checklist completed boolean deal field"
      label       = "Deal Field: Checklist Completed"
      name        = "pdDealChecklistCompleted"
      required    = true
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for revenue band deal field — create field first then add hash"
      label       = "Deal Field: Revenue Band"
      name        = "pdDealRevenueBand"
      required    = false
      sensitive   = false
      type        = "STRING"
    },
    {
      description = "Pipedrive hash for company size deal field — create field first then add hash"
      label       = "Deal Field: Company Size"
      name        = "pdDealCompanySize"
      required    = false
      sensitive   = false
      type        = "STRING"
    },
  ]
}
