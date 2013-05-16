fs = require 'fs'
path = require 'path'
async = require 'async'
glob = require 'glob'
{utils: {parseXml, resolveSymlink, deepExtend}} = require('flash-build-api')

modules_xml = (data)->
    modules = []
    data.modules = modules
    return { project: { component: { modules: { module: (properties)->
        modules.push properties.filepath
    } } } }

named_dependency_xml = (data)->
    data.sourcePaths = []
    data.libPaths = []
    return {
        component:
            library:
                CLASSES:
                    root: {}
                JAVADOC: {}
                SOURCES:
                    root: (properties)->
                        data.sourcePaths.push(properties.url)
                jarDirectory: (properties)->
                    data.libPaths.push(properties.url)
    }

flashCompiler_xml = (data)->
    return {
        project:
            component: (properties)->
                if properties.name == "FlexIdeProjectLevelCompilerOptionsHolder"
                    return {
                        "compiler-options": 
                            map: null
                            option: (properties)->
                                data[properties.name] = properties.value
                    }
                else
                    return null
    }

module_xml = (data)->
    swf                                  = {}
    swf.modules         = swfModules     = {}
    data.swf            = swf
    data.android        = androidModules = {}
    data.ios            = iosModules     = {}
    data.air            = airModules     = {}
    data["test-path"]   = testPaths      = []
    data["source-path"] = sourcePaths    = []
    data.libraryItems   = libraryItems   = []
    return {
        module: {
            component: (properties) ->
                if properties.name == "NewModuleRootManager"
                    return {
                        "exclude-output": null
                        content: {
                            sourceFolder: (properties)->
                                if properties.isTestSource == "true"
                                    testPaths.push(properties.url)
                                else
                                    sourcePaths.push(properties.url)
                            excludeFolder: null
                        }
                        orderEntry: (properties)->
                            if properties.type == "module-library"
                                return {
                                    library: (properties)->
                                        if properties.type == "flex"
                                            libraryItems.push(libraryItem = {})
                                            return  {
                                                properties: (properties)->
                                                    libraryItem.id = properties.id
                                                CLASSES: {
                                                    root: (properties)->
                                                        libraryItem.url = properties.url
                                                }
                                                JAVADOC: null
                                                SOURCES: null
                                                jarDirectory: (properties)->
                                                    libraryItems.many = true
                                            }
                                        else
                                            return null
                                }
                            else
                                return null
                    }
                else if properties.name == "FlexBuildConfigurationManager"
                    return {
                        "compiler-options": {
                            option: (properties)->
                                if properties.name == "additionalOptions"
                                    return data.additionalOptions = properties.value
                                return null
                        }
                        configurations: {
                            configuration: (properties) ->
                                if properties.name?
                                    moduleName = properties.name
                                    linkedDependencies = []
                                    namedDependencies = []
                                    module = {
                                        output: properties["output-folder"]+"/"+properties["output-file"]
                                        classes: [properties["main-class"]]
                                        linkedDependencies: linkedDependencies
                                        namedDependencies: namedDependencies
                                        additionalOptions: ''
                                    }
                                    swfModules[moduleName] = module

                                    createPackaging = (modules) ->
                                        return (properties)->
                                            if (!properties.hasOwnProperty("enabled") || properties.enabled == "true") && properties.hasOwnProperty('package-file-name')
                                                if properties['use-generated-descriptor'] == "true"
                                                    throw "Can not autogenerated a -app.xml file!"
                                                
                                                paths = []
                                                packaging = {
                                                    descriptor: properties['custom-descriptor-path']
                                                    'package-file-name': properties['package-file-name']
                                                    paths: paths
                                                }
                                                modules[moduleName] = packaging
                                                return {
                                                    'files-to-package': {
                                                        'FilePathAndPathInPackage': (properties)->
                                                            paths.push(properties)
                                                    }
                                                    AirSigningOptions: (properties)->
                                                        if packaging['use-temp-certificate']
                                                            throw "Can not use a temporary certificate!"
                                                        packaging.key = properties['keystore-path']
                                                        packaging['provisioning-profile'] = properties['provisioning-profile-path']
                                                        return null
                                                }
                                            else
                                                return null
                                    return {
                                        "compiler-options": {
                                            map: null
                                            option: (properties)->
                                                if properties.name == "additionalOptions"
                                                    return module.additionalOptions += properties.value
                                                return null
                                        }
                                        "packaging-android": createPackaging(androidModules)
                                        "packaging-ios": createPackaging(iosModules)
                                        "packaging-air-desktop": createPackaging(airModules)
                                        dependencies: (properties)->
                                            module["target-player"] = properties["target-player"]
                                            return {
                                                entries: {
                                                entry: (properties) ->
                                                    if properties['library-level']? && properties['library-level'] != 'project'
                                                        throw new Error("No idea what to do with a library-level that isn't 'project'")
                                                    library = {
                                                        id: properties["library-id"]
                                                        name: properties["library-name"]
                                                    }
                                                    if library.id?
                                                        linkedDependencies.push(library)
                                                    else if library.name?
                                                        namedDependencies.push(library)    
                                                    return {
                                                        dependency: (properties)->
                                                            library.linkage = properties.linkage
                                                    }
                                                }
                                                sdk: null
                                            }
                                    }
                                else
                                    return null
                        }
                    }
                else
                    return null
        }
    }

