import {
  to = segment_destination_subscription.id-69e6bbe9e9d0b41c5df9fc40_xwt6EyzaESw3etAZQhmXWB
  id = "69e6bbe9e9d0b41c5df9fc40:xwt6EyzaESw3etAZQhmXWB"
}

resource "segment_destination_subscription" "id-69e6bbe9e9d0b41c5df9fc40_xwt6EyzaESw3etAZQhmXWB" {
  action_id            = "dGDsZPqKXXCQNrgDcr1oKb"
  destination_id       = "69e6bbe9e9d0b41c5df9fc40"
  enabled              = true
  model_id             = null
  name                 = "Create or Update an Activity"
  reverse_etl_schedule = null
  settings = jsonencode({
    activity_id = {
      "@path" = "$.properties.activity_id"
    }
    deal_match_value = {
      "@path" = "$.properties.deal_id"
    }
    description = {
      "@path" = "$.properties.description"
    }
    done = {
      "@path" = "$.properties.done"
    }
    due_date = {
      "@path" = "$.properties.due_date"
    }
    due_time = {
      "@path" = "$.properties.due_time"
    }
    duration = {
      "@path" = "$.properties.duration"
    }
    note = {
      "@path" = "$.properties.note"
    }
    organization_match_value = {
      "@path" = "$.context.groupId"
    }
    person_match_value = {
      "@path" = "$.userId"
    }
    subject = {
      "@path" = "$.properties.subject"
    }
    type = {
      "@path" = "$.properties.type"
    }
  })
  trigger = "type = \"track\" and event = \"Activity Upserted\""
}