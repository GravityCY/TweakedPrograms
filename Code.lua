local ip, port = "192.168.0.69", 8080;

local id = os.getComputerID();

local ws = nil;

local function onSave(message)
    local fileName, content = message:match("(%S+) (.+)");
    local file = fs.open(fileName, "w");
    file.write(content);
    file.close();
    print("Writing file, " .. fileName);
end

local function onSync(message)
    local fileName = message;
    local file = fs.open(fileName, "r");
    local content = "";
    if (file) then content = file.readAll(); end
    ws.send(content);
    file.close();
    print("Syncing file, " .. fileName);
end

local ops = {sync=onSync, save=onSave};

local function onMessage(message)
    local op, msg = message:match("(%S+) (.+)");    
    ops[op](msg);
end

while true do
  ws = http.websocket("ws://"..ip..":"..port);
  if (ws) then
    print("Connected.");
    sleep(0.5);
    ws.send(id);
    while true do
      print("Waiting For Message...");
      local message = ws.receive();
      onMessage(message);
    end
  else 
    print("Disconnected...");
    sleep(1); 
  end
end