# MikroTik RouterOS v7 CAPsMAN Controller Template
# Purpose:
#   Central CAPsMAN controller + VLAN 150 WiFi client network.
#
# Tested design:
#   - RouterOS v7
#   - New /interface wifi CAPsMAN
#   - cAP AC devices using wifi-qcom-ac package
#
# Important:
#   On cAP AC devices with wifi-qcom-ac, CAPsMAN forwarding is not used here.
#   WiFi traffic is locally bridged on the AP and carried back to this router with VLAN 150.
#   This router still centrally manages DHCP, DNS, NAT, firewall and bandwidth queues.
#
# Replace these values before using:
#   CHANGE_ME_WIFI_PASSWORD
#   CHANGE_ME_COUNTRY
#   CHANGE_ME_UPLINK_INTERFACE
#
# Backup first:
#   /export file=before-capsman-change
#   /system backup save name=before-capsman-change


# ------------------------------------------------------------------------------
# 1. Bridge and VLAN interfaces
# ------------------------------------------------------------------------------

# Main bridge. If you already have a bridge, do not duplicate it.
# Change "Local" to your actual bridge name if different.
/interface bridge
add name=Local vlan-filtering=yes comment="Main LAN bridge"

# VLAN 1 example interface for main LAN.
# Remove this if your router already has an existing LAN interface.
/interface vlan
add interface=Local name=vlan1 vlan-id=1 comment="Main LAN VLAN"

# VLAN 150 for cAP management and WiFi clients.
/interface vlan
add interface=Local name=vlan150 vlan-id=150 comment="CAPsMAN / cAP AC / WiFi clients VLAN"


# ------------------------------------------------------------------------------
# 2. Uplink trunk to switch
# ------------------------------------------------------------------------------

# Add your switch uplink to the bridge.
# Replace CHANGE_ME_UPLINK_INTERFACE with your real interface, for example:
#   ether5
#   sfp-sfpplus1
#   To-Local-Network
#
# If your uplink is already a bridge port, do not add it again.
/interface bridge port
add bridge=Local interface=CHANGE_ME_UPLINK_INTERFACE comment="Trunk to switch carrying VLAN 150"

# Allow VLAN 150 tagged toward the switch.
# Local must be tagged so the router VLAN interface can receive VLAN 150.
/interface bridge vlan
add bridge=Local tagged=Local,CHANGE_ME_UPLINK_INTERFACE vlan-ids=150 comment="VLAN 150 tagged to switch/AP network"


# ------------------------------------------------------------------------------
# 3. IP addressing
# ------------------------------------------------------------------------------

# Main LAN example. Remove if you already have a LAN gateway.
/ip address
add address=192.168.65.1/24 interface=vlan1 comment="Main LAN gateway"

# VLAN 150 gateway.
/ip address
add address=192.168.150.1/24 interface=vlan150 comment="WiFi / cAP VLAN gateway"


# ------------------------------------------------------------------------------
# 4. DHCP server for VLAN 150
# ------------------------------------------------------------------------------

/ip pool
add name=dhcp_pool_vlan150 ranges=192.168.150.10-192.168.150.250

# DHCP lease script:
#   - When a client receives an IP, create a simple queue for that client.
#   - When the lease expires/unbinds, remove the queue.
#   - Default limit: 20M download / 20M upload.
#
# Change max-limit if you want a different speed policy.
/ip dhcp-server
add name=CAPs-Management \
    interface=vlan150 \
    address-pool=dhcp_pool_vlan150 \
    lease-time=1d \
    lease-script=":local qName (\"CAP150-\" . \$leaseActIP); \
:if (\$leaseBound = \"1\") do={ \
    /queue simple remove [find name=\$qName]; \
    /queue simple add name=\$qName target=(\$leaseActIP . \"/32\") max-limit=20M/20M comment=(\"Auto VLAN150 limit \" . \$leaseActMAC); \
} else={ \
    /queue simple remove [find name=\$qName]; \
}"

# Tell clients the gateway, DNS and CAPsMAN address.
/ip dhcp-server network
add address=192.168.150.0/24 \
    gateway=192.168.150.1 \
    dns-server=192.168.150.1 \
    caps-manager=192.168.150.1


# ------------------------------------------------------------------------------
# 5. DNS
# ------------------------------------------------------------------------------

/ip dns
set allow-remote-requests=yes


# ------------------------------------------------------------------------------
# 6. Basic NAT address-list example
# ------------------------------------------------------------------------------

# Add VLAN 150 to NAT and local address lists.
# You still need your own srcnat/masquerade rule depending on your WAN setup.
/ip firewall address-list
add address=192.168.150.0/24 list=NAT comment="WiFi VLAN allowed to NAT"
add address=192.168.150.0/24 list=Local comment="WiFi VLAN local network"


# ------------------------------------------------------------------------------
# 7. WiFi CAPsMAN datapath, security and SSIDs
# ------------------------------------------------------------------------------

# Datapath:
#   bridge=Local is used for local forwarding.
#   Do not set CAPsMAN forwarding here.
#   Do not rely on manager forwarding with wifi-qcom-ac cAP AC design.
/interface wifi datapath
add name=Store-Wi-Fi bridge=Local disabled=no comment="Local forwarding datapath"

# Security profile.
# Replace CHANGE_ME_WIFI_PASSWORD before use.
/interface wifi security
add name=Store-main \
    authentication-types=wpa2-psk \
    passphrase="CHANGE_ME_WIFI_PASSWORD" \
    disabled=no

# 2.4 GHz SSID template.
# Replace CHANGE_ME_COUNTRY with your country, for example Armenia.
/interface wifi configuration
add name=Daryana-2GHz \
    country=CHANGE_ME_COUNTRY \
    ssid="Daryana-2GHz" \
    security=Store-main \
    datapath=Store-Wi-Fi \
    disabled=no

# 5 GHz SSID template.
/interface wifi configuration
add name=Daryana-5GHz \
    country=CHANGE_ME_COUNTRY \
    ssid="Daryana-5GHz" \
    security=Store-main \
    datapath=Store-Wi-Fi \
    disabled=no


# ------------------------------------------------------------------------------
# 8. Enable CAPsMAN on VLAN 150
# ------------------------------------------------------------------------------

# CAPsMAN should listen on VLAN 150 because cAP devices get management IPs there.
/interface wifi capsman
set enabled=yes interfaces=vlan150


# ------------------------------------------------------------------------------
# 9. Provisioning rules
# ------------------------------------------------------------------------------

# Provision 5 GHz radios.
/interface wifi provisioning
add action=create-dynamic-enabled \
    master-configuration=Daryana-5GHz \
    name-format=cAP-5GHz \
    supported-bands=5ghz-ac \
    disabled=no

# Provision 2.4 GHz radios.
/interface wifi provisioning
add action=create-dynamic-enabled \
    master-configuration=Daryana-2GHz \
    name-format=cAP-2GHz \
    supported-bands=2ghz-n \
    disabled=no


# ------------------------------------------------------------------------------
# 10. Verification commands
# ------------------------------------------------------------------------------

# Run these after applying:
#   /interface wifi capsman print
#   /interface wifi registration-table print
#   /ip dhcp-server lease print where server=CAPs-Management
#   /queue simple print where name~"CAP150"
#   /interface bridge vlan print
#   /ip address print where interface=vlan150
