local obs_client = require("websocket").new("localhost", 6666)
--local newdecoder = require 'decoder'

obs_client.init = function(self)
  newdecoder = require 'decoder'
  self.decode = newdecoder()

  newencoder = require 'encoder'
  self.encode = newencoder()
  --self:load_apis()

  self.connected = false
end

obs_client.load_apis = function()
  --obs_client.scenes = require "src.api.requests.scenes"
end

--update already in the require, uncomment if needs extending
--obs_client.update = function(self, dt)
  --self:update()
--end

obs_client.onopen = function(self)
  self.connected = true
  self:log("Connection to OBS opened")
end

--obs_client.SwitchScenes = function(self, data)
--  self:log("Running SwitchScenes \"" .. data["scene-name"] .. "\"", "Success")
--end

obs_client.onmessage = function(self, msg)
  self:log(msg, "Event")

  local err = nil
  local success, data = pcall(self.decode, msg)
  if not success then
    self:log("JSON Decoding Error " .. data, "Invalid Data")
  else
    success, err = pcall(self[data["update-type"]], self, data)
    if not success then
      self:log("Ignoring " .. data["update-type"] .. " " .. err, "Unhandled Event")
    end
  end
end

obs_client.onclose = function(self)
  self.connected = false
  self:log("Connection to OBS closed")
end

obs_client.debug = {
  init_time = os.time()
}

obs_client.log = function(self, data, type)
  type = type or "obs_client"
  print(data)
  love.filesystem.append("obsClient-" .. self.debug.init_time .. ".log", 
                         "[".. os.time() .. "] " .. type .. ": " .. tostring(data) .. "\r\n")
end

return obs_client
