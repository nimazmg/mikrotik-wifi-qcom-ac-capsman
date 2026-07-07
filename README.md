# MikroTik wifi-qcom-ac CAPsMAN with VLAN 150

GitHub-ready MikroTik RouterOS v7 configuration templates for running MikroTik **cAP AC** access points with the modern **`wifi-qcom-ac`** package and central CAPsMAN management.

This repository includes both sides of the design:

- **CAPsMAN controller side** on a MikroTik router, for example CCR2004
- **cAP AC side** configuration for access points
- VLAN-based forwarding design for WiFi traffic
- DHCP-based automatic per-client bandwidth queues

## Why this design exists

On MikroTik cAP AC devices using the **`wifi-qcom-ac`** package, traditional CAPsMAN forwarding / manager forwarding is not available in the same way as legacy CAPsMAN.

Because of that, the practical design is:

```text
WiFi traffic is locally bridged on the cAP AC
↓
Traffic is carried back to the central router using VLAN 150
↓
The central router still manages DHCP, DNS, NAT, firewalling and bandwidth queues
```

So traffic forwarding is local on the AP, but traffic policy and client management are still centralized at the router.

## Topology

Example topology:

```text
Internet
  |
MikroTik Router / CAPsMAN Controller
  |
  | trunk: VLAN 1 native + VLAN 150 tagged
  |
Core / Access Switch
  |
  | access VLAN 150 OR trunk VLAN 150
  |
MikroTik cAP AC
  |
WiFi clients on 192.168.150.0/24
```

## IP plan used in the example

| Network | Purpose | Gateway |
|---|---|---|
| `192.168.65.0/24` | Main LAN / servers / management | `192.168.65.1` |
| `192.168.150.0/24` | WiFi clients and cAP management | `192.168.150.1` |

## Files

```text
scripts/
  capsman-controller-vlan150.rsc
  cap-ac-access-vlan150.rsc
  cap-ac-trunk-vlan150.rsc
docs/
  design-notes.md
```

## Which cAP script should I use?

### Option A — Access VLAN 150 switch port

Use:

```text
scripts/cap-ac-access-vlan150.rsc
```

Use this if the switch port connected to the cAP AC is configured like this:

```text
switchport mode access
switchport access vlan 150
```

In this design, the cAP AC does not need to tag frames itself. The switch places all cAP traffic into VLAN 150.

### Option B — Trunk VLAN 150 switch port

Use:

```text
scripts/cap-ac-trunk-vlan150.rsc
```

Use this if the switch port connected to the cAP AC is configured like this:

```text
switchport mode trunk
switchport trunk allowed vlan add 150
```

In this design, the cAP AC handles VLAN 150 tagging on its Ethernet uplink.

## CAPsMAN controller script

Use:

```text
scripts/capsman-controller-vlan150.rsc
```

This configures:

- VLAN 150 interface
- DHCP server for WiFi clients and cAPs
- CAPsMAN on VLAN 150
- 2.4 GHz and 5 GHz SSID templates
- DHCP lease script that automatically creates `20M/20M` simple queues per client
- Firewall address-list examples for NAT and local access

## Important notes

- Do **not** put real passwords, public IP addresses, serial numbers or customer data into GitHub.
- Replace all `CHANGE_ME_*` values before using.
- Test in a lab or maintenance window before applying in production.
- Make an export/backup before applying scripts.

## Backup first

Before applying any script:

```routeros
/export file=before-capsman-change
/system backup save name=before-capsman-change
```

## Apply a script

Upload the `.rsc` file to the MikroTik and run:

```routeros
/import file-name=cap-ac-access-vlan150.rsc
```

or:

```routeros
/import file-name=capsman-controller-vlan150.rsc
```

## License

Use freely and adapt for your own MikroTik CAPsMAN deployments.
