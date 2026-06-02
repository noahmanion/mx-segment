import {
  to = segment_destination_subscription.id-6a1f00344db171f61bf445b2_8iMCrWySvG4D5hcvvtMc7p
  id = "6a1f00344db171f61bf445b2:8iMCrWySvG4D5hcvvtMc7p"
}

resource "segment_destination_subscription" "id-6a1f00344db171f61bf445b2_8iMCrWySvG4D5hcvvtMc7p" {
  action_id            = "ja2fMtPLyGVf5gRvcPg2Km"
  destination_id       = "6a1f00344db171f61bf445b2"
  enabled              = true
  model_id             = null
  name                 = "Send Server"
  reverse_etl_schedule = null
  settings = jsonencode({
    data = {
      "@path" = "$."
    }
    method = "POST"
    url    = "https://gambling-plenty-stallion.ngrok-free.dev/ingest?src=client"
  })
  trigger = "type = \"track\" or type = \"identify\""
}