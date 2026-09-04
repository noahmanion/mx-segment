import {
  to = segment_destination_subscription.id-6a9af012190e658f8cee1814_vKFCP5cMepPmYQ2PmPLiXS
  id = "6a9af012190e658f8cee1814:vKFCP5cMepPmYQ2PmPLiXS"
}

resource "segment_destination_subscription" "id-6a9af012190e658f8cee1814_vKFCP5cMepPmYQ2PmPLiXS" {
  action_id            = "66wGU3cfJrrdBk8CqekrJc"
  destination_id       = "6a9af012190e658f8cee1814"
  enabled              = true
  model_id             = null
  name                 = "Create or Update a Person"
  reverse_etl_schedule = null
  settings = jsonencode({
    email = {
      "@path" = "$.traits.email"
    }
    match_value = {
      "@path" = "$.userId"
    }
    name = {
      "@path" = "$.traits.name"
    }
    phone = {
      "@path" = "$.traits.phone"
    }
  })
  trigger = "type = \"identify\""
}