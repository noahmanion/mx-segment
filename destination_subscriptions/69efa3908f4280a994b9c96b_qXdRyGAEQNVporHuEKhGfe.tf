import {
  to = segment_destination_subscription.id-69efa3908f4280a994b9c96b_qXdRyGAEQNVporHuEKhGfe
  id = "69efa3908f4280a994b9c96b:qXdRyGAEQNVporHuEKhGfe"
}

resource "segment_destination_subscription" "id-69efa3908f4280a994b9c96b_qXdRyGAEQNVporHuEKhGfe" {
  action_id            = "vaKecAu4KpBs6R7sHQKTNY"
  destination_id       = "69efa3908f4280a994b9c96b"
  enabled              = false
  model_id             = null
  name                 = "Identify"
  reverse_etl_schedule = null
  settings = jsonencode({
    email = {
      "@path" = "$.properties.email"
    }
    eventName = {
      "@path" = "$.event"
    }
    eventProperties = {
      "@path" = "$.properties"
    }
    userId = {
      "@path" = "$.anonymousId"
    }
  })
  trigger = "type = \"identify\""
}