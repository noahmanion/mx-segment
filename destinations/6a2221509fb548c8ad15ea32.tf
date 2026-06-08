import {
  to = segment_destination.id-6a2221509fb548c8ad15ea32
  id = "6a2221509fb548c8ad15ea32"
}

resource "segment_destination" "id-6a2221509fb548c8ad15ea32" {
  enabled = true
  metadata = {
    contacts          = null
    id                = "61806e472cd47ea1104885fc"
    partner_owned     = false
    region_endpoints  = ["US"]
    supported_regions = ["us-west-2", "eu-west-1"]
  }
  name = "Facebook CAPI Client"
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
  source_id = "FmFezjcFVDksP66TYg63v"
}