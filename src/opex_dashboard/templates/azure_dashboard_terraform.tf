locals {
  name = "${var.prefix}-${var.env_short}-{{name}}"
}

resource "azurerm_resource_group" "this" {
  name     = "${local.name}-rg"
  location = "{{ location }}"
}

resource "azurerm_dashboard" "this" {
  name                = local.name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = var.tags

  dashboard_properties = <<-PROPS
    {{ dashboard_properties }}
  PROPS
}

{% for endpoint in endpoints %}
resource "azurerm_monitor_scheduled_query_rules_alert" "alarm_availability_{{ forloop.counter0 }}" {
  name                = replace(join("_",split("/", "${local.name}-availability @ {{endpoint}}")), "/\\{|\\}/", "")
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  action {
    action_group = []
  }

  data_source_id          = "{{ data_source_id }}"
  description             = "Availability for {{endpoint}} is less than or equal to 99%"
  enabled                 = true
  auto_mitigation_enabled = false

  query = <<-QUERY
    {% include "queries/availability.kusto" with is_alarm=True %}
  QUERY

  severity    = 0
  frequency   = 10
  time_window = 20
  trigger {
    operator  = "GreaterThanOrEqual"
    threshold = 1
  }

  tags = var.tags
}

resource "azurerm_monitor_scheduled_query_rules_alert" "alarm_time_{{ forloop.counter0 }}" {
  name                = replace(join("_",split("/", "${local.name}-responsetime @ {{endpoint}}")), "/\\{|\\}/", "")
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  action {
    action_group = []
  }

  data_source_id          = "{{ data_source_id }}"
  description             = "Response time for {{endpoint}} is less than or equal to 1s"
  enabled                 = true
  auto_mitigation_enabled = false

  query = <<-QUERY
    {% include "queries/response_time.kusto" with is_alarm=True %}
  QUERY

  severity    = 0
  frequency   = 10
  time_window = 20
  trigger {
    operator  = "GreaterThanOrEqual"
    threshold = 1
  }

  tags = var.tags
}
{% endfor %}
