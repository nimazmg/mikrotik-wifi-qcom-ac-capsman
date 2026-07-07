# MikroTik cAP AC Template - Trunk VLAN 150 Switch Port
# Purpose:
#   Configure a cAP AC to tag WiFi/client and management traffic as VLAN 150.
#
# Use this version when the switch port connected to the cAP AC is a TRUNK:
#
#   switchport mode trunk
#   switchport trunk allowed vlan add 150
#
# In this design:
#   - ether1 is tagged VLAN 150 toward the switch
#   - wifi1/wifi2 are untagged access ports inside VLAN 150
#   - the AP management IP is received on vlan150
#
# Backup first:
#   /export file=before-cap-change
#   /system backup save name=before-cap-change


# ------------------------------------------------------------------------------
# 1. Create VLAN-aware bridge
# ------------------------------------------------------------------------------

/interface bridge
add name=Local vlan-filtering=yes comment="VLAN-aware bridge for trunked AP"


# ------------------------------------------------------------------------------
# 2. Create VLAN 150 interface for AP management
# ------------------------------------------------------------------------------

/interface vlan
add interface=Local name=vlan150 vlan-id=150 comment="AP management on VLAN 150"


# ------------------------------------------------------------------------------
# 3. Add physical and wireless interfaces to bridge
# ------------------------------------------------------------------------------

/interface bridge port
add bridge=Local interface=ether1 frame-types=admit-only-vlan-tagged comment="Tagged trunk uplink to switch"
add bridge=Local interface=wifi1 pvid=150 comment="2.4 GHz clients untagged into VLAN 150"
add bridge=Local interface=wifi2 pvid=150 comment="5 GHz clients untagged into VLAN 150"


# ------------------------------------------------------------------------------
# 4. VLAN table
# ------------------------------------------------------------------------------

# ether1 carries VLAN 150 tagged to the switch.
# wifi1 and wifi2 are untagged access ports for client traffic.
# Local must be tagged so the AP can use vlan150 for management.
/interface bridge vlan
add bridge=Local tagged=Local,ether1 untagged=wifi1,wifi2 vlan-ids=150 comment="VLAN 150 trunk uplink + WiFi access"


# ------------------------------------------------------------------------------
# 5. DHCP client for AP management
# ------------------------------------------------------------------------------

/ip dhcp-client
add interface=vlan150 disabled=no use-peer-dns=yes use-peer-ntp=yes comment="Get cAP management IP from VLAN 150"


# ------------------------------------------------------------------------------
# 6. Make radios CAPsMAN controlled
# ------------------------------------------------------------------------------

/interface wifi
set [find default-name=wifi1] configuration.manager=capsman disabled=no
set [find default-name=wifi2] configuration.manager=capsman disabled=no


# ------------------------------------------------------------------------------
# 7. Enable CAP mode
# ------------------------------------------------------------------------------

/interface wifi cap
set enabled=yes discovery-interfaces=vlan150 caps-man-addresses=192.168.150.1


# ------------------------------------------------------------------------------
# 8. Optional identity
# ------------------------------------------------------------------------------

/system identity
set name="CHANGE_ME_CAP_NAME"


# ------------------------------------------------------------------------------
# 9. Verification commands
# ------------------------------------------------------------------------------

# Run these after applying:
#   /ip dhcp-client print
#   /ip address print
#   /interface bridge vlan print
#   /interface wifi cap print
#   /log print where message~"CAP"
