module.exports = (args, path, onComplete)->
    start = Date.now()
    @packageReinstallAir args, path, (error, packageResult)=>
        if error then onComplete(error)
        else
            @launchAir args, path, (error, result)->
                if error then onComplete(error)
                else
                    packageResult.parts.push(result)
                    packageResult.duration = Date.now()-start
                    onComplete(null, packageResult)
