'use strict';
module.exports = function(onComplete) {
    var exec = require("child_process").exec;
    exec("node_modules/coffee-script/bin/coffee -c -l -b -o lib src", function(error, stdout, stderr) {
        if(error) {
            console.info(stdout)
            console.error(stderr)
            console.info("Stopping execution due to error")
        } else {
            console.info(stdout)
            console.info(stderr)
            onComplete && onComplete()
        }
    });
}