import {
  to = segment_destination_subscription.id-6a1efb66509bd4897a260766_hSnZR2gPvGFKmncqF5EkLb
  id = "6a1efb66509bd4897a260766:hSnZR2gPvGFKmncqF5EkLb"
}

resource "segment_destination_subscription" "id-6a1efb66509bd4897a260766_hSnZR2gPvGFKmncqF5EkLb" {
  action_id            = "ja2fMtPLyGVf5gRvcPg2Km"
  destination_id       = "6a1efb66509bd4897a260766"
  enabled              = true
  model_id             = null
  name                 = "Send Server"
  reverse_etl_schedule = null
  settings = jsonencode({
    data = {
      "@path" = "$."
    }
    method = "POST"
    url    = "https://gambling-plenty-stallion.ngrok-free.dev/ingest?src=server"
  })
  trigger = "type = \"track\" or type = \"identify\""
}