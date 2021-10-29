# mägic.ObsClient
Control OBS in Love2d via websockets api

# Requirements
- [Love2d](https://love2d.org) version used 11.3
- [OBS](https://obsproject.com) version used 27.0.1
- [obs-websocket](https://github.com/Palakis/obs-websocket/releases/tag/4.9.1) version used 4.9.1
- [lunajson](https://github.com/grafi-tt/lunajson)
- [love2d-lua-websocket](https://github.com/flaribbit/love2d-lua-websocket)


`lunajson`, `love2d-lua-websocket` (and `src/obsClient.lua`) must be included in your love projects `require path` (I prefer using submodules (see [mägic.ObsClient-demo](https://github.com/scawp/magic.ObsClient-demo) for usage) but you can also copying `src/obsClient.lua` from this project into yours)

 `OBS` must have the `obs-websocket` plugin installed, see [obs-websocket](https://github.com/Palakis/obs-websocket) for instructions.

 # Usage

 ```
 function love.load()
  obsClient = require('obsClient').new(host, port) -- defaults to localhost 4444
end

function love.update(dt)
  obsClient:update(dt)
end
````

## Watch for an event
 ```
  --obsClient:watchEvent(event_type<string>, func<function>)
  obsClient:watchEvent("SwitchScenes", function (data)
    print("Current Scene: " .. data["scene-name"])
  end)
 ```

 ## Send a basic request
 ```
   --obsClient:sendRequest(request_type<string>)
  obsClient:sendRequest("StartStreaming")
 ```

 ## Send a request with a callback on message received
 ```
  --obsClient:sendRequest(request_type<string>, func<function>)
  obsClient:sendRequest("StartStreaming", 
                        function(data)
                          if data["status"] == "ok" then
                            print("Stream is starting")
                          end
                        end)
 ```

  ## Send a request with parameters
 ```
  --obsClient:sendRequest(request_type<string>, params<table>)
  obsClient:sendRequest("SetCurrentScene", {["scene-name"] = "Scene One"})
 ```

  ## Send a complete request
 ```
  --[[obsClient:sendRequest(request_type<string>, 
                            retry<bool>, 
                            message_id<string>, 
                            params<table>, 
                            func<function>)
  ]]--
  obsClient:sendRequest("SetCurrentScene", 
                        true,
                        {["scene-name"] = "Scene One"},
                        function(data)
                          if data["status"] == "ok" then
                            print("Scene Switched")
                          end
                        end)
 ```
`request_type` must be the first parameter, the rest can be in any order


### When to use retry

set `retry` to `true` to add request to queue to be sent when connection is established, otherwise default `false` request is dropped

### When to use message_id

`message_id` will be sent to Obs and used for calling the `callback_func`, leaving `message_id` blank will auto generate a unique id, you can set your own if required. 

# Issues and Limitations

TODO

# See also

see [obs-websockets](https://github.com/Palakis/obs-websocket/blob/4.x-current/docs/generated/protocol.md) for list of `Events`, `Requests` and required parameters.


# Working Example

See [mägic.ObsClient-demo](https://github.com/scawp/magic.ObsClient-demo) for a working demo.

