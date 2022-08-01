local ws = {};
local wss = {};
local wso = {};

local JSON = {};

function JSON.toObj(data)
  return textutils.unserializeJSON(data);
end

function wss.connect(ip)
  ws = http.websocket(ip);
  if (ws) then return wso end
end

function wso:getFile(fileName)
  ws.send(fileName);
  local data = ws.receive();
  return JSON.toObj(data);
end

return wss;