fs = require "fs"
path = require 'path'

cache = {}

module.exports = (path)->
    try
        target = cache[path]
        if !target
            stat = fs.lstatSync(path)
            if stat.isSymbolicLink()
                target = fs.readlinkSync(path)
            else
                target = path
            cache[path] = target

        return target
    catch e
        return path
    