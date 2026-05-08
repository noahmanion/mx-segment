import {
  to = segment_source.id-5DuG9BVuZ9kEbn4K3gR7vL
  id = "5DuG9BVuZ9kEbn4K3gR7vL"
}

resource "segment_source" "id-5DuG9BVuZ9kEbn4K3gR7vL" {
  enabled = true
  labels = [
    {
      key   = "environment"
      value = "dev"
    },
  ]
  metadata = {
    id = "8HWbgPTt3k"
  }
  name     = ".NET DEV"
  settings = jsonencode({})
  slug     = "net_dev"
}