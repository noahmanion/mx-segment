import {
  to = segment_destination_subscription.id-6a3590172e465e0dafe9987a_4fiPHPAog48GJCKfM8p6JA
  id = "6a3590172e465e0dafe9987a:4fiPHPAog48GJCKfM8p6JA"
}

resource "segment_destination_subscription" "id-6a3590172e465e0dafe9987a_4fiPHPAog48GJCKfM8p6JA" {
  action_id            = "pAMZTGDc7yKTW5ZGecP8Df"
  destination_id       = "6a3590172e465e0dafe9987a"
  enabled              = true
  model_id             = null
  name                 = "Complete Registration"
  reverse_etl_schedule = null
  settings = jsonencode({
    __segment_internal_sync_mode = "add"
    batch_size                   = 1500
    conversion_action            = "7651099651"
    conversion_timestamp = {
      "@path" = "$.timestamp"
    }
    currency = {
      "@path" = "$.properties.currency"
    }
    email_address = {
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
    gclid = {
      "@path" = "$.properties.gclid"
    }
    items = {
      "@arrayPath" = [{
        "@path" = "$.properties.products"
        }, {
        price = {
          "@path" = "$.price"
        }
        product_id = {
          "@path" = "$.product_id"
        }
        quantity = {
          "@path" = "$.quantity"
        }
      }]
    }
    order_id = {
      "@if" = {
        else = {
          "@path" = "$.properties.order_id"
        }
        exists = {
          "@path" = "$.properties.orderId"
        }
        then = {
          "@path" = "$.properties.orderId"
        }
      }
    }
    phone_number = {
      "@if" = {
        else = {
          "@path" = "$.context.traits.phone"
        }
        exists = {
          "@path" = "$.properties.phone"
        }
        then = {
          "@path" = "$.properties.phone"
        }
      }
    }
    session_attributes_encoded = {
      "@path" = "$.integrations.Google Ads Conversions.session_attributes_encoded"
    }
    session_attributes_key_value_pairs = {
      gad_campaignid = {
        "@path" = "$.properties.gad_campaignid"
      }
      gad_source = {
        "@path" = "$.properties.gad_source"
      }
      landing_page_referrer = {
        "@path" = "$.context.page.referrer"
      }
      landing_page_url = {
        "@path" = "$.context.page.url"
      }
      landing_page_user_agent = {
        "@path" = "$.context.userAgent"
      }
      session_start_time_usec = {
        "@path" = "$.properties.session_start_time_usec"
      }
    }
    user_ip_address = {
      "@path" = "$.context.ip"
    }
    value = {
      "@path" = "$.properties.total"
    }
  })
  trigger = "event = \"Signup Form Completed\""
}