runUnitTest = require './runUnitTest'
{exec} = require 'child_process'
{getFlexHome} = require './utils'

module.exports = (args, path, onComplete)->
    try
        flexHome = getFlexHome(args)
    catch e
        onComplete e
        return

    cmd = (onComplete) ->
        try
            cmd = "#{flexHome}/bin/adl #{args.descriptor} -profile extendedDesktop"
            console.info cmd, path
            return exec cmd, {cwd: path}, onComplete
        catch e
            console.error e.stack
            onComplete(e)
    runUnitTest cmd, onComplete