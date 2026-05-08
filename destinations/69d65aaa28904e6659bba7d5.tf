import {
  to = segment_destination.id-69d65aaa28904e6659bba7d5
  id = "69d65aaa28904e6659bba7d5"
}

resource "segment_destination" "id-69d65aaa28904e6659bba7d5" {
  enabled = true
  metadata = {
    contacts          = null
    id                = "614a3c7d791c91c41bae7599"
    partner_owned     = false
    region_endpoints  = ["US"]
    supported_regions = ["us-west-2", "eu-west-1"]
  }
  name = "Webhook JS"
  settings = jsonencode({
    dynamicAuthSettings = {
      configId = "69d65aaa28904e6659bba7d5"
      oauth = {
        type = "noAuth"
      }
    }
    sharedSecret = "••••••••••RWvE"
  })
  source_id = "FmFezjcFVDksP66TYg63v"
}