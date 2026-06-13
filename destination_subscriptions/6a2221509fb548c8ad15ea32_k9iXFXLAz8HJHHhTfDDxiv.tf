import {
  to = segment_destination_subscription.id-6a2221509fb548c8ad15ea32_k9iXFXLAz8HJHHhTfDDxiv
  id = "6a2221509fb548c8ad15ea32:k9iXFXLAz8HJHHhTfDDxiv"
}

resource "segment_destination_subscription" "id-6a2221509fb548c8ad15ea32_k9iXFXLAz8HJHHhTfDDxiv" {
  action_id            = "evdcEYsm4uM3LNKtFqLBR4"
  destination_id       = "6a2221509fb548c8ad15ea32"
  enabled              = true
  model_id             = null
  name                 = "Signup Form Completed"
  reverse_etl_schedule = null
  settings = jsonencode({
    __segment_internal_sync_mode = "add"
    action_source                = "website"
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
      email = {
        "@path" = "$.context.traits.email"
      }
      externalId = {
        "@if" = {
          else = {
            "@path" = "$.anonymousId"
          }
          exists = {
            "@path" = "$.userId"
          }
          then = {
            "@path" = "$.userId"
          }
        }
      }
      fbc = {
        "@path" = "$.traits.fbclid"
      }
      fbp = {
        "@path" = "$.traits.fbp"
      }
      firstName = {
        "@path" = "$.context.traits.firstName"
      }
      lastName = {
        "@path" = "$.context.traits.lastName"
      }
      phone = {
        "@path" = "$.context.traits.phone"
      }
      state = {
        "@path" = "$.context.traits.address.state"
      }
      zip = {
        "@path" = "$.context.traits.address.postalCode"
      }
    }
  })
  trigger = "type = \"identify\""
}