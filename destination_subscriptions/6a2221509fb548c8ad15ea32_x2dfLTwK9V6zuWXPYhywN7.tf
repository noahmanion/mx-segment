import {
  to = segment_destination_subscription.id-6a2221509fb548c8ad15ea32_x2dfLTwK9V6zuWXPYhywN7
  id = "6a2221509fb548c8ad15ea32:x2dfLTwK9V6zuWXPYhywN7"
}

resource "segment_destination_subscription" "id-6a2221509fb548c8ad15ea32_x2dfLTwK9V6zuWXPYhywN7" {
  action_id            = "3d5gFs6q9sfwJVAYPDyGQc"
  destination_id       = "6a2221509fb548c8ad15ea32"
  enabled              = true
  model_id             = null
  name                 = "CTA Click"
  reverse_etl_schedule = null
  settings = jsonencode({
    action_source = "website"
    app_data_field = {
      application_tracking_enabled = {
        "@path" = "$.context.device.adTrackingEnabled"
      }
      carrier = {
        "@path" = "$.context.network.carrier"
      }
      density = {
        "@path" = "$.context.screen.density"
      }
      deviceName = {
        "@path" = "$.context.device.model"
      }
      deviceTimezone = {
        "@path" = "$.context.timezone"
      }
      height = {
        "@path" = "$.context.screen.height"
      }
      locale = {
        "@path" = "$.context.locale"
      }
      longVersion = {
        "@path" = "$.context.app.version"
      }
      madId = {
        "@path" = "$.context.madId"
      }
      osVersion = {
        "@path" = "$.context.os.version"
      }
      packageName = {
        "@path" = "$.context.app.namespace"
      }
      width = {
        "@path" = "$.context.screen.width"
      }
    }
    event_id = {
      "@path" = "$.properties.event_id"
    }
    event_name = {
      "@path" = "$.event"
    }
    event_source_url = {
      "@path" = "$.context.page.url"
    }
    event_time = {
      "@path" = "$.timestamp"
    }
    user_data = {
      city = {
        "@path" = "$.context.traits.address.city"
      }
      client_ip_address = {
        "@path" = "$.context.ip"
      }
      client_user_agent = {
        "@path" = "$.context.userAgent"
      }
      dateOfBirth = {
        "@path" = "$.context.traits.birthday"
      }
      externalId = {
        "@path" = "$.anonymousId"
      }
      fbc = {
        "@path" = "$.properties.fbc"
      }
      fbp = {
        "@path" = "$.properties.fbp"
      }
      firstName = {
        "@path" = "$.context.traits.firstName"
      }
      lastName = {
        "@path" = "$.context.traits.lastName"
      }
      state = {
        "@path" = "$.context.traits.address.state"
      }
      zip = {
        "@path" = "$.context.traits.address.postalCode"
      }
    }
  })
  trigger = "event = \"CTA Clicked\""
}