inQuotes = require "./inQuotes"

addDebugFlags = (flags, useDebugFlag)->
    flags['CONFIG::release'] = !useDebugFlag
    flags['CONFIG::debug'] = useDebugFlag

module.exports = (args, argList, useDebugFlag=false)->
    args.define ?= {}
    addDebugFlags(args.define, useDebugFlag)
    for name, value of args.define
        if typeof value == "string"
            value = inQuotes("'#{value}'")
        else
            value = value.toString()
        argList.push("-define=#{name},#{value}")

    return argList
