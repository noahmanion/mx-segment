import {
  to = segment_destination_subscription.id-69efa3218b9415a1fb48eb69_5bWboDrJPNATL3XcgmxNVM
  id = "69efa3218b9415a1fb48eb69:5bWboDrJPNATL3XcgmxNVM"
}

resource "segment_destination_subscription" "id-69efa3218b9415a1fb48eb69_5bWboDrJPNATL3XcgmxNVM" {
  action_id            = "unHYcGwymGuZGnXskSGFQt"
  destination_id       = "69efa3218b9415a1fb48eb69"
  enabled              = true
  model_id             = null
  name                 = "Create or update a contact"
  reverse_etl_schedule = null
  settings = jsonencode({
    customAttributes = {
      "@path" = "$.traits"
    }
    email = {
      "@path" = "$.properties.email"
    }
    firstName = {
      "@path" = "$.traits.firstName"
    }
    lastName = {
      "@path" = "$.traits.lastName"
    }
    source = {
      "@if" = {
        else = "Segment"
        exists = {
          "@path" = "$.traits.source"
        }
        then = {
          "@path" = "$.traits.source"
        }
      }
    }
    subscribed = true
    userGroup = {
      "@path" = "$.traits.userGroup"
    }
    userId = {
      "@path" = "$.userId"
    }
  })
  trigger = "type = \"track\" and event = \"Account Created\""
}