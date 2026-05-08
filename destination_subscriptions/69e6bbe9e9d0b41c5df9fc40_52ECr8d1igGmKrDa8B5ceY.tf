import {
  to = segment_destination_subscription.id-69e6bbe9e9d0b41c5df9fc40_52ECr8d1igGmKrDa8B5ceY
  id = "69e6bbe9e9d0b41c5df9fc40:52ECr8d1igGmKrDa8B5ceY"
}

resource "segment_destination_subscription" "id-69e6bbe9e9d0b41c5df9fc40_52ECr8d1igGmKrDa8B5ceY" {
  action_id            = "66wGU3cfJrrdBk8CqekrJc"
  destination_id       = "69e6bbe9e9d0b41c5df9fc40"
  enabled              = true
  model_id             = null
  name                 = "Create or Update a Person"
  reverse_etl_schedule = null
  settings = jsonencode({
    email = {
      "@path" = "$.traits.email"
    }
    match_value = {
      "@path" = "$.userId"
    }
    name = {
      "@path" = "$.traits.name"
    }
    phone = {
      "@path" = "$.traits.phone"
    }
  })
  trigger = "type = \"identify\""
}