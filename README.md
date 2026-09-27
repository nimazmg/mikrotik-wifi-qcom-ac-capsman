# MikroTik wifi-qcom-ac CAPsMAN with VLAN 150

![MikroTik Script](https://img.shields.io/badge/MikroTik-Script-blue?logo=router)

GitHub-ready MikroTik RouterOS v7 configuration templates for running MikroTik cAP AC access points with the modern `wifi-qcom-ac` package and central CAPsMAN management.

This repository includes both sides of the design:

- CAPsMAN controller configuration for a MikroTik router
- cAP AC configuration for access points
- VLAN-based forwarding for WiFi traffic
- DHCP-based automatic per-client bandwidth queues
- Optional CAPsMAN package persistence on flash storage

## Why this design exists

On MikroTik cAP AC devices using the `wifi-qcom-ac` package, traditional CAPsMAN forwarding / manager forwarding is not used in the same way as the legacy CAPsMAN model.

The practical design is:

```text
WiFi traffic is locally bridged on the cAP AC
↓
Traffic is carried back to the central router using VLAN 150
↓
The central router still manages DHCP, DNS, NAT, firewalling, and bandwidth queues
```

So traffic forwarding is local on the AP, while traffic policy and client management remain centralized at the router.

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
  capsman-controller.rsc
  cap-ac-access.rsc
  cap-ac-trunk.rsc
docs/
  design-notes.md
```

## Recent updates

The repository has been updated to reflect the current RouterOS v7 CAPsMAN workflow:

- WiFi configuration values are now explicitly configurable before deployment
- SSID names, datapath names, security profile names, and country are set via `CHANGE_ME_*` values
- CAPsMAN package upgrade persistence is configured with:

```routeros
/interface wifi capsman
set enabled=yes \
    interfaces=vlan150 \
    package-path=/flash/capsman-packages \
    upgrade-policy=suggest-same-upgrade
```

This keeps CAPsMAN upgrade packages on flash storage instead of relying on default package locations.

## Which cAP script should I use?

### Option A — Access VLAN 150 switch port

Use:

```text
scripts/cap-ac-access.rsc
```

Use this when the switch port connected to the cAP AC is configured like this:

```text
switchport mode access
switchport access vlan 150
```

In this design, the switch handles VLAN tagging and the AP keeps a simple local bridge without VLAN tagging on the uplink.

### Option B — Trunk VLAN 150 switch port

Use:

```text
scripts/cap-ac-trunk.rsc
```

Use this when the switch port connected to the cAP AC is configured like this:

```text
switchport mode trunk
switchport trunk allowed vlan add 150
```

In this design, the cAP AC handles VLAN 150 tagging on its Ethernet uplink.

## CAPsMAN controller script

Use:

```text
scripts/capsman-controller.rsc
```

This configures:

- VLAN 150 interface
- DHCP server for WiFi clients and cAPs
- CAPsMAN on VLAN 150
- 2.4 GHz and 5 GHz SSID templates
- DHCP lease script that automatically creates `20M/20M` simple queues per client
- Firewall address-list examples for NAT and local access
- CAPsMAN package path persistence on flash storage

## Required configuration values to change

Before deployment, replace the template placeholders in the controller script:

- `CHANGE_ME_WIFI_PASSWORD`
- `CHANGE_ME_WIFI_2GHZ_SSID`
- `CHANGE_ME_WIFI_5GHZ_SSID`
- `CHANGE_ME_WIFI_DATAPATH_NAME`
- `CHANGE_ME_WIFI_SECURITY_NAME`
- `CHANGE_ME_COUNTRY`
- `CHANGE_ME_UPLINK_INTERFACE`

For the AP script, also set the device identity as needed:

- `CHANGE_ME_CAP_NAME`

## Important notes

- Do not put real passwords, public IP addresses, serial numbers, or customer data into GitHub.
- Replace all `CHANGE_ME_*` values before using.
- Test in a lab or maintenance window before applying in production.
- Make an export/backup before applying scripts.
- For newer CAPsMAN packages, the controller explicitly keeps upgrade files under `/flash/capsman-packages`.

## Backup first

Before applying any script:

```routeros
/export file=before-capsman-change
/system backup save name=before-capsman-change
```

## Apply a script

Upload the `.rsc` file to the MikroTik and run:

```routeros
/import file-name=cap-ac-access.rsc
```

or:

```routeros
/import file-name=cap-ac-trunk.rsc
```

or:

```routeros
/import file-name=capsman-controller.rsc
```

## Additional reference

For the design rationale and traffic-flow explanation, see the notes in [docs/design-notes.md](docs/design-notes.md).

## License

Use freely and adapt for your own MikroTik CAPsMAN deployments.
