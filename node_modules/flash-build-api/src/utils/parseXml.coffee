fs = require 'fs'
ExpatParser = require('node-expat').Parser

safe = (parser, error, mtd)->
    return ->
        try
            mtd.apply(null, arguments)
        catch text
            error(text)

module.exports = (path, format, onComplete)->
    fs.readFile path, (err, dataInput)->
        if err
            onComplete(err)
        else
            data = {}
            current = format(data)
            firstNode = null
            treeNames = []
            tree = []

            parser = new ExpatParser("utf-8")

            hasError = false

            msg = ""

            error = (err)->
                hasError = true
                parser.stop()
                onComplete(err, null)

            parser.on "startElement", safe(parser, error, (nodeType, attributes) ->
                if !hasError
                    if current != undefined then tree.push(current)
                    current = if current then current[nodeType] else null
                    if current == undefined then throw "Unexpected node type "+treeNames.join(">")+">#{nodeType} @ #{path}"
                    if typeof current == "function"
                        current = current(attributes)
                    treeNames.push(nodeType)
            )
            
            parser.on "endElement", safe(parser, error, (nodeType) ->
                if !hasError
                    currentNodeName = treeNames.pop()
                    if nodeType != currentNodeName then error "Trying to close block '#{currentNodeName}' with '#{nodeType}'"
                    if current == undefined then throw "Unexpected end of the block '#{nodeType}'"
                    else if current && current.$end then current.$end()
                    current = tree.pop()
            )
            
            parser.on "text", safe(parser, error, (txt) ->
                if current && current.$text then current.$text(txt)
            )

            if !parser.parse(dataInput.toString(), true)
                onComplete(new Error("Error while parsing: #{path}: "+parser.getError()))
            else
                onComplete(null, {
                    path
                    data
                })