xtend = require 'xtend'
flashAPI = require 'flash-build-api'
augmentAdt = require "./augmentAdt"

module.exports = xtend flashAPI, {
    installAir                : augmentAdt flashAPI, "installAir"
    launchAir                 : augmentAdt flashAPI, "launchAir"
    packageAir                : augmentAdt flashAPI, "packageAir"
    packageReinstallAir       : augmentAdt flashAPI, "packageReinstallAir"
    packageReinstallLaunchAir : augmentAdt flashAPI, "packageReinstallLaunchAir"
    reinstallAir              : augmentAdt flashAPI, "reinstallAir"
    reinstallLaunchAir        : augmentAdt flashAPI, "reinstallLaunchAir"
    uninstallAir              : augmentAdt flashAPI, "uninstallAir"
    parseProject              : require './parseProject'
} 