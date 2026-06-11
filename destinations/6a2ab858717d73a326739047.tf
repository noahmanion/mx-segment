import {
  to = segment_destination.id-6a2ab858717d73a326739047
  id = "6a2ab858717d73a326739047"
}

resource "segment_destination" "id-6a2ab858717d73a326739047" {
  enabled = false
  metadata = {
    contacts = [
      {
      },
      {
      },
      {
      },
    ]
    id                = "5661eb58e954a874ca44cc07"
    partner_owned     = false
    region_endpoints  = null
    supported_regions = null
  }
  name = "Fscebook Pixel"
  settings = jsonencode({
    automaticConfiguration         = true
    blacklistPiiProperties         = []
    contentTypes                   = {}
    initWithExistingTraits         = false
    keyForExternalId               = ""
    legacyEvents                   = {}
    limitedDataUse                 = true
    pixelId                        = ""
    standardEvents                 = {}
    standardEventsCustomProperties = []
    userIdAsExternalId             = false
    valueIdentifier                = "value"
    whitelistPiiProperties         = []
  })
  source_id = "FmFezjcFVDksP66TYg63v"
}