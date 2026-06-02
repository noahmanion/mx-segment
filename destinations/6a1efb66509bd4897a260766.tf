import {
  to = segment_destination.id-6a1efb66509bd4897a260766
  id = "6a1efb66509bd4897a260766"
}

resource "segment_destination" "id-6a1efb66509bd4897a260766" {
  enabled = false
  metadata = {
    contacts          = null
    id                = "66b1f528d26440823fb27af9"
    partner_owned     = true
    region_endpoints  = null
    supported_regions = ["us-west-2", "eu-west-1"]
  }
  name = "Webhook Debug Server"
  settings = jsonencode({
    sharedSecret = ""
  })
  source_id = "pNNoNmJpKPz6odJierJ1yZ"
}