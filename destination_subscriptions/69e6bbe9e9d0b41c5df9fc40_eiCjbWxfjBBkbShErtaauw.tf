import {
  to = segment_destination_subscription.id-69e6bbe9e9d0b41c5df9fc40_eiCjbWxfjBBkbShErtaauw
  id = "69e6bbe9e9d0b41c5df9fc40:eiCjbWxfjBBkbShErtaauw"
}

resource "segment_destination_subscription" "id-69e6bbe9e9d0b41c5df9fc40_eiCjbWxfjBBkbShErtaauw" {
  action_id            = "uVzPR9SSpfLqF3zoPok99Q"
  destination_id       = "69e6bbe9e9d0b41c5df9fc40"
  enabled              = true
  model_id             = null
  name                 = "Create or Update an Organization"
  reverse_etl_schedule = null
  settings = jsonencode({
    match_value = {
      "@path" = "$.groupId"
    }
    name = {
      "@path" = "$.traits.name"
    }
  })
  trigger = "type = \"group\""
}