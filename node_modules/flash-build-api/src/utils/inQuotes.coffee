module.exports = (text) ->
    text = text
            .replace(/\\/g, "\\\\")
            .replace(/\"/g, "\\\"")
    return "\"#{text}\""