import {
  to = segment_destination_subscription.id-6a1f3f97a84c3cb88a8c575d_65wNcAbF8YvvPn5NW3VpaF
  id = "6a1f3f97a84c3cb88a8c575d:65wNcAbF8YvvPn5NW3VpaF"
}

resource "segment_destination_subscription" "id-6a1f3f97a84c3cb88a8c575d_65wNcAbF8YvvPn5NW3VpaF" {
  action_id            = "evdcEYsm4uM3LNKtFqLBR4"
  destination_id       = "6a1f3f97a84c3cb88a8c575d"
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
    event_name = "AccountCreated"
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