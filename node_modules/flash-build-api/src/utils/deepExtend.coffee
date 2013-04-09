is_plain_obj = require './is_plain_obj'

deepExtend = (a, b)->
    target = {}
    for part in [a, b]
        for name, value of part
            nowValue = target[name]
            if nowValue == value
            else if Array.isArray(value) and Array.isArray(nowValue)
                target[name] = nowValue.concat(value)
            else if is_plain_obj(value) and is_plain_obj(nowValue)
                target[name] = deepExtend(nowValue, value)
            else if value?
                target[name] = value
    return target

module.exports = deepExtend