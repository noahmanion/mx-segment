import {
  to = segment_destination.id-6a1f00344db171f61bf445b2
  id = "6a1f00344db171f61bf445b2"
}

resource "segment_destination" "id-6a1f00344db171f61bf445b2" {
  enabled = false
  metadata = {
    contacts          = null
    id                = "66b1f528d26440823fb27af9"
    partner_owned     = true
    region_endpoints  = null
    supported_regions = ["us-west-2", "eu-west-1"]
  }
  name = "Webhook Debug Client"
  settings = jsonencode({
    sharedSecret = ""
  })
  source_id = "FmFezjcFVDksP66TYg63v"
}