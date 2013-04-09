packageTargets = require './packageTargets'

module.exports = (target)->
    if packageTargets.android.indexOf(target) != -1
        return 'android'
    else if packageTargets.ios.indexOf(target) != -1
        return 'ios'