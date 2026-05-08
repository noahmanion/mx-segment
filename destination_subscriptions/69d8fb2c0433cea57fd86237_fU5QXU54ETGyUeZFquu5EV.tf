import {
  to = segment_destination_subscription.id-69d8fb2c0433cea57fd86237_fU5QXU54ETGyUeZFquu5EV
  id = "69d8fb2c0433cea57fd86237:fU5QXU54ETGyUeZFquu5EV"
}

resource "segment_destination_subscription" "id-69d8fb2c0433cea57fd86237_fU5QXU54ETGyUeZFquu5EV" {
  action_id            = "nFPnRozhz1mh4Gbx4MLvT5"
  destination_id       = "69d8fb2c0433cea57fd86237"
  enabled              = true
  model_id             = null
  name                 = "Page"
  reverse_etl_schedule = null
  settings = jsonencode({
    batch_keys = ["url", "method", "headers"]
    data = {
      "@path" = "$."
    }
    method = "POST"
    url    = "https://bloomads.softpath.co/api/segment/webhook"
  })
  trigger = "type = \"page\""
}