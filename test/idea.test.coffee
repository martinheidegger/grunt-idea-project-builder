path = require 'path'
fs = require 'fs'
assert = require 'assert'
tasks = require '../lib'

wrap = (next, handler) ->
    return ->
        try 
            result = handler.apply(null, arguments)
            if typeof result == "function"
                result(next)
            else
                next()
        catch e
            console.error e
            next(e)

describe "reading a project", ->
    @timeout(15000);
    ###
    it "should finish for empty projects", (next)->
        parseIdeaProject ".", (error, result)->
            next()

    it "should finish with an error for empty projects", (next)->
        parseIdeaProject ".", wrap next, (error, result)->
            assert.equal("Folder does not contain an idea project", error)
            assert.equal(result, undefined)

    it "should show simple idea project", (next)->
        parseIdeaProject "test/ideaFolderProject", wrap next, (error, result)->
            assert.deepEqual({
                ideaFolderProject: {
                    path: path.resolve('test/ideaFolderProject')
                    args: {
                        "static-link-runtime-shared-libraries": true
                        files: ['src/IdeaFolderProject.as']
                        'output': 'out/production/ideaFolderProject/IdeaFolderProject.swf'
                        'target-player': '11.4'
                        additionalOptions: ''
                        'source-path': ['src']
                    }
                }
            }, result.swf)
            return (next)->
                data = result.swf.ideaFolderProject
                compileFlash data.args, data.path, wrap next, (error, result)->
                    ""

    it "should list linked dependencies", (next)->
        parseIdeaProject "test/ideaFolderLinkedProject", wrap next, (error, result)->
            assert.deepEqual({
                ideaFolderLinkedProject: {
                    path: path.resolve('test/ideaFolderLinkedProject')
                    args: {
                        "static-link-runtime-shared-libraries": true
                        files: ['src/IdeaFolderLinkedProject.as']
                        'target-player': '11.4'
                        'output': 'out/production/ideaFolderLinkedProject/IdeaFolderLinkedProject.swf'
                        additionalOptions: ''
                        'source-path': ['src']
                        'compiler.library-path':['lib/as3commons-logging-2.7.swc']
                    }
                }
            }, result.swf)
            return (next)->
                data = result.swf.ideaFolderLinkedProject
                compileFlash data.args, data.path, wrap next, (error, result)->
                    ""
                    

    it "should add compiler options", (next)->
        parseIdeaProject "test/ideaFolderCOProject", wrap next, (error, result)->
            assert.deepEqual({
                ideaFolderCOProject: {
                    path: path.resolve('test/ideaFolderCOProject'),
                    args: {
                        "static-link-runtime-shared-libraries": true
                        files: ['src/IdeaFolderCOProject.as']
                        'target-player': '11.4'
                        'output': 'out/production/ideaFolderCOProject/IdeaFolderCOProject.swf'
                        additionalOptions: '-define+=CONFIG::debug,true -define+=CONFIG::release,false -define+=CONFIG::mobile,false -define+=CONFIG::ios,false -define+=CONFIG::android,false -define+=CONFIG::desktop,true'
                        'source-path': ['src']   
                    }
                }
            }, result.swf)
            assert.deepEqual([], result.air)
            return (next)->
                data = result.swf.ideaFolderCOProject
                compileFlash data.args, data.path, wrap next, (error, result)->
                    ""
    ###
    it "should work with air projects", (next)->
        flexHome = "/Users/heideggermartin/air_sdk_3.6"
        tasks.parseProject "test/ideaAirAndroidProject", flexHome, wrap next, (error, result)->
            assert.equal(null, error)
            swf = result.swf.ideaAirAndroidProject
            android = result.android.ideaAirAndroidProject

            assert.equal(path.resolve('test/ideaAirAndroidProject'), swf.path)
            assert.deepEqual({
                    "static-link-runtime-shared-libraries": 'true'
                    files: ['src/IdeaAirAndroidProject.as']
                    'target-player': '11.4'
                    flexHome: flexHome
                    'output': 'out/production/ideaAirAndroidProject/IdeaAirAndroidProject.swf'
                    'source-path': ['src']
                    additionalOptions: ''
                }, swf.args)

            assert.equal(path.resolve('test/ideaAirAndroidProject'), android.path)
            assert.deepEqual({
                    keystore: 'test.p12'
                    descriptor: 'out/production/ideaAirAndroidProject/IdeaAirAndroidProject-app.xml'
                    inputDescriptor: 'IdeaAirAndroidProject-app.xml'
                    mainFile: 'IdeaAirAndroidProject.swf'
                    flexHome: flexHome
                    'package-file-name': 'IdeaAirAndroidProject'
                    output: 'out/production/ideaAirAndroidProject/IdeaAirAndroidProject'
                    paths: [
                        {'file-path': 'data/temp',    'path-in-package': 'temp'}
                        {'file-path': 'data/test',    'path-in-package': 'test'}
                        {'file-path': 'data/subtest', 'path-in-package': 'subtest'}
                        {'file-path': 'out/production/ideaAirAndroidProject/IdeaAirAndroidProject.swf', 'path-in-package': 'IdeaAirAndroidProject.swf'}
                    ],
                    extDirs: []
                }, android.args)
            
            return (next)->
                tasks.compileSWF swf.args, swf.path, wrap next, (error, result)->
                    if error then throw error
                    return (next)->
                        android.args.storepass = "test"
                        android.args.target = "apk"
                        tasks.packageReinstallLaunchAir android.args, android.path, wrap next, (error, result)->
                            if error then throw error
