{DOMParser, XMLSerializer} = require 'xmldom'
fs = require 'fs'

module.exports = (data, inputFile, outputFile, mainFile, version, id, onComplete)->
    try
        parser = new DOMParser()
        dom = parser.parseFromString(data)
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

        console.info "Writing changes on file #{inputFile} to #{outputFile}"
        fs.writeFile outputFile, new XMLSerializer().serializeToString(doc), (error, result)->
            if error then onComplete(error)
            else
                onComplete(null, id)

    catch e
        console.error e.stack
        onComplete(e)