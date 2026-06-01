# Hybrid Connectivity

## Overview

The Hybrid Connectivity module provides enterprise-style Azure Point-to-Site (P2S) VPN connectivity for secure remote access to private Azure resources.

The implementation enables authenticated remote clients to establish encrypted VPN tunnels into Azure virtual networks using certificate-based authentication.

This solution is integrated into cloud-org-infra through modular PowerShell automation and GitHub Actions deployment workflows.

---

## Objectives

The primary goals of this implementation are:

- Secure remote access to Azure private resources
- Certificate-based authentication
- Elimination of public VM administration endpoints
- Reusable and idempotent infrastructure deployment
- Enterprise-style networking architecture
- Automated deployment through CI/CD workflows

---

## Architecture

```text
Remote Laptop
    ↓
Azure VPN Client
    ↓
Point-to-Site VPN Tunnel
    ↓
Azure VPN Gateway (VpnGw1AZ)
    ↓
Azure Virtual Network
    ↓
Private Resources
        ├── Virtual Machines
        ├── Private Endpoints
        ├── Internal Services
        └── Future Platform Components
```

---

## Components

### HybridConnectivity PowerShell Module

Location:

```text
automation/modules/HybridConnectivity/HybridConnectivity.psm1
```

Responsibilities:

- Gateway subnet validation
- VPN Public IP deployment
- Virtual Network Gateway deployment
- Point-to-Site VPN configuration
- Root certificate integration
- VPN client address pool configuration
- Hybrid connectivity orchestration

---

### Deployment Script

Location:

```text
automation/create-hybridconnectivity.ps1
```

Responsibilities:

- Execute hybrid connectivity deployment
- Coordinate module execution
- Load VPN root certificate
- Apply Point-to-Site configuration
- Maintain deployment idempotency

---

### GitHub Actions Workflow

Location:

```text
.github/workflows/deploy-hybridconnectivity.yml
```

Responsibilities:

- Azure authentication using OIDC
- Hybrid connectivity deployment
- Infrastructure automation execution
- CI/CD integration

---

## Deployment Flow

The deployment process follows a dependency-aware orchestration model.

```text
GatewaySubnet
    ↓
VPN Public IP
    ↓
Virtual Network Gateway
    ↓
Root Certificate
    ↓
Point-to-Site Configuration
    ↓
VPN Client Package
    ↓
Client Connection
```

Each stage validates existing resources before creating new ones to ensure idempotent behavior.

---

## Network Configuration

### Virtual Network

```text
vnet-core-dev-weu
```

---

### Gateway Subnet

```text
10.10.255.0/27
```

Purpose:

- Dedicated subnet required by Azure VPN Gateway

---

### VPN Client Address Pool

```text
172.16.250.0/24
```

Purpose:

- Address pool assigned to remote VPN clients

Example assigned client IP:

```text
172.16.250.2
```

---

### VPN Gateway

```text
vpngw-core-dev-weu
```

SKU:

```text
VpnGw1AZ
```

Purpose:

- Provides encrypted remote access into Azure private networking

---

### Public IP

```text
pip-vpngw-core-dev-weu
```

Configuration:

```text
Standard SKU
Zone-aware
Availability Zones: 1,2,3
```

---

## Authentication

### Root Certificate

```text
cloud-org-infra-root-cert
```

Purpose:

- Establishes trust between Azure VPN Gateway and client certificates

Uploaded to:

```text
Azure VPN Gateway
```

---

### Client Certificate

```text
cloud-org-infra-client-cert
```

Purpose:

- Authenticates remote clients during VPN connection establishment

Installed on:

```text
Remote Client Device
```

---

## VPN Protocols

Configured protocols:

```text
IKEv2
OpenVPN
```

Purpose:

- Secure encrypted communication
- Broad client compatibility
- Enterprise-grade VPN connectivity

---

## Validation Performed

The implementation was validated end-to-end.

### VPN Client Deployment

Validated:

```text
VPN client package generation
VPN profile installation
Azure VPN Client configuration
```

---

### VPN Connectivity

Validated:

```text
Successful VPN connection establishment
Certificate-based authentication
Encrypted tunnel creation
```

---

### Address Assignment

Validated:

```text
VPN Client IP: 172.16.250.2
```

---

### Private Resource Connectivity

Validated:

```text
Private VM Address: 10.10.2.5
```

---

### TCP Connectivity

Validated:

```text
Test-NetConnection 10.10.2.5 -Port 22

TcpTestSucceeded: True
```

---

### SSH Connectivity

Validated:

```text
ssh azureuser@10.10.2.5
```

Result:

```text
Successful SSH login through Point-to-Site VPN
```

---

## Idempotency

The Hybrid Connectivity deployment follows an idempotent deployment model.

Capabilities:

- Detect existing resources
- Skip unnecessary deployments
- Reuse existing infrastructure
- Apply configuration changes safely
- Support repeated executions

Deployment behavior:

```text
Run Once
Run Twice
Run Ten Times

Result:
Desired State Maintained
```

---

## Lessons Learned

Key implementation lessons:

- Azure VPN Gateways require a dedicated GatewaySubnet
- VpnGw1AZ requires zone-aware Public IP resources
- Certificate trust must be established before client authentication succeeds
- VPN client address pools must not overlap with VNet address space
- Hybrid connectivity deployment requires dependency-aware orchestration
- GitHub Actions integration benefits from configurable certificate paths
- Infrastructure automation should be designed for repeatable execution

---

## Business Value

The Hybrid Connectivity module provides:

- Secure remote administration
- Elimination of public VM exposure
- Enterprise-grade network access controls
- Foundation for private service architectures
- Future site-to-site connectivity expansion
- Support for private endpoint adoption
- Improved operational security posture

---

## Future Enhancements

Potential future improvements:

- Automated client certificate generation
- Certificate rotation workflows
- Certificate revocation support
- Site-to-Site VPN connectivity
- ExpressRoute integration
- Azure Firewall integration
- Hub-and-Spoke networking architecture
- Terraform implementation
- Monitoring and alerting enhancements

---

## Validation Evidence

Successfully validated:

- VPN Client Connected
- Assigned VPN Client IP: 172.16.250.2
- Private VM Reachability: 10.10.2.5
- SSH Connectivity Established
- GitHub Actions Deployment Workflow Created

### Validation Commands

```powershell
ipconfig

ping 10.10.2.5

Test-NetConnection 10.10.2.5 -Port 22

ssh azureuser@10.10.2.5
```

### Validation Results

```text
VPN Client IP: 172.16.250.2

Ping:
Packets Sent = 4
Packets Received = 4
Packet Loss = 0%

Port 22:
TcpTestSucceeded = True

SSH:
Connection Established Successfully

Target VM:
10.10.2.5
```

Validation Date: June 2026

---

## Outcome

Successfully implemented enterprise-grade Azure Point-to-Site VPN automation with:

- Certificate-based authentication
- Azure VPN Gateway deployment
- Private network access
- GitHub Actions integration
- Modular PowerShell automation
- Idempotent deployment behavior
- End-to-end validation

Final validated connectivity path:

```text
Remote Laptop
    ↓
Azure VPN Client
    ↓
Azure VPN Gateway
    ↓
Private Azure Network
    ↓
10.10.2.5
    ↓
SSH Access Successful
```

This implementation establishes the Hybrid Connectivity foundation for cloud-org-infra and provides a secure platform for future networking, security, and platform engineering capabilities.
