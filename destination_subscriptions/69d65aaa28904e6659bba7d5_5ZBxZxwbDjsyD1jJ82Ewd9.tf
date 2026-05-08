import {
  to = segment_destination_subscription.id-69d65aaa28904e6659bba7d5_5ZBxZxwbDjsyD1jJ82Ewd9
  id = "69d65aaa28904e6659bba7d5:5ZBxZxwbDjsyD1jJ82Ewd9"
}

resource "segment_destination_subscription" "id-69d65aaa28904e6659bba7d5_5ZBxZxwbDjsyD1jJ82Ewd9" {
  action_id            = "nFPnRozhz1mh4Gbx4MLvT5"
  destination_id       = "69d65aaa28904e6659bba7d5"
  enabled              = true
  model_id             = null
  name                 = "Track"
  reverse_etl_schedule = null
  settings = jsonencode({
    batch_keys = ["url", "method", "headers"]
    data = {
      "@path" = "$."
    }
    method = "POST"
    url    = "https://bloomads.softpath.co/api/segment/webhook"
  })
  trigger = "type = \"track\""
}