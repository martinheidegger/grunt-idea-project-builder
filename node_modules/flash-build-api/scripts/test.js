#!/usr/bin/env node
require("./common")(function(){
    var exec = require("child_process").exec;
    exec("node_modules/mocha/bin/mocha -r should -R dot -t 180000 --compilers coffee:coffee-script test/*.test.coffee", function(error, stdout, stderr) {
        if(error) {
            console.info(stdout)
            console.error(stderr)
            console.info("Stopping execution due to error")
        } else {
            console.info(stdout)
            console.info(stderr)
        }
    });
});
