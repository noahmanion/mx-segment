import {
  to = segment_destination_subscription.id-6a2221509fb548c8ad15ea32_5nH6ZKZdEKceLJ4c9ha4yW
  id = "6a2221509fb548c8ad15ea32:5nH6ZKZdEKceLJ4c9ha4yW"
}

resource "segment_destination_subscription" "id-6a2221509fb548c8ad15ea32_5nH6ZKZdEKceLJ4c9ha4yW" {
  action_id            = "evdcEYsm4uM3LNKtFqLBR4"
  destination_id       = "6a2221509fb548c8ad15ea32"
  enabled              = true
  model_id             = null
  name                 = "Complete Registration"
  reverse_etl_schedule = null
  settings = jsonencode({
    __segment_internal_sync_mode = "add"
    action_source                = "website"
    app_data_field = {
      deviceTimezone = {
        "@path" = "$.context.timezone"
      }
    }
    event_id = {
      "@path" = "$.messageId"
    }
    event_name = "CompleteRegistration"
    event_source_url = {
      "@path" = "$.context.page.url"
    }
    event_time = {
      "@path" = "$.timestamp"
    }
    user_data = {
      email = {
        "@path" = "$.properties.email"
      }
      externalId = {
        "@path" = "$.userId"
      }
    }
  })
  trigger = "event = \"Account Created\""
}