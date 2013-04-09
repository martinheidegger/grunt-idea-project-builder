inQuotes = require './inQuotes'

module.exports = (input) ->
    result = []
    if input? then for part, pos in input
        result[pos] = inQuotes(part)
    return result