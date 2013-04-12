net = require 'net'
sys = require 'sys'
{DOMParser, XMLSerializer} = require('xmldom')
parser = new DOMParser()
serializer = new XMLSerializer()

DOMAIN_POLICY =  "<?xml version=\"1.0\"?>"+
    "<cross-domain-policy xmlns=\"http://localhost\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.adobe.com/xml/schemas PolicyFileSocket.xsd\">" +
    "<allow-access-from domain=\"*\" to-ports=\"{0}\" />" +
    "</cross-domain-policy>"

END_OF_TEST_ACK = "<endOfTestRunAck/>"
END_OF_TEST_RUN = "<endOfTestRun/>"
POLICY_PROFILE = "<policy-file-request/>"
START_OF_TEST_RUN_ACK = "<startOfTestRunAck/>"

startServer = (host, port, waitForPolicyFile, timeout, onComplete)->

    allData = []
    _stream = null

    server = net.createServer (stream)->
        _stream = stream
        stream.setEncoding("utf8")

        send = (msg) ->
            stream.write("#{msg}\u0000")
        classes = {}
        hasError = false

        stream.on "connect", -> 
            if !waitForPolicyFile
                send(START_OF_TEST_RUN_ACK)

        stream.on "data", (data) ->
            clearTimeout waitTimeout
            data = data.substr(0, data.length-1)

            if data == END_OF_TEST_RUN
                end(if hasError then "Error during execution" else null)
            else if data == POLICY_PROFILE
                send(DOMAIN_POLICY)
                send(START_OF_TEST_RUN_ACK)
            else
                packet = parser.parseFromString(data).documentElement

                className = packet.getAttribute("classname")
                method = packet.getAttribute("name")
                status = packet.getAttribute("status")

                if status == "error"
                    error = serializer.serializeToString(packet.getElementsByTagName("error")[0])
                else if status == "failure"
                    error = serializer.serializeToString(packet.getElementsByTagName("failure")[0])
                else
                    error = null

                clazz = classes[className]
                if !clazz
                    allData.push(clazz = [])
                    classes[className] = clazz

                clazz.push {
                    method
                    status
                    error
                }

                console.info "#{className}.#{method} ... #{status}"

                if error
                    hasError = true

        stream.on "end", -> end "Server prematurely closed"
    listening = true
    end = (error)->
        if listening
            listening = false
            try
                _stream.destroy()
            catch e
                # ignore
            try
                server.close -> onComplete(error, allData)
            catch e
                onComplete(error, allData)
    try
        server.listen(port, host)
        waitTimeout = setTimeout ->
                end("Unit tests havn't started after #{timeout}ms")
            , timeout
    catch e
        listening = false
        process.nextTick -> onComplete(e)
    return {
        isListening: -> return listening
        endWithError: (error) ->
            if listening
                hasError = true
                end(error)
    }


module.exports = (startCommand, onComplete, timeout=4000, waitForPolicyFile=false, host='127.0.0.1', port=1024)->
    server = startServer host, port, waitForPolicyFile, timeout, (error, result)->
        try
            if swfRunning then swf.kill()
        catch e
            # eat error
        onComplete(error, result)

    swfRunning = true
    swf = startCommand (error, result)->
        swfRunning = false
        server.endWithError(result || "No unit test was run...")
    swf.on "exit", ->
        swfRunning = false