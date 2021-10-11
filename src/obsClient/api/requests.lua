return {
  sendObsRequest = function(self, data)
    obsClient:sendObsRequest(data)
  end,
  StartRecording = function(self)
    self:sendObsRequest({["request-type"] = "StartRecording" })
   end,
  
  StopRecording = function(self)
    self:sendObsRequest({["request-type"] = "StopRecording" })
   end,

   GetVersion = function(self)
    self:sendObsRequest({["request-type"] = "GetVersion",
                         ["retry"] = true,
                         ["callback_func"] = "GetVersionCallback"})
   end,

  GetSceneList = function(self, params)
    local params = params or {}
    params["request-type"] = "GetSceneList"
    params["callback_func"] = params["callback_func"] or "GetSceneListCallBack"
    self:sendObsRequest(params)
   end,
  
  SetCurrentScene = function (self, scene_name)
    self:sendObsRequest({
      ["request-type"] = "SetCurrentScene",
      ["scene-name"] = scene_name
    })
  end
}