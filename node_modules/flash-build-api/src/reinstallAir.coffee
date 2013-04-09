uninstallAir = require './uninstallAir'
installAir = require './installAir'

module.exports = (args, root, onComplete)->
    start = Date.now()
    results = {
        parts: []
    }
    uninstallAir args, root, (error, result)->
        results.parts.push result
        installAir args, root, (error, result)->
            if error? then onComplete(error)
            else
                results.parts.push result
                results.duration = Date.now()-start 
                onComplete(null, results)