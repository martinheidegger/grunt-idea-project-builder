fs = require 'fs'
path = require 'path'
{pushToMember, getFlexHome, addRegularArguments, addDefinesSpecially, executeJar, deepExtend} = require './utils'

folderOf = (path) ->
    paths = path.split("/")
    paths.pop()
    return if paths.length > 0 then paths.join("/") else "."

clearPath = (path) ->
    parts = path.split("/")

    if parts[0] == "."
        parts.shift()

    result = []
    for part in parts
        if part == ".."
            result.pop()
        else
            result.push(part)
    return result.join("/")

relativeTo = (parent, path) ->
    path = clearPath(path)
    pathParts = path.split("/")
    parent = clearPath(parent)
    parentParts = parent.split("/")

    result = []
    for i in [0...parentParts.length]
        if parentParts[i] != pathParts[i]
            i++
            while i < parentParts.length
                pathParts.unshift("..")
                i++
    
    return pathParts.join("/")

removeNonExistingPaths = (target, parentPath, member) ->
    input = target[member]
    if input
        result = []
        for pth in input
            pth = path.resolve(parentPath, pth)
            if fs.existsSync(pth) then result.push(pth)
        target[member] = result

prepareFlashArgs = (args, root, flexHome) ->
    files = args.files
    if files
        for file in files
            pushToMember(args, "file-specs", file)
    delete args.files
    delete args["compiler.debug"]
    delete args["debug"]
    delete args["benchmark"]
    args["use-network"] = "true"

    removeNonExistingPaths(args, root, "compiler.library-path")
    removeNonExistingPaths(args, root, "compiler.include-libraries")
    removeNonExistingPaths(args, root, "compiler.external-library-path")
    removeNonExistingPaths(args, root, "runtime-shared-library-path")
    output = null
    if args.output
        output = args.output
        delete args["output"]
    if args.o
        output = args.o
        delete args["o"]
    args.output = path.resolve(root, output)

    if !args.define then args.define = {}

    delete args['omit-trace-statements']
    args['compiler.omit-trace-statements'] = "true"

    versions = [args['target-player'], "11.4", "11.1", "10.2", "10.1", "10"]
    for version, pos in versions
        playerglobal = "#{flexHome}/frameworks/libs/player/#{version}/playerglobal.swc"
        if fs.existsSync(playerglobal)
            pushToMember( args, "compiler.external-library-path", playerglobal)
            args['target-player'] = version
            break

    pushToMember(args, "compiler.library-path", "#{flexHome}/frameworks/libs/framework.swc")
    pushToMember(args, "compiler.library-path", "#{flexHome}/frameworks/libs/core.swc")
    pushToMember(args, "compiler.library-path", "#{flexHome}/frameworks/libs/osmf.swc")
    pushToMember(args, "compiler.library-path", "#{flexHome}/frameworks/libs/textLayout.swc")
    pushToMember(args, "compiler.library-path", "#{flexHome}/frameworks/libs/air/aircore.swc")
    pushToMember(args, "compiler.library-path", "#{flexHome}/frameworks/libs/air/airglobal.swc")

    return args

module.exports = (args, root, onComplete) ->
    try
        flexHome = getFlexHome(args)
        args = prepareFlashArgs(deepExtend(args, args.additionalArguments), root, flexHome)
        argList = ["+flexlib=\"#{flexHome}/frameworks\""]
        argList = addDefinesSpecially(args, argList)
        argList = addRegularArguments(args, argList, "=", "additionalArguments", "additionalOptions", "flexHome", "define")
        argList.push args.additionalOptions
        if args.additionalArguments
            argList = addDefinesSpecially(args.additionalArguments, argList)
            
        executeJar "#{flexHome}/lib/mxmlc.jar", argList.join(" "), root, onComplete
    catch e
        onComplete e
        return
