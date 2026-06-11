import {
  to = segment_destination.id-6a2b35c54f6330690c5819ff
  id = "6a2b35c54f6330690c5819ff"
}

resource "segment_destination" "id-6a2b35c54f6330690c5819ff" {
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
  name = "Google Ads Conversions - Client"
  settings = jsonencode({
    conversionTrackingId = ""
    customerId           = ""
    loginCustomerId      = ""
  })
  source_id = "FmFezjcFVDksP66TYg63v"
}