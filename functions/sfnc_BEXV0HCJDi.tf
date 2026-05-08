import {
  to = segment_function.id-sfnc_BEXV0HCJDi
  id = "sfnc_BEXV0HCJDi"
}

resource "segment_function" "id-sfnc_BEXV0HCJDi" {
  code          = "// Segment Source Function: flatten group to identify\nasync function onGroup(event) {\n\tconst userId = event.userId;\n\tconst groupTraits = event.traits || {};\n\n\tif (!userId) return;\n\n\tSegment.set('userId', userId);\n\tSegment.set('traits', {\n\t\tplan: groupTraits.plan,\n\t\tmrr: groupTraits.mrr,\n\t\ttrialStartedAt: groupTraits.trial_started_at,\n\t\ttrialEndsAt: computeTrialEnd(groupTraits.trial_started_at),\n\t\tindustry: groupTraits.industry,\n\t\tcompanyName: groupTraits.name\n\t});\n}\n\nfunction campaignTrialEnd(trialStart) {\n\tif (!trialStart) return null;\n\tconst start = new Date(trialStart);\n\tstart.setDate(start.getDate() + 14);\n\treturn start.toISOString();\n}\n"
  description   = "Flattens group calls so that loops can accept them."
  display_name  = "Group Flattening"
  logo_url      = "https://cdn.filepicker.io/api/file/RmPmpcBTQZKaFeGQrdG5"
  resource_type = "SOURCE"
  settings = [
  ]
}