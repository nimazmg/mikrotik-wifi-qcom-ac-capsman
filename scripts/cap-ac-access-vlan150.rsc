# MikroTik cAP AC Template - Access VLAN 150 Switch Port
# Purpose:
#   Configure a cAP AC to be managed by CAPsMAN over VLAN 150.
#
# Use this version when the switch port connected to the cAP AC is ACCESS VLAN 150:
#
#   switchport mode access
#   switchport access vlan 150
#
# In this design, the switch handles VLAN tagging.
# The AP keeps its local bridge simple and untagged.
#
# Important:
#   DHCP client must be on the bridge, not on ether1.
#   ether1 becomes a slave interface once added to the bridge.
#
# Backup first:
#   /export file=before-cap-change
#   /system backup save name=before-cap-change


# ------------------------------------------------------------------------------
# 1. Create local bridge
# ------------------------------------------------------------------------------

/interface bridge
add name=Local comment="Local bridge for AP uplink and WiFi interfaces"


# ------------------------------------------------------------------------------
# 2. Add Ethernet and WiFi interfaces to the bridge
# ------------------------------------------------------------------------------

/interface bridge port
add bridge=Local interface=ether1 comment="Uplink to access switch port VLAN 150"
add bridge=Local interface=wifi1 comment="2.4 GHz radio, CAPsMAN managed"
add bridge=Local interface=wifi2 comment="5 GHz radio, CAPsMAN managed"


# ------------------------------------------------------------------------------
# 3. DHCP client for AP management
# ------------------------------------------------------------------------------

# Because ether1 is now a bridge slave, DHCP must run on the bridge.
/ip dhcp-client
add interface=Local disabled=no use-peer-dns=yes use-peer-ntp=yes comment="Get cAP management IP from VLAN 150"


# ------------------------------------------------------------------------------
# 4. Make radios CAPsMAN controlled
# ------------------------------------------------------------------------------

/interface wifi
set [find default-name=wifi1] configuration.manager=capsman disabled=no
set [find default-name=wifi2] configuration.manager=capsman disabled=no


# ------------------------------------------------------------------------------
# 5. Enable CAP mode
# ------------------------------------------------------------------------------

# The AP discovers CAPsMAN through the Local bridge.
# caps-man-addresses is optional if DHCP option / L2 discovery works.
# Set it explicitly for reliable operation.
/interface wifi cap
set enabled=yes discovery-interfaces=Local caps-man-addresses=192.168.150.1


# ------------------------------------------------------------------------------
# 6. Optional identity
# ------------------------------------------------------------------------------

/system identity
set name="CHANGE_ME_CAP_NAME"


# ------------------------------------------------------------------------------
# 7. Verification commands
# ------------------------------------------------------------------------------

# Run these after applying:
#   /ip dhcp-client print
#   /ip address print
#   /interface wifi print
#   /interface wifi cap print
#   /log print where message~"CAP"
