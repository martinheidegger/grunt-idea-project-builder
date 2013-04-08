{DOMParser, XMLSerializer} = require 'xmldom'
fs = require 'fs'
path = require 'path'
{packageAir} = require 'flash-build-api'

createDescriptor = (input, output, mainFile, root, version, id, onComplete)->
    inputFile = path.resolve(root, input)
    fs.readFile inputFile, (error, data)->
        if error then onComplete(error)
        else
            try
                parser = new DOMParser()
                dom = parser.parseFromString(data.toString())
                doc = dom.documentElement
                for child in doc.childNodes
                    switch child.nodeName
                        when "initialWindow"
                            for subchild in child.childNodes
                                if subchild.nodeName == "content"
                                    subchild.firstChild.data = mainFile
                        when "versionNumber"
                            if version?
                                child.firstChild.data = version
                        when "id"
                            if id?
                                child.firstChild.data = id
                            else
                                id = child.firstChild.data



                outputFile = path.resolve(root, output)
                console.info "Writing changes on file #{inputFile} to #{outputFile}"
                fs.writeFile outputFile, new XMLSerializer().serializeToString(doc), (error, result)->
                    if error then onComplete(error)
                    else
                        onComplete(null, id)
            catch e
                onComplete(e)

module.exports = (scope, methodName)->
    method = scope[methodName]
    return (args, root, onComplete)->
        if args.inputDescriptor && args.descriptor
            createDescriptor args.inputDescriptor, args.descriptor, args.mainFile, root, args.version, args["app-id"], (error, result)->
                if error then onComplete(error)
                else
                    args['app-id'] = result
                    method.apply(scope, [args, root, onComplete])
        else
            method.apply(scope, [args, root, onComplete])

