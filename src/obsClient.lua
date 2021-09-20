local obs_client = require("websocket").new("localhost", 6666)

obs_client.init = function(self)
  self.decode = require('decoder')
  self.encode = require('encoder')
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

obs_client.onmessage = function(self, msg)
  self:log("--------------")
  self:log(msg, "Event")


  local json_msg = self.decode(msg)
  self:log(json_msg)

  --process msg

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
