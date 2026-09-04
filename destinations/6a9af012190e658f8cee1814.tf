import {
  to = segment_destination.id-6a9af012190e658f8cee1814
  id = "6a9af012190e658f8cee1814"
}

resource "segment_destination" "id-6a9af012190e658f8cee1814" {
  enabled = false
  metadata = {
    contacts = [
      {
      },
    ]
    id                = "5f7dd8191ad74f868ab1fc48"
    partner_owned     = true
    region_endpoints  = null
    supported_regions = ["us-west-2", "eu-west-1"]
  }
  name = "Pipedrive Lead Ads"
  settings = jsonencode({
    apiToken          = ""
    dealField         = "id"
    domain            = ""
    organizationField = "id"
    personField       = "id"
  })
  source_id = "s6wcFS6qdXWq8dt1U66TZe"
}