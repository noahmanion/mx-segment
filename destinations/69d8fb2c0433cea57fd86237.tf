import {
  to = segment_destination.id-69d8fb2c0433cea57fd86237
  id = "69d8fb2c0433cea57fd86237"
}

resource "segment_destination" "id-69d8fb2c0433cea57fd86237" {
  enabled = true
  metadata = {
    contacts          = null
    id                = "614a3c7d791c91c41bae7599"
    partner_owned     = false
    region_endpoints  = ["US"]
    supported_regions = ["us-west-2", "eu-west-1"]
  }
  name = "Server Webhoook"
  settings = jsonencode({
    dynamicAuthSettings = {
      configId = "69d65aaa28904e6659bba7d5"
      oauth = {
        type = "noAuth"
      }
    }
    sharedSecret = "••••••••••RWvE"
  })
  source_id = "pNNoNmJpKPz6odJierJ1yZ"
}