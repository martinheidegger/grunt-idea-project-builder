{getFlexHome, addRegularArguments, inQuotes, executeJar, addRegularArgument} = require './utils'
{exec} = require 'child_process'
fs = require 'fs'
path = require 'path'

getStorePass = (key)->
    if key?
        filePath = path.resolve(process.cwd(), ".storepass")
        if fs.existsSync filePath
            try
                data = JSON.parse(fs.readFileSync(filePath))
                return data[key]
            catch e
                console.warn(e)
    return null

getStoreType = (keystore)->    
    ext = path.extname(keystore)
    return (
        if ext == ".keystore" then "jks"
        else if ext == ".p12" or ext == ".pfx" then "pkcs12"
        else throw "No keystore type defined"
    )

module.exports = (args, root, onComplete)->
    flexHome = getFlexHome(args)

    argList = ["-package"]

    try
        argList.push("-target "+args.target)

        args.storetype ?= getStoreType(args.keystore)
        args.storepass ?= getStorePass(args.storekey)

        argList.push("-storetype "+args.storetype)
        argList.push addRegularArgument("keystore", args.keystore, " ")
        argList.push addRegularArgument("storepass", args.storepass, " ")

        addRegularArguments(args, argList, " ", "version", "extDirs", "app-id", "keystore", "storepass", "flexHome", "mainFile", "inputDescriptor", "target", "output", "storetype", "storekey", "paths", "package-file-name", "descriptor")
        argList.push(inQuotes(args.output))
        argList.push(inQuotes(args.descriptor))

        eFiles = []
        cFiles = []

        if args.paths? then for pathInfo in args.paths
            filePath = path.resolve(root, pathInfo['file-path'])
            try
                if args.target == 'ane' || fs.statSync(filePath).isDirectory()
                    cFiles.push(pathInfo)
                else
                    eFiles.push(pathInfo)
            catch e
                console.info "Warning: Tried to add non-existing file #{filePath}"
                #ignore missing files

        for pathInfo in eFiles
            argList.push("-e "+inQuotes(pathInfo['file-path'])+" "+inQuotes(pathInfo['path-in-package']))

        for pathInfo in cFiles
            argList.push("-C "+inQuotes(path.dirname(pathInfo['file-path']))+" "+inQuotes(path.basename(pathInfo['file-path'])))

        if args.extDirs
            for extdir in args.extDirs
                argList.push "-extdir"
                argList.push inQuotes(extdir)

    catch e
        onComplete(e)
        return

    executeJar "#{flexHome}/lib/adt.jar", argList.join(" "), root, onComplete