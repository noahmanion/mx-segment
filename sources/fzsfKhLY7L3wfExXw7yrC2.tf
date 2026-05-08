import {
  to = segment_source.id-fzsfKhLY7L3wfExXw7yrC2
  id = "fzsfKhLY7L3wfExXw7yrC2"
}

resource "segment_source" "id-fzsfKhLY7L3wfExXw7yrC2" {
  enabled = true
  labels = [
    {
      key   = "environment"
      value = "dev"
    },
  ]
  metadata = {
    id = "IqDTy1TpoU"
  }
  name = "JS Dev"
  settings = jsonencode({
    apiHost     = "api.segment.io/v1"
    website_url = "https://localhost:4200"
  })
  slug = "js_dev"
}