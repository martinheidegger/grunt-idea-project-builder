{exec} = require 'child_process'

module.exports = (jar, args, cwd, onComplete) ->
    start = Date.now()
    cmd = "java -Xmx384m -Djava.awt.headless=true -Dsun.io.useCanonCaches=false -jar \"#{jar}\" #{args}"
    console.info cmd
    return exec cmd, {cwd: cwd}, (error, stdout, stderr) ->
        if onComplete
            result = {
                cmd
                error
                stderr
                stdout
                path: cwd
                duration: Date.now()-start
            }
            if error
                onComplete(result, null)
            else
                onComplete(null, result)
        else
            if error
                console.error stderr
            else
                console.info stdout