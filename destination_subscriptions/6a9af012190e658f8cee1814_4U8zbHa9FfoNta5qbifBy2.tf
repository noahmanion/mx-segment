import {
  to = segment_destination_subscription.id-6a9af012190e658f8cee1814_4U8zbHa9FfoNta5qbifBy2
  id = "6a9af012190e658f8cee1814:4U8zbHa9FfoNta5qbifBy2"
}

resource "segment_destination_subscription" "id-6a9af012190e658f8cee1814_4U8zbHa9FfoNta5qbifBy2" {
  action_id            = "uVzPR9SSpfLqF3zoPok99Q"
  destination_id       = "6a9af012190e658f8cee1814"
  enabled              = false
  model_id             = null
  name                 = "Create or Update an Organization"
  reverse_etl_schedule = null
  settings = jsonencode({
    match_value = {
      "@path" = "$.groupId"
    }
    name = {
      "@path" = "$.traits.name"
    }
  })
  trigger = "type = \"group\""
}