# Cost Control Checklist

## Resource Governance
- [x] All environments use standard SKU tiers (B1/LRS for non-prod)
- [x] Each resource tagged with `costCenter`
- [x] Automation scripts default to minimal sizes

## Monitoring
- [ ] Azure Cost Management alerts configured
- [ ] Daily budget thresholds reviewed

## Cleanup
- [x] `cleanup.ps1` script tested and functional
- [ ] Stale environments older than 7 days auto-removed via scheduled job

## Optimization Tips
- Use `--WhatIf` before full deploys in production.
- Regularly delete unused App Service Plans.
- Centralize shared resources in one region when possible.
