module.exports = (target, member, value) ->
    (target[member] || target[member] = []).push(value)