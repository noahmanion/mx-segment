import {
  to = segment_destination_subscription.id-69e7dcfa8c4f59cf1a076b2d_6cEseCw337qPpoY1f37tkL
  id = "69e7dcfa8c4f59cf1a076b2d:6cEseCw337qPpoY1f37tkL"
}

resource "segment_destination_subscription" "id-69e7dcfa8c4f59cf1a076b2d_6cEseCw337qPpoY1f37tkL" {
  action_id            = "rUAGKsZYJvuuoN1cr1pmF2"
  destination_id       = "69e7dcfa8c4f59cf1a076b2d"
  enabled              = true
  model_id             = null
  name                 = "Session Attributes Encoded Plugin"
  reverse_etl_schedule = null
  settings             = jsonencode({})
  trigger              = "type = \"track\" or type = \"identify\" or type = \"group\" or type = \"page\" or type = \"alias\""
}