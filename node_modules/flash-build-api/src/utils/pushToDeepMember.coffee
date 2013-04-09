pushToMember = require './pushToMember'

module.exports = (target, member, value) ->
    dotIndex = member.indexOf(".")
    if dotIndex != -1
        childName = member.substring(0,dotIndex)
        member = member.substring(dotIndex+1)
        childNode = (target[childName] || target[childName] = {})
        pushToMember(childNode, member, value)
    else
        pushToMember(target, member, value)