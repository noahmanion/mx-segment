import {
  to = segment_destination.id-6a1ef3517e53cd37ef1082da
  id = "6a1ef3517e53cd37ef1082da"
}

resource "segment_destination" "id-6a1ef3517e53cd37ef1082da" {
  enabled = false
  metadata = {
    contacts          = null
    id                = "614a3c7d791c91c41bae7599"
    partner_owned     = false
    region_endpoints  = ["US"]
    supported_regions = ["us-west-2", "eu-west-1"]
  }
  name = "Webhook Debug Server"
  settings = jsonencode({
    sharedSecret = ""
  })
  source_id = "pNNoNmJpKPz6odJierJ1yZ"
}