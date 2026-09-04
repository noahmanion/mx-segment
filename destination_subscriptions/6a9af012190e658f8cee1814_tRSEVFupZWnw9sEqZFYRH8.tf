import {
  to = segment_destination_subscription.id-6a9af012190e658f8cee1814_tRSEVFupZWnw9sEqZFYRH8
  id = "6a9af012190e658f8cee1814:tRSEVFupZWnw9sEqZFYRH8"
}

resource "segment_destination_subscription" "id-6a9af012190e658f8cee1814_tRSEVFupZWnw9sEqZFYRH8" {
  action_id            = "dGDsZPqKXXCQNrgDcr1oKb"
  destination_id       = "6a9af012190e658f8cee1814"
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