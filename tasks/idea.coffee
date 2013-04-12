grunt = require 'grunt'
async = require 'async'
flash = require 'flash-build-api'
idea = require '../lib'
{deepExtend, packageTargets} = flash.utils

_doCompile = (swf, data, onComplete)->
    extra = {}
    if data.version then extra["CONFIG::version"] = data.version
    additional = deepExtend({"define": extra}, data.swf)
    compileActive = data.compile || !data.compile?
    swf = deepExtend swf, {
        args:
            additionalArguments: additional
    }
    if compileActive
        flash.compileSWF swf.args, swf.path, onComplete
    else
        onComplete()

_oneTask = (project, module, target, data)->
    return (onComplete)->
        actions = []
        swf = deepExtend {}, project.swf[module]
        testSwf = deepExtend {}, project.testSwf?[module]

        if data.compile || !data.compile?
            if data.test
                if testSwf
                    actions.push (onComplete) ->
                        grunt.log.writeln("Compiling #{module} test swf")
                        _doCompile testSwf, data, onComplete
                else
                    onComplete("#{module} does not have test code but asks for executing unit tests")
                    return

            actions.push (onComplete) ->
                if swf
                    grunt.log.writeln("Compiling #{module} regular swf")
                    _doCompile swf, data, onComplete
                else
                    onComplete("Woops, trying to compile unexisting project #{module}")

        if target == "swf" then # ignore
        else if packageTargets.all.indexOf(target) != -1
            if packageTargets.android.indexOf(target) != -1
                moduleRoot = project.android
                testModuleRoot = project.testAndroid
            else if packageTargets.ios.indexOf(target) != -1
                moduleRoot = project.ios
                testModuleRoot = project.testIos
            else 
                moduleRoot = project.air
                testModuleRoot = project.testAir

            airModule = deepExtend {}, moduleRoot[module]
            if !airModule
                available = (name for name, data of moduleRoot)
                onComplete(new Error("Module '#{module}' is not available for target '#{target}', available targets: #{available}"))
                return
            else
                actions.unshift (onComplete) ->
                    grunt.log.writeln "Making sure that a required app.xml is available..."
                    idea.createAppXmlIfNecessary airModule.args, root, data.version, data.air, target, (error, result)->
                        if error then onComplete(error)
                        else
                            airModule.args = result
                            onComplete(null, "xml created")

                if testSwf && data.test
                    testAirModule = deepExtend {}, testModuleRoot[module]
                    if !testAirModule
                        onComplete(new Error("Module '#{module}' can not be tested for target '#{target}'"))
                        return

                    actions.splice 2, 0, (onComplete) ->
                        flash.runAirUnitTest testAirModule.args, testAirModule.path, (error, result)->
                            if error
                                for part in result
                                    for entry in part when entry.error
                                        grunt.log.error entry.error
                                onComplete(error)
                            else
                                onComplete()
                    
                    actions.unshift (onComplete) ->
                        grunt.log.writeln "Making sure that a required test-app.xml is available..."
                        idea.createAppXmlIfNecessary testAirModule.args, root, data.version, data.air, target, (error, result)->
                            if error then onComplete(error)
                            else 
                                testAirModule.args = result
                                onComplete()

                if data.package || data.package == undefined
                    actions.push (onComplete) ->
                        grunt.log.writeln "Packaging Air..."
                        flash.packageAir(airModule.args, airModule.path, onComplete)
                if data.install
                    actions.push (onComplete) ->
                        grunt.log.writeln "Reinstalling Air..."
                        flash.reinstallAir(airModule.args, airModule.path, onComplete)
                if data.launch
                    actions.push (onComplete) -> 
                        grunt.log.writeln "Launching Air..."
                        flash.launchAir(airModule.args, airModule.path, onComplete)
        else
            onComplete("Don't know what to do with a '#{target}'-target please use: swf,"+packageTargets.all.join(","))
            return

        async.series actions, onComplete

validateModule = (module, project)->
    if !module
        for moduleName, moduleData of project.swf
            return moduleName
    else if !project.swf[module]
        return null
    return module

grunt.registerMultiTask 'idea', 'Allows compilation of idea projects.', ->
    finish = (error)->
        if !error then onComplete()
        else
            console.log(error)
            onComplete(false)

    options = @options()
    onComplete = @async()
    module = @data.module
    compile = @data.compile

    idea.parseProject @data.path, options.flexHome, (error, project)->
        if error then finish(error)
        else
            module = validateModule(module, project)
            if module
                compileStatements = []
                for compileTarget, compileData of compile
                     compileStatements.push _oneTask(project, module, compileTarget, compileData)
                async.series compileStatements, finish 
            else
                finish "No valid Module specified! Available modules: " + (name for name, swf of project.swf).join(", ")