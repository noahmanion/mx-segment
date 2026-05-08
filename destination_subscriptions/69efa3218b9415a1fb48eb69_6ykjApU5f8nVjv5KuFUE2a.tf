import {
  to = segment_destination_subscription.id-69efa3218b9415a1fb48eb69_6ykjApU5f8nVjv5KuFUE2a
  id = "69efa3218b9415a1fb48eb69:6ykjApU5f8nVjv5KuFUE2a"
}

resource "segment_destination_subscription" "id-69efa3218b9415a1fb48eb69_6ykjApU5f8nVjv5KuFUE2a" {
  action_id            = "vaKecAu4KpBs6R7sHQKTNY"
  destination_id       = "69efa3218b9415a1fb48eb69"
  enabled              = true
  model_id             = null
  name                 = "Send Event"
  reverse_etl_schedule = null
  settings = jsonencode({
    email = {
      "@if" = {
        else = {
          "@path" = "$.context.traits.email"
        }
        exists = {
          "@path" = "$.properties.email"
        }
        then = {
          "@path" = "$.properties.email"
        }
      }
    }
    eventName = {
      "@path" = "$.event"
    }
    eventProperties = {
      "@path" = "$.properties"
    }
    userId = {
      "@path" = "$.userId"
    }
  })
  trigger = "type = \"track\""
}