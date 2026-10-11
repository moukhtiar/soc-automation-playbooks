# STATUS: reference only, NOT YET APPLIED. See versions.tf.
variable "resource_group_name" { default = "rg-infra-sec" }
variable "workspace_name"      { default = "law-sec-central" }

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "sec" {
  name = var.resource_group_name
}

data "azurerm_log_analytics_workspace" "law" {
  name                = var.workspace_name
  resource_group_name = data.azurerm_resource_group.sec.name
}

# Playbook shell with managed identity. Build the workflow body in the designer (see ../playbook).
resource "azurerm_logic_app_workflow" "pb" {
  name                = "pb-sentinel-notify-disabledacct"
  location            = data.azurerm_resource_group.sec.location
  resource_group_name = data.azurerm_resource_group.sec.name

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "pb_responder" {
  scope                = data.azurerm_resource_group.sec.id
  role_definition_name = "Microsoft Sentinel Responder"
  principal_id         = azurerm_logic_app_workflow.pb.identity[0].principal_id
}

data "azuread_service_principal" "sentinel" {
  display_name = "Azure Security Insights"
}

resource "azurerm_role_assignment" "sentinel_automation" {
  scope                = data.azurerm_resource_group.sec.id
  role_definition_name = "Microsoft Sentinel Automation Contributor"
  principal_id         = data.azuread_service_principal.sentinel.object_id
}

resource "random_uuid" "ar_triage" {}
resource "random_uuid" "ar_notify" {}

resource "azurerm_sentinel_automation_rule" "triage" {
  name                       = random_uuid.ar_triage.result
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  display_name               = "ar-disabledacct-triage"
  order                      = 1
  triggers_on                = "Incidents"
  triggers_when              = "Created"

  # TODO: add a condition on the analytics rule name (syntax depends on provider version).

  action_incident {
    order  = 1
    status = "Active"
  }

  action_incident {
    order  = 2
    labels = ["auto-triaged"]
  }

  depends_on = [azurerm_role_assignment.sentinel_automation]
}

resource "azurerm_sentinel_automation_rule" "notify" {
  name                       = random_uuid.ar_notify.result
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  display_name               = "ar-disabledacct-notify"
  order                      = 2
  triggers_on                = "Incidents"
  triggers_when              = "Created"

  # TODO: same analytics rule name condition as above.

  action_playbook {
    order        = 1
    logic_app_id = azurerm_logic_app_workflow.pb.id
    tenant_id    = data.azurerm_client_config.current.tenant_id
  }

  depends_on = [azurerm_role_assignment.sentinel_automation]
}
