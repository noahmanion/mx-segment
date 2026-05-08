import {
  to = segment_destination.id-69efa3908f4280a994b9c96b
  id = "69efa3908f4280a994b9c96b"
}

resource "segment_destination" "id-69efa3908f4280a994b9c96b" {
  enabled = false
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
  name = "Loops Frontend"
  settings = jsonencode({
    apiKey = "••••••••••8a2b"
    dynamicAuthSettings = {
      configId = "69efa3218b9415a1fb48eb69"
      oauth = {
        type = "noAuth"
      }
    }
  })
  source_id = "FmFezjcFVDksP66TYg63v"
}