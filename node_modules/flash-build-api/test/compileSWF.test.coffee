compileSWF = require "../lib/compileSWF"
assert = require 'assert'

describe "Trying to compile a swf", ->
    it "should not work without a flex sdk", (next)->
        delete process.env["FLEX_HOME"]
        compileSWF {}, ".", (error, result) ->
            assert.notEqual(error, null)
            next()

    it "should not work with a broken flex sdk", (next)->
        process.env["FLEX_HOME"] = "/"
        compileSWF {}, ".", (error, result)->
            assert.notEqual(error, null)
            next()