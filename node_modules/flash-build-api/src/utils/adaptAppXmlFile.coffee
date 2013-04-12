fs = require 'fs'
path = require 'path'
adaptAppXml = require './adaptAppXml'

module.exports = (input, output, mainFile, root, version, id, onComplete)->
    inputFile = path.resolve(root, input)
    outputFile = path.resolve(root, output)
    fs.readFile inputFile, (error, data)->
        if error then onComplete(error)
        else
            adaptAppXml(data.toString(), inputFile, outputFile, mainFile, version, id, onComplete)