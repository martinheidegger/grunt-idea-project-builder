grunt = require 'grunt'
async = require 'async'
{deepExtend, packageTargets} = require('flash-build-api').utils
idea = require '../lib'

_compile = (project, module, target, data)->
    return (onComplete)->
        extra = {}
        if data.version then extra["CONFIG::version"] = data.version
        additional = deepExtend({"define": extra}, data.swf)
        swf = deepExtend project.swf[module], {
            args:
                additionalArguments: additional
        }

        nextStep = (result)->
            if target == "swf" then onComplete(null, result)
            else if packageTargets.all.indexOf(target) != -1
                if packageTargets.android.indexOf(target) != -1
                    moduleRoot = project.android
                else if packageTargets.ios.indexOf(target) != -1
                    moduleRoot = project.ios
                else 
                    onComplete()
                    return

                airModule = moduleRoot[module]
                if !airModule
                    available = (name for name, data of moduleRoot)
                    onComplete(new Error("Module '#{module}' is not available for target '#{target}', available targets: #{available}"))
                else
                    airModule = deepExtend({}, airModule)

                    if data.version then airModule.args.version = data.version

                    airModule = deepExtend deepExtend(airModule, {
                        args:
                            target: target
                     }), {
                        args: data.air
                    }

                    method = (
                        if data.package || data.package == undefined
                            if data.install?
                                if data.launch? then idea.packageReinstallLaunchAir
                                else                 idea.packageReinstallAir
                            else
                                if data.launch? then null #todo: need a packageLaunchAir command
                                else                 idea.packageAir
                        else
                            if data.install?
                                if data.launch? then idea.reinstallLaunchAir
                                else                 idea.reinstallAir
                            else
                                if data.launch? then idea.launchAir
                                else                 null
                    )

                    if method
                        method.apply idea, [airModule.args, airModule.path, onComplete]
                    else
                        onComplete(null, result)
            else
                onComplete("Don't know what to do with a '#{target}'-target please use: swf,"+packageTargets.all.join(","))

        if data.compile || !data.compile?
            idea.compileSWF swf.args, swf.path, (error, result)->
                if error then onComplete(error)
                else
                    nextStep(result)
        else
            nextStep(null)

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
                compileStatements = (_compile(project, module, compileTarget, compileData) for compileTarget, compileData of compile)
                async.series compileStatements, finish 
            else
                grunt.log.warn("No valid Module specified!")
                finish()
        