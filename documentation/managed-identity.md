# Managed Identity

## Purpose

This environment uses a User Assigned Managed Identity to enable passwordless authentication between Azure services.

The identity is created independently and attached to the App Service.

## Resources

- Managed Identity: `mi-core-dev-weu`
- App Service: attached through User Assigned Identity
- Resource Group: `rg-core-dev-weu`

## Why User Assigned Managed Identity

A User Assigned Managed Identity can be reused across multiple Azure resources and has an independent lifecycle.

If the App Service is deleted, the identity can remain available.

## Benefits

- No secrets stored in code
- No client secret rotation
- Azure RBAC integration
- Enterprise-ready authentication pattern
- Prepares secure access to Key Vault

## Validation

Azure Portal:

App Service  
→ Identity  
→ User assigned  
→ `mi-core-dev-weu`

Managed Identity  
→ Associated resources  
→ App Service should be listed
