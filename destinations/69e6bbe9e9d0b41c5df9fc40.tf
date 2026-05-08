import {
  to = segment_destination.id-69e6bbe9e9d0b41c5df9fc40
  id = "69e6bbe9e9d0b41c5df9fc40"
}

resource "segment_destination" "id-69e6bbe9e9d0b41c5df9fc40" {
  enabled = true
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
  name = "Pipedrive Backend"
  settings = jsonencode({
    apiToken  = "••••••••••ec29"
    dealField = "id"
    domain    = "mxbuild"
    dynamicAuthSettings = {
      configId = "69e6bbe9e9d0b41c5df9fc40"
      oauth = {
        type = "noAuth"
      }
    }
    organizationField = "id"
    personField       = "id"
  })
  source_id = "pNNoNmJpKPz6odJierJ1yZ"
}