# Design Notes

## Problem

MikroTik cAP AC access points running the modern `wifi-qcom-ac` package are managed through the new `/interface wifi` CAPsMAN system.

With this package on cAP AC devices, CAPsMAN forwarding / manager forwarding is not used in the same way as the legacy CAPsMAN model.

## Solution

Use local forwarding on the AP, but place AP management and WiFi clients into a dedicated VLAN.

In this example:

```text
VLAN 150 = WiFi clients + cAP management
Subnet   = 192.168.150.0/24
Gateway  = 192.168.150.1
CAPsMAN  = 192.168.150.1
```

The AP locally bridges WiFi clients to VLAN 150. The central router receives that VLAN and still controls:

- DHCP
- DNS
- NAT
- firewall policy
- routing
- per-client simple queues
- CAPsMAN configuration

## Traffic flow

```text
Client connects to SSID
  ↓
cAP AC bridges client traffic locally
  ↓
Traffic enters VLAN 150
  ↓
Switch carries VLAN 150 to the router
  ↓
Router handles DHCP, DNS, NAT, firewall and queues
```

## Why this is still centrally managed

Even though the AP locally forwards traffic, the router remains the central control point because:

- the IP gateway is on the router
- DHCP is on the router
- DNS is on the router
- NAT and firewall are on the router
- per-client bandwidth queues are created on the router
- CAPsMAN provisions the SSIDs and security profiles

## Recommended switch design

For simplicity, use an access VLAN port for APs:

```text
switchport mode access
switchport access vlan 150
spanning-tree portfast
```

Use a trunk port only if you need multiple VLANs/SSIDs on the AP.
