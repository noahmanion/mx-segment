import {
  to = segment_destination_subscription.id-6a9af012190e658f8cee1814_9jAKJvEXiyj3Xn4cBc6Pia
  id = "6a9af012190e658f8cee1814:9jAKJvEXiyj3Xn4cBc6Pia"
}

resource "segment_destination_subscription" "id-6a9af012190e658f8cee1814_9jAKJvEXiyj3Xn4cBc6Pia" {
  action_id            = "hd2J84Sw2PcfzEkAm47YaK"
  destination_id       = "6a9af012190e658f8cee1814"
  enabled              = true
  model_id             = null
  name                 = "Create or update Lead"
  reverse_etl_schedule = null
  settings = jsonencode({
    amount = {
      "@if" = {
        else = {
          "@path" = "$.properties.amount"
        }
        exists = {
          "@path" = "$.traits.amount"
        }
        then = {
          "@path" = "$.traits.amount"
        }
      }
    }
    currency = {
      "@if" = {
        else = {
          "@path" = "$.properties.currency"
        }
        exists = {
          "@path" = "$.traits.currency"
        }
        then = {
          "@path" = "$.traits.currency"
        }
      }
    }
    expected_close_date = {
      "@if" = {
        else = {
          "@path" = "$.properties.expected_close_date"
        }
        exists = {
          "@path" = "$.traits.expected_close_date"
        }
        then = {
          "@path" = "$.traits.expected_close_date"
        }
      }
    }
    lead_id = {
      "@if" = {
        else = {
          "@path" = "$.properties.lead_id"
        }
        exists = {
          "@path" = "$.traits.lead_id"
        }
        then = {
          "@path" = "$.traits.lead_id"
        }
      }
    }
    person_match_field = "email"
    person_match_value = {
      "@path" = "$.traits.email"
    }
    title = {
      "@path" = "$.traits.name"
    }
  })
  trigger = "type = \"identify\""
}