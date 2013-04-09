genericAdt= require './utils/genericAdt'

module.exports = (args, root, onComplete)->
    genericAdt.execute("uninstallApp", {appid: args["app-id"]}, args, root, onComplete)