import {
  to = segment_destination.id-6a1f3f97a84c3cb88a8c575d
  id = "6a1f3f97a84c3cb88a8c575d"
}

resource "segment_destination" "id-6a1f3f97a84c3cb88a8c575d" {
  enabled = true
  metadata = {
    contacts          = null
    id                = "61806e472cd47ea1104885fc"
    partner_owned     = false
    region_endpoints  = ["US"]
    supported_regions = ["us-west-2", "eu-west-1"]
  }
  name = "Facebook CAPI Server"
  settings = jsonencode({
    dynamicAuthSettings = {
      configId = "6a1f3f97a84c3cb88a8c575d"
      oauth = {
        type = "noAuth"
      }
    }
    pixelId       = "1251375650140164"
    testEventCode = ""
  })
  source_id = "pNNoNmJpKPz6odJierJ1yZ"
}