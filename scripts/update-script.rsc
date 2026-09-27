# MikroTik RouterOS v7 weekly update policy
#
# Run this script on the CAPsMAN controller.
# It stages the cAP AC packages in /flash/capsman-packages and lets CAPsMAN suggest
# the matching RouterOS version to connected CAPs.
#
# The cAP AC devices in this project use the ARM architecture and wifi-qcom-ac.
# Change CHANGE_ME_CAP_PACKAGE_ARCHITECTURE if the managed CAP hardware differs.
#
# RouterOS and CAPsMAN updates require a reboot. Schedule this during a
# maintenance window because the controller may reboot after installing.

/system script
remove [find name="weekly-router-capsman-cap-update"]
add name=weekly-router-capsman-cap-update source={
:global weeklyUpdateRunning
:if ([:typeof $weeklyUpdateRunning] = "nothing") do={
    :set weeklyUpdateRunning false
}
:if ($weeklyUpdateRunning = true) do={
    :log warning "Weekly update already running; exiting"
    :return
}
:set weeklyUpdateRunning true

:local packageDirectory "flash/capsman-packages"
:local capPackageArchitecture "arm"
:local capWifiPackage "wifi-qcom-ac"
:local currentVersion [/system package get [find name="routeros"] version]
:local updateStatus ""
:local targetVersion $currentVersion

:do {
:if ([:len [/file find where name=$packageDirectory]] = 0) do={
    /file make-directory $packageDirectory
}
    }

    # Remove every previously staged package before downloading the new set.
    /file remove [find where name~("^" . $packageDirectory . "/")]

    /system package update check-for-updates once
    :delay 5s
    :set updateStatus [/system package update get status]
    :if ($updateStatus = "New version is available") do={
        :set targetVersion [/system package update get latest-version]
    }

    :if ([:len $targetVersion] = 0) do={
        :error "Unable to determine RouterOS version for CAP package staging"
    }

    /tool fetch \
        url=("https://download.mikrotik.com/routeros/" . $targetVersion . "/routeros-" . $targetVersion . "-" . $capPackageArchitecture . ".npk") \
        dst-path=($packageDirectory . "/routeros-" . $targetVersion . "-" . $capPackageArchitecture . ".npk") \
        check-certificate=yes

    /tool fetch \
        url=("https://download.mikrotik.com/routeros/" . $targetVersion . "/" . $capWifiPackage . "-" . $targetVersion . "-" . $capPackageArchitecture . ".npk") \
        dst-path=($packageDirectory . "/" . $capWifiPackage . "-" . $targetVersion . "-" . $capPackageArchitecture . ".npk") \
        check-certificate=yes

    :log info ("CAP package staging completed for RouterOS " . $targetVersion)

    :if ($updateStatus = "New version is available") do={
        :log info ("RouterOS update available: " . $targetVersion . "; installing and rebooting")
        /system package update install
    }
} on-error={
    :log error "Weekly update failed; CAP packages were not staged completely"
}

:set weeklyUpdateRunning false
}

# Run once every seven days at 03:00.
/system scheduler
remove [find name="weekly-router-capsman-cap-update"]
add name=weekly-router-capsman-cap-update \
    interval=7d \
    start-time=03:00:00 \
    on-event="/system script run weekly-router-capsman-cap-update" \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon