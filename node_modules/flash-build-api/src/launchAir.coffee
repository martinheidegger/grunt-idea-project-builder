genericAdt= require './utils/genericAdt'

module.exports = (args, root, onComplete)->
    genericAdt.execute("launchApp", {appid: args["app-id"]}, args, root, onComplete)