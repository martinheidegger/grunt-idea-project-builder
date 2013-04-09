addRegularArgument = require './addRegularArgument'

module.exports = (args, argList, separator, ignore...)->
    for name, value of args
        if ignore.indexOf(name) == -1
            argList.push addRegularArgument(name, value, separator)
    return argList