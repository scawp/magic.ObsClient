if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  require("lldebugger").start()
end

local websocket = require("websocket")
local jsondecoder = require 'decoder'
local jsonencoder = require 'encoder'

return {
  new = function(self, host, port)
    local ws = websocket.new(host or "localhost", port or 4445)

    ws.json_decode = jsondecoder()
    ws.json_encode = jsonencoder()
    ws.requests = require 'obsClient.api.requests'
    ws.events = require 'obsClient.api.events'
    ws.callbacks = require 'obsClient.api.callbacks'

    ws.init = function(self)
      self.msg_queue = {}
      self.request_callback_list = {}
      self.connected = false
    end
    
    ws._message_id = 0
    ws.new_message_id = function(self)
      self._message_id = self._message_id + 1
      return self._message_id
    end
    
    --update already in the require, uncomment if needs extending
    --ws.update = function(self, dt)
      --self:update()
    --end
    
    ws.onopen = function(self)
      self.connected = true
      self:log("Connection to OBS opened")
    
      self:sendqueue()
    end
    
    ws.sendqueue = function(self)
      for i, query_str in ipairs(self.msg_queue) do
        if self:sendObsRequest(query_str) then
          --can i do this mid iteration?
          --TODO: no, see docs
          table.remove(self.msg_queue, i)
        end
      end
    end
    
    ws.add_callback = function(self, callback_func, message_id)
      --TODO: ignore if not in callback list?
      self.request_callback_list[tostring(message_id)] = callback_func
      return message_id
    end
    
    ws.sendObsRequest = function(self, query_str)
      local retry = false
      
      if type(query_str) ~= "string" then
        if type(query_str) == "table" then
          if query_str["callback_func"] then
            --TODO: clean up to show call to add_callback
            query_str["message-id"] = tostring(self:add_callback(query_str["callback_func"], self:new_message_id()))
          else
            query_str["message-id"] = tostring(self:new_message_id())
          end
          retry = query_str["retry"] or false 
          query_str = self.json_encode(query_str)
        else
          self:log("Query is type table nor string", "On Send")
          return false
        end
      else
        --this assumes because its a string it comes from the queue
        --and hence only got there because "retry" was set
        --TODO: dont assume
        retry = true
      end
      self:log(query_str, "On Send")
      if self.connected then
        self:send(query_str)
        return true
      else
        if retry then
          table.insert(self.msg_queue, query_str)
          self:log("Connection not established adding to queue", "On Send")
        else
          self:log("Connection not established, dropping request", "On Send")
        end
        return false
      end
    end
    
    ws.onmessage = function(self, msg)
      self:log(msg, "Event")
    
      local err = nil
      local success, data = pcall(self.json_decode, msg)
      if not success then
        self:log("JSON Decoding Error " .. data, "Invalid Data")
      else
        --if data["error"] then
        --errors logged at Log Event: so dont add more logs here
        --maybe if screen output is required
        --potentially add message to self.request_callback_list for retry on error?
        if data["update-type"] then
          --call event watchers
          success, err = pcall(self.events[data["update-type"]], self, data)
          if success then
            self.request_callback_list[tostring(data["message-id"])] = nil
          else
            --TODO: err is "attempt to call a nil value" when no event watcher
            --check if nil before pcall rather than relying on this
            --log message will be wrong
            self:log("Ignoring " .. data["update-type"] .. " " .. err, "Unhandled Event")
          end
        elseif data["message-id"] then 
          if self.request_callback_list[data["message-id"]] then
            success, err = pcall(self.callbacks[self.request_callback_list[data["message-id"]]], self, data)
            if not success then
              self:log("Ignoring " .. data["message-id"] .. " " .. err, "Unhandled Callback Function")
            end
            --remove message from callback queue
            self.request_callback_list[tostring(data["message-id"])] = nil
          else
            self:log("Ignoring " .. data["message-id"], "Unhandled Callback Message")
          end
        else
          self:log("Ignoring" .. err, "Unhandled Data")
        end
      end
    
      self:sendqueue()
    end
    
    ws.onclose = function(self)
      self.connected = false
      self:log("Connection to OBS closed")
    end
    
    ws.debug = {
      init_time = os.time()
    }
    
    ws.log = function(self, data, type)
      type = type or "obs_client"
      print("[".. os.time() .. "] " .. type .. ": " .. tostring(data))
      love.filesystem.append("obsClient.log",
      --this was really annoying
      --love.filesystem.append("obsClient-" .. self.debug.init_time .. ".log", 
                             "[".. os.time() .. "] " .. type .. ": " .. tostring(data) .. "\r\n")
    end
    return ws
  end
}