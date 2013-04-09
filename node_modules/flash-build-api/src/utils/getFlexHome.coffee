module.exports = (args)->
    flexHome = args.flexHome || process.env.FLEX_HOME
    try
        if !flexHome then throw new Error("Set the environment variable 'FLEX_HOME' to a valid flex sdk")
    catch e
        throw e
    
    return flexHome