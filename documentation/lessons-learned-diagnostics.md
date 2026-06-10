# Lessons Learned - Diagnostics

## Challenge

Azure Diagnostic Settings deployment required multiple deployment iterations because different Azure resources expose different log categories, metric categories, and diagnostic capabilities.

## Resolution

The diagnostics deployment logic was updated to validate resource IDs, target the correct Log Analytics Workspace, and configure supported diagnostic categories through Azure Resource Manager.

## Outcome

Diagnostic settings can be managed through the cloud-org-infra automation workflow and connected to the existing Log Analytics Workspace.

## AZ-104 Topics

- Azure Monitor
- Log Analytics Workspace
- Diagnostic Settings
- Resource Logs
- Platform Metrics
- Activity Log
- Monitoring and alerting

## Key Takeaway

Diagnostic Settings are the connection between Azure resources and centralized monitoring.
