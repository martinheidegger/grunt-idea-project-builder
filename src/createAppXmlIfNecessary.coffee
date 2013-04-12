{utils: {adaptAppXmlFile, deepExtend}} = require 'flash-build-api'

module.exports = (data, root, version, air, target, onComplete)->
    if data.inputDescriptor && data.descriptor
        adaptAppXmlFile data.inputDescriptor, data.descriptor, data.mainFile, root, data.version, data["app-id"], (error, result)->
            if error then onComplete(error)
            else
                data['app-id'] = result

                if version then data.version = version

                data = deepExtend data, air
                data.target = target
                onComplete(null, data)
    else
        onComplete(null, data)