_replaceModule = (targetPath, dir)->
    if targetPath?
        p = targetPath.replace(/\$MODULE_DIR\$/, dir)
        return (path.relative(dir, resolveSymlink(p)))
    else
        return null

_replaceProject = (targetPath, dir)->
    if targetPath?
        return targetPath.replace(/^file\:\/\//, "").replace(/\$PROJECT_DIR\$/, dir)
    else
        return null

_loadNamedDependency = (dependency, namedDependencyMap, ideaRoot)->
    return (onComplete)->
        dependencyPath = path.resolve(ideaRoot, "libraries/#{dependency}.xml")
        parseXml dependencyPath, named_dependency_xml, (error, result)->
            namedDependencyMap[dependency] = result.data
            onComplete(error, result)

_loadModule = (allModules, module, moduleDir, projectDir, ideaRoot, flexHome, globalOptions) ->
    return (onComplete)->
        parseXml module, module_xml, (error, moduleResult)->
            if error then onComplete(error)
            else
                namedDependencies = _getAllNamedDependencies(moduleResult.data.swf.modules)
                loadAllNamedDependencies = []
                namedDependencyMap = {}
                for dependency in namedDependencies
                    loadAllNamedDependencies.push _loadNamedDependency(dependency, namedDependencyMap, ideaRoot)

                async.series loadAllNamedDependencies, (error, tempResult)->
                    if error then onComplete(error)
                    else
                        try
                            namedDependencyMap = _resolveNamedDependencies(namedDependencyMap, projectDir)
                            _constructData(moduleResult, allModules, moduleDir, flexHome, namedDependencyMap, globalOptions, onComplete)
                        catch e
                            onComplete(e)

_getAllNamedDependencies = (modules)->
    namedMap = {}
    namedList = []
    for name, args of modules
        for namedDependency in args.namedDependencies
            name = namedDependency.name
            if !namedMap[name]?
                namedMap[name] = true
                namedList.push(name)
    return namedList

_resolveNamedDependencies = (namedDependencyMap, projectDir)->
    for name, namedDependency of namedDependencyMap
        namedDependency.sourcePaths = (
            for sourcePath in namedDependency.sourcePaths
                _replaceProject(sourcePath, projectDir)
        )

        namedDependency.libPaths    =  (
            for libPath in namedDependency.libPaths
                _replaceProject(libPath, projectDir)     
        )

        swcs = []
        for libPath in namedDependency.libPaths
            swcs = swcs.concat glob.sync("#{libPath}/*.swc")
            swcs = swcs.concat glob.sync("#{libPath}/*.ane")
        namedDependency.swcs = swcs
    return namedDependencyMap

_searchClassFile = (sourcePath, clazz, moduleDir, ending)->
    classFileRelative = sourcePath+"/"+clazz+".#{ending}"
    classFile = path.resolve(moduleDir, classFileRelative)
    if fs.existsSync(classFile)
        return classFileRelative

_searchClass = (clazz, moduleDir, paths)->
    for pth in paths
        filePath = _searchClassFile(pth, clazz, moduleDir, "as") ||
            _searchClassFile(pth, clazz, moduleDir, "mxml")
        if filePath
            return filePath
    return null

_replaceFiles = (entries, moduleDir) ->
    result = []
    for entry in entries
        result.push(
            _replaceModule(
                entry.replace(/^file\:\/\//, ""),
                moduleDir
            )
        )
    return result

_constructData = (result, allModules, moduleDir, flexHome, namedDependencyMap, globalOptions, onComplete)->

    try
        libraryItems = {}

        for libraryItem in result.data.libraryItems
            url = libraryItem.url
            libraryItems[libraryItem.id] = _replaceModule(
                url.substr(0, url.length-2).replace(/^jar\:\/\//, ""),
                moduleDir
            )


        sourcePaths = _replaceFiles(result.data['source-path'], moduleDir)
        testPaths   = _replaceFiles(result.data['test-path'], moduleDir)

        swfModules         = allModules.swf         ?= {}
        testSwfModules     = allModules.testSwf     ?= {}
        allModules.ios         ?= {}
        allModules.testIos     ?= {}
        allModules.android     ?= {}
        allModules.testAndroid ?= {}
        allModules.air         ?= {}
        allModules.testAir     ?= {}

        hasTests = result.data["test-path"].length > 0

        for name, args of result.data.swf.modules
            libraryPaths = []
            externalLibraryPaths = []
            moduleSourcePaths = sourcePaths.concat()

            args.output = _replaceModule(args.output, moduleDir)

            files = []
            for clazz in args.classes
                file = _searchClass(clazz, moduleDir, moduleSourcePaths)
                if file then files.push(file)
            
            for linkedDependency in args.linkedDependencies
                libraryItem = libraryItems[linkedDependency.id]
                libraryPaths.push libraryItem

            for namedDependency in args.namedDependencies
                library = namedDependencyMap[namedDependency.name]
                moduleSourcePaths = moduleSourcePaths.concat(library.sourcePaths)
                libraryPaths = libraryPaths.concat(library.swcs)

            for i in [libraryPaths.length-1..0]
                item = libraryPaths[i]
                if /\.ane$/.test(item)
                    libraryPaths.splice(i, 1)
                    externalLibraryPaths.push(item)

            args["source-path"] = moduleSourcePaths
            args.files = files
            args["static-link-runtime-shared-libraries"] = "true"
            if result.data.additionalOptions
                args.additionalOptions ?= ""
                args.additionalOptions += " "+result.data.additionalOptions
            args.inheritedOptions = globalOptions.additionalOptions
            

            delete args['classes']
            delete args['libraryItems']
            delete args['libraryPaths']
            delete args["linkedDependencies"]
            delete args['namedDependencies']
            if !args.flexHome then args.flexHome = flexHome

            if libraryPaths.length > 0
                args["compiler.library-path"] = libraryPaths

            if externalLibraryPaths.length > 0
                args["compiler.external-library-path"] = externalLibraryPaths

            swfModules[name] = {
                path: moduleDir
                args: args
            }

            if hasTests
                moduleSourcePaths = moduleSourcePaths.concat(testPaths)
                file = _searchClass("TestMain", moduleDir, moduleSourcePaths)
                if file
                    args = deepExtend args, {
                        "source-path": moduleSourcePaths
                    }
                    args.files = [file]
                    ext = path.extname(args.output)
                    args.output = args.output.substr(0, args.output.length-ext.length)+".test"+ext
                    testSwfModules[name] = {
                        path: moduleDir
                        args: args
                    }
        try
            _createAllAirModules allModules, result.data, args, moduleDir, flexHome, false
            if hasTests
                _createAllAirModules allModules, result.data, args, moduleDir, flexHome, true
        catch e
            onComplete(e.stack)
            return

        onComplete(null, allModules)
    catch e
        console.error e.stack
        throw e


_createAllAirModules = (allModules, allModuleArgs, args, moduleDir, flexHome, tests)->
    if tests 
        swfModules     = allModules.testSwf
        iosModules     = allModules.testIos
        androidModules = allModules.testAndroid
        airModules     = allModules.testAir
    else
        swfModules     = allModules.swf
        iosModules     = allModules.ios
        androidModules = allModules.android
        airModules     = allModules.air

    _createAirModules iosModules,     allModuleArgs.ios,     args, moduleDir, swfModules, flexHome
    _createAirModules androidModules, allModuleArgs.android, args, moduleDir, swfModules, flexHome
    _createAirModules airModules,     allModuleArgs.air,     args, moduleDir, swfModules, flexHome

_createAirModules = (modules, moduleArgs, args, moduleDir, swfModules, flexHome) ->
    for name, args of moduleArgs
        modules[name] = _createAirModule(args, moduleDir, swfModules[name], flexHome)

removeUndefined = (obj)->
    for name, val of obj
        if !val
            delete obj[name]
    return obj

_createAirModule = (args, moduleDir, swfModule, flexHome)->
    outputFile = swfModule.args.output
    outDir = path.dirname(outputFile)
    paths = _createAirPackagePaths(args, moduleDir, outputFile)
    return {
        path: moduleDir
        args: removeUndefined 
            flexHome:               flexHome
            "package-file-name":    args['package-file-name']
            mainFile:               path.basename(outputFile)
            output:                 path.relative(".", path.resolve(outDir, path.basename(outputFile, ".swf")))
            descriptor:             path.relative(".", path.resolve(outDir, path.basename(outputFile, ".swf")+"-app.xml"))
            keystore:               _replaceModule(args.key, moduleDir)
            "provisioning-profile": _replaceModule(args["provisioning-profile"], moduleDir)
            inputDescriptor:        _replaceModule(args.descriptor, moduleDir)
            paths:                  paths
            extDirs:                _getExtDirs(swfModule.args['compiler.library-path'], paths)
    }

_getExtDirs = (libraryPaths, paths)->
    aneFolders = _getAneContainingFolders(libraryPaths)
    aneFolders = _getAneContainingFolders(pkgPath['file-path'] for pkgPath in paths, aneFolders)
    return aneFolders

_getAneContainingFolders = (paths, aneFolders=[]) ->
    if paths
        for subPath in paths 
            dir = path.dirname(subPath)
            if /\.ane$/.test(subPath) and aneFolders.indexOf(dir) == -1
                aneFolders.push(dir)
    return aneFolders


_createAirPackagePaths = (args, moduleDir, outputFile)->
    paths = []

    for pathInfo in args.paths
        filePath = _replaceModule(pathInfo['file-path'], moduleDir)
        
        paths.push({
            'file-path': filePath
            'path-in-package': pathInfo['path-in-package']
        })

    paths.push({
        'file-path': outputFile
        'path-in-package': path.basename(outputFile)
    })

    return paths

module.exports = (folder, flexHome, onComplete)->
    root = path.resolve(folder, ".")
    ideaRoot = path.resolve(root, ".idea")
    fs.exists ideaRoot, (exists)->
        if !exists 
            onComplete("Folder does not contain an idea project")
        else 
            fs.stat ideaRoot, (error, stat)->
                if error
                    onComplete("Error while trying to figure out what sort of folder that is:"+error)
                else if stat && stat.isDirectory
                    parseXml path.resolve(ideaRoot, "modules.xml"), modules_xml, (error, result)->
                        if error
                            onComplete(error, null)
                        else
                            parseXml path.resolve(ideaRoot, "flexCompiler.xml"), flashCompiler_xml, (error, globalOptions)->
                                globalOptions ?= {data:{}}

                                allModules = {}
                                moduleLoaders = []

                                for module in result.data.modules
                                    module = _replaceProject(module, root)
                                    moduleRoot = path.resolve(root, path.dirname(module))
                                    moduleLoaders.push _loadModule(allModules, module, moduleRoot, root, ideaRoot, flexHome, globalOptions.data)
                                
                                async.parallel moduleLoaders, (error, result)->
                                    onComplete(error, allModules)
                else
                    onComplete("Folder does not contain an idea project")