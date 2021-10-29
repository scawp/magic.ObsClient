local websocket = require("websocket")
local jsondecoder = require 'decoder'
local jsonencoder = require 'encoder'

--helper functions
function string_explode(str, div) --https://love2d.org/wiki/String_exploding
  assert(type(str) == "string" and type(div) == "string", "invalid arguments")
  local o = {}
  while true do
      local pos1,pos2 = str:find(div)
      if not pos1 then
          o[#o+1] = str
          break
      end
      o[#o+1],str = str:sub(1,pos1-1),str:sub(pos2+1)
  end
  return o
end

function table_contains(table, str)
  for _, el in pairs(table) do
    if el == str then
      return true
    end
  end
  return false
end

--Magic.obsClient
return {
  new = function(host, port)
    local obsClient = websocket.new(host or "localhost", port or 4444)

    obsClient.host = host
    obsClient.port = port
    obsClient.json_decode = jsondecoder()
    obsClient.json_encode = jsonencoder()

    obsClient.msg_queue = {}
    obsClient.request_callback_list = {}
    obsClient.event_watcher_list = {}
    obsClient.connected = false
    obsClient.valid_requests = {}

    obsClient.watchEvent = function (self, event, watch_func)
      self.event_watcher_list[event] = watch_func
    end
    
    obsClient._message_id = 0
    obsClient.getNewMessageId = function(self)
      self._message_id = self._message_id + 1
      return "magic-" .. self._message_id
    end
    
    obsClient.onopen = function(self)
      self:log("Connection to OBS opened", "Connection")

      self:sendRequest("GetVersion",
                       "magic-connecting",
                       function(data)
                         self.valid_requests = string_explode(data["available-requests"], ",")
                         self.connected = true
                         self:sendMessageQueue()
                       end)
    end

    obsClient.addToCallbackList = function(self, callback_func, message_id)
      --TODO: ignore if not in callback list?
      self.request_callback_list[tostring(message_id)] = callback_func
    end
    
    obsClient.validateQueryParams = function(self, params)
      if type(params) == "table" 
         and params["request-type"] 
         and table_contains(self.valid_requests, params["request-type"]) then
        return true
      end
      return false
    end

    obsClient.addToMessageQueue = function(self, params)
      table.insert(self.msg_queue, params)
    end

    obsClient.sendMessageQueue = function(self)
      for i, query_str in ipairs(self.msg_queue) do
        if self:_sendRequest(query_str) then
          --can i do this mid iteration?
          --TODO: no?, see docs
          table.remove(self.msg_queue, i)
        end
      end
    end

    obsClient.sendRequest = function(self, request_type, ...)
      local params = {}
      if {...} then
        for _, var in pairs({...}) do
          if type(var) == "table" then 
            params = var 
            break
          end
        end

        for _, var in pairs({...}) do
          if type(var) == "function" then 
            params["callback_func"] = var
          elseif type(var) == "boolean" then
            params["retry"] = var
          elseif type(var) == "string" then 
            params["message-id"] = var 
          end
        end
      end
      
      params["request-type"] = request_type
      self:_sendRequest(params)
    end
    
    obsClient._sendRequest = function(self, params)
      if self.connected or params["message-id"] == "magic-connecting" then
        if self:validateQueryParams(params) or params["message-id"] == "magic-connecting" then
          self:log(params["message-id"], "Sending Msg")

          params["message-id"] = params["message-id"] or self:getNewMessageId()

          if params["callback_func"] then
            self:addToCallbackList(params["callback_func"], params["message-id"])
          end
        
          --remove the things obs doesnt need before sending
          params["callback_func"] = nil
          params["retry"] = nil
          self:send(self.json_encode(params))

          return true
        else
          self:log("INVALID REQUEST" .. params["request-type"],"Invalid Request Query")
  
          return false
        end
      else
        if params["retry"] then
          self:log("Connection not established adding to queue", "Send Obs Request")
          
          self:addToMessageQueue(params)
        else
          self:log("Connection not established, dropping request", "Send Obs Request")
        end

        return false
      end
    end
    
    obsClient.onmessage = function(self, msg)
      self:log(msg, "Event")
    
      local err = nil
      local success, data = pcall(self.json_decode, msg)
      if not success then
        self:log("JSON Decoding Error " .. data, "Invalid Data")
      else
        if data["update-type"] then
          --call event watchers
          if self.event_watcher_list[data["update-type"]] then
            --TODO: update this to handle multiple watchers
            self.event_watcher_list[data["update-type"]](data)
          else
            self:log("Ignoring " .. data["update-type"], "Unhandled Event")
          end
        elseif data["message-id"] then 
          if self.request_callback_list[data["message-id"]] then
            if type(self.request_callback_list[data["message-id"]]) == "function" then
              self.request_callback_list[data["message-id"]](data)
            else
              self:log("Ignoring " .. data["message-id"], "Invalid Callback Function")
            end
            --TODO: remove message from callback queue in function
            self.request_callback_list[tostring(data["message-id"])] = nil
          else
            self:log("Skipping " .. data["message-id"], "Unhandled Callback Message")
          end
        else
          self:log("Ignoring" .. err, "Unhandled Data")
        end
      end
    
      self:sendMessageQueue()
    end
    
    obsClient.onclose = function(self)
      self.connected = false
      self:log("Connection to OBS closed", "Connection")
    end
    
    --TODO move this to magic.debug
    obsClient.log = function(self, data, type)
      type = type or "obs_client"
      print("[".. os.time() .. "] " .. type .. ": " .. tostring(data))
      love.filesystem.append("obsClient.log",
                             "[".. os.time() .. "] " .. type .. ": " .. tostring(data) .. "\r\n")
    end
    return obsClient
  end
}