inQuotes = require "./inQuotes"
allInQuotes = require "./allInQuotes"

module.exports = (name, value, separator)->
    arg = "-#{name}#{separator}"
    if typeof value == "string"
        if !isNaN(parseInt(value))
            arg += value
        else if value.toLowerCase() == "true"
            arg += "true"
        else if value.toLowerCase() == "false"
            arg += "false"
        else
            arg += inQuotes(value)
    else
        arg += allInQuotes(value).join(",")