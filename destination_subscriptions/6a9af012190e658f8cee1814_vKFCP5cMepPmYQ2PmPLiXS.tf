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
    custom_fields = {
      "26f716e0c9f3d6cc0cee7bd51e2da4018bfe9bdd" = {
        "@path" = "$.traits.campaignName"
      }
      "5cf8b6026b685e0b760999c9295f6505ed2f5cc2" = {
        "@path" = "$.traits.adSetName"
      }
      b71a9d4d54446c84af8ad0e667e5c7dd9de123b0 = {
        "@template" = "{{traits.what's_your_trade}}"
      }
      c1eacba1ed67ffb2a94106f085355a4f764785db = {
        "@path" = "$.traits.adName"
      }
    }
    email = {
      "@path" = "$.traits.email"
    }
    match_field = "email"
    match_value = {
      "@path" = "$.traits.email"
    }
    name = {
      "@path" = "$.traits.name"
    }
    phone = {
      "@path" = "$.traits.phone_number"
    }
  })
  trigger = "type = \"identify\""
}