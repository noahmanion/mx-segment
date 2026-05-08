import {
  to = segment_source.id-FmFezjcFVDksP66TYg63v
  id = "FmFezjcFVDksP66TYg63v"
}

resource "segment_source" "id-FmFezjcFVDksP66TYg63v" {
  enabled = true
  labels  = null
  metadata = {
    id = "IqDTy1TpoU"
  }
  name = "Loveable Landing Page"
  settings = jsonencode({
    apiHost     = "api.segment.io/v1"
    website_url = "https://demo.mxbuild.co"
  })
  slug = "loveable_landing_page"
}