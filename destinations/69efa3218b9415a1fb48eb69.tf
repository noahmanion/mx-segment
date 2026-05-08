import {
  to = segment_destination.id-69efa3218b9415a1fb48eb69
  id = "69efa3218b9415a1fb48eb69"
}

resource "segment_destination" "id-69efa3218b9415a1fb48eb69" {
  enabled = true
  metadata = {
    contacts = [
      {
      },
    ]
    id                = "63360a5fe290ca3fdfad4a68"
    partner_owned     = true
    region_endpoints  = null
    supported_regions = ["us-west-2", "eu-west-1"]
  }
  name = "Loops Backend"
  settings = jsonencode({
    apiKey = "••••••••••8a2b"
    dynamicAuthSettings = {
      configId = "69efa3218b9415a1fb48eb69"
      oauth = {
        type = "noAuth"
      }
    }
  })
  source_id = "pNNoNmJpKPz6odJierJ1yZ"
}