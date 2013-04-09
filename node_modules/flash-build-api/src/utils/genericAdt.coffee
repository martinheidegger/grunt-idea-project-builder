addRegularArguments  = require './addRegularArguments'
deepExtend           = require './deepExtend'
executeJar           = require './executeJar'
getFlexHome          = require './getFlexHome'
getPlatformForTarget = require './getPlatformForTarget'
{exec}               = require 'child_process'

executeWithPlatform = (command, commandArgs, args, root, platform, onComplete)->
    addArgs = {}
    addArgs[command] = null
    addArgs.platform = platform
    if args.device then addArgs.device = args.device

    executeJar getFlexHome(args)+"/lib/adt.jar"
        , addRegularArguments(deepExtend(addArgs, commandArgs), [], " ").join(" ")
        , root
        , onComplete

module.exports = {
    executeWithPlatform: executeWithPlatform
    execute: (command, commandArgs, args, root, onComplete)->
        platform = getPlatformForTarget(args.target)
        if platform?
            executeWithPlatform(command, commandArgs, args, root, platform, onComplete)
        else
            onComplete(new Error("Don't now how to #{command} -target='#{args.target}'"))
}