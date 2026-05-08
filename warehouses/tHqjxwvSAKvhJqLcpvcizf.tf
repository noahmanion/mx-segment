import {
  to = segment_warehouse.id-tHqjxwvSAKvhJqLcpvcizf
  id = "tHqjxwvSAKvhJqLcpvcizf"
}

resource "segment_warehouse" "id-tHqjxwvSAKvhJqLcpvcizf" {
  enabled = true
  metadata = {
    id = "kwX50Df0hr"
  }
  name = "BigQuery Warehouse"
  settings = jsonencode({
    credential_id = "3CdwyYQHzS1Z5UR8Lth8jo87OrZ"
    location      = "US"
  })
}