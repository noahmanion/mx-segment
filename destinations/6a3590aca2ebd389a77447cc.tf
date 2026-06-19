import {
  to = segment_destination.id-6a3590aca2ebd389a77447cc
  id = "6a3590aca2ebd389a77447cc"
}

resource "segment_destination" "id-6a3590aca2ebd389a77447cc" {
  enabled = false
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
  name = "Google Ads Conversions - Server"
  settings = jsonencode({
    account              = ""
    conversionTrackingId = ""
    customerId           = "518-471-3650"
    dynamicAuthSettings = {
      configId = "69e7dcfa8c4f59cf1a076b2d"
      oauth = {
        type = "noAuth"
      }
    }
    loginCustomerId = ""
  })
  source_id = "pNNoNmJpKPz6odJierJ1yZ"
}