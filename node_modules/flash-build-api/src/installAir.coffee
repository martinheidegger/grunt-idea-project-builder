genericAdt = require './utils/genericAdt'
{getPlatformForTarget} = require './utils'
path = require 'path'

module.exports = (args, root, onComplete)->
    command = "installApp"
    platform = getPlatformForTarget(args.target)
    if platform?
        ending = if platform == "android" then "apk" else "ipa"
        genericAdt.executeWithPlatform(command, {
            "package": path.resolve(
                path.resolve(root,
                    path.dirname(args.output),
                    path.basename(args.output, ".#{ending}")+".#{ending}"
                )
            )}, args, root, platform, onComplete)
    else
        onComplete(new Error("Don't now how to #{command} -target='#{args.target}'"))