# mägic.ObsClient
Control OBS via websockets api

# Requirements
- [Love2d](https://love2d.org) version used 11.3
- [OBS](https://obsproject.com) version used 27.0.1
- [obs-websocket](https://github.com/Palakis/obs-websocket/releases/tag/4.9.1) version used 4.9.1
- [lunajson](https://github.com/grafi-tt/lunajson)
- [love2d-lua-websocket](https://github.com/flaribbit/love2d-lua-websocket)


`lunajson`, `love2d-lua-websocket` (and `src/obsClient.lua`) must be included in your love projects `require path` (I prefer using submodules (see [mägic.ObsClient-demo](https://github.com/scawp/magic.ObsClient-demo) for usage) but you can also copying `src/obsClient.lua` from this project into yours)

 `OBS` must have the `obs-websocket` plugin installed, see [obs-websocket](https://github.com/Palakis/obs-websocket) for instructions.

 # Usage

## Watch for an event
 ```
  --obsClient:watchEvent(EVENT, FUNCTION)
  obsClient:watchEvent("SwitchScenes", function (data)
    lbl_current_scene.text = "Current Scene: " .. data["scene-name"]
  end)
 ```

 ## Send a request
 ```
  obsClient:sendObsRequest({
    ["request-type"] = "StartStreaming"
  })
  --TODO: change to this
  obsClient:sendRequest("StartStreaming", params)
```
see [obs-websockets](https://github.com/Palakis/obs-websocket/blob/4.x-current/docs/generated/protocol.md) for list of `Events` request-type`s and required parameters.

# Working Example

See [mägic.ObsClient-demo](https://github.com/scawp/magic.ObsClient-demo) for a working demo.
