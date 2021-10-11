
function string.explode(str, div) --https://love2d.org/wiki/String_exploding
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

return {
  validRequests = {},

  GetSceneListCallBack = function(self, data)
    self:log("Getting Current Scene \"" .. data["current-scene"] .. "\"", "Callback")
  
    for i, scene in ipairs(data.scenes) do
      MENU:addButton({label = scene.name, 
                      --y = i * 100,
                      action = function ()
                        --TODO move log from obsclient
                        self:log("clicked " .. scene.name, "Button Click")
                        self.requests:SetCurrentScene(scene.name)
                      end
                    })
    end
  end,

  GetVersionCallback = function(self, data)
    self.validRequests = string.explode(data["available-requests"], ",")
    for i, v in ipairs(self.validRequests) do 
      print(v)
    end
  end
}