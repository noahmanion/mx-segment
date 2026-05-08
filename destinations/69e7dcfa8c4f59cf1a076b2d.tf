import {
  to = segment_destination.id-69e7dcfa8c4f59cf1a076b2d
  id = "69e7dcfa8c4f59cf1a076b2d"
}

resource "segment_destination" "id-69e7dcfa8c4f59cf1a076b2d" {
  enabled = true
  metadata = {
    contacts = [
      {
      },
    ]
    id                = "60ae8b97dcb6cc52d5d0d5ab"
    partner_owned     = false
    region_endpoints  = ["US"]
    supported_regions = ["us-west-2", "eu-west-1"]
  }
  name = "Google Ads Conversions"
  settings = jsonencode({
    conversionTrackingId = "AW-17058796366/IDXeCPWr2f0bEM6mosY_"
    customerId           = " 602-342-5554"
    dynamicAuthSettings = {
      configId = "69e7dcfa8c4f59cf1a076b2d"
      oauth = {
        type = "noAuth"
      }
    }
    loginCustomerId = "426-856-8241"
  })
  source_id = "FmFezjcFVDksP66TYg63v"
}