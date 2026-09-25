# Azure Monitor Investigation: When a Flat CPU Graph Was Not an Incident

## Scenario

While reviewing the monitoring data for `vm-core-dev-deu-01`, I noticed that the average CPU metric had suddenly dropped from approximately 7% to almost zero.

A flat metric could indicate several things:

* the VM stopped;
* monitoring stopped collecting data;
* the resource became unavailable;
* an automation process changed the VM state.

Instead of treating the graph as proof of a failure, I used it as the starting point for an investigation.

## Investigation

### 1. Review the platform metric

The Azure Monitor CPU chart showed when the change occurred.

Platform metrics helped answer:

> What changed, and when?

The chart showed the symptom, but it did not explain the cause.

![VM CPU metric](./images/azure-monitor-investigation/cpu-metric.png)

### 2. Check the Activity Log

I then checked the VM Activity Log for control-plane operations around the same time.

The log showed a successful `Deallocate Virtual Machine` operation initiated by the identity used by my GitHub Actions automation.

This confirmed that the VM had not failed. It had been intentionally deallocated by the configured workflow.

The Activity Log helped answer:

> What operation changed the resource, and who initiated it?

![VM Activity Log](./images/azure-monitor-investigation/activity-log.png)

### 3. Query collected data with KQL

I also used the Log Analytics Workspace to inspect metrics collected from Azure resources.

```kusto
AzureMetrics
| project TimeGenerated, Resource, ResourceGroup, MetricName,
          Average, Maximum, UnitName
| sort by TimeGenerated desc
| take 10
```

This query:

1. reads records from the `AzureMetrics` table;
2. selects the relevant properties;
3. sorts the records from newest to oldest;
4. returns the latest ten results.

![AzureMetrics KQL query](./images/azure-monitor-investigation/azuremetrics-kql.png)

## Understanding the monitoring paths

| Question                                          | Azure source                                  |
| ------------------------------------------------- | --------------------------------------------- |
| How is the resource performing?                   | Azure Monitor Metrics                         |
| Who changed the resource?                         | Activity Log                                  |
| What data was sent to the workspace?              | Log Analytics and KQL                         |
| What is happening inside the VM operating system? | Azure Monitor Agent and Data Collection Rules |

These are related monitoring capabilities, but they answer different questions.

`AzureMetrics` contains Azure resource metrics sent to Log Analytics, typically through Diagnostic Settings.

Guest operating system telemetry follows a different path:

```text
Virtual Machine
    → Azure Monitor Agent
    → Data Collection Rule
    → Log Analytics Workspace
    → Heartbeat / Perf / Syslog
```

A useful validation query for VM connectivity is:

```kusto
Heartbeat
| summarize
    LastHeartbeat = max(TimeGenerated),
    Samples = count()
    by Computer, _ResourceId
| sort by LastHeartbeat desc
```

## Conclusion

The flat CPU graph was not an incident.

It was evidence that the scheduled automation had successfully deallocated the VM.

The investigation reinforced a useful troubleshooting principle:

> Treat every problem as a hypothesis to verify, not as a conclusion.

Metrics showed the symptom.

The Activity Log explained the cause.

Log Analytics and KQL provided a deeper way to investigate the collected data.
