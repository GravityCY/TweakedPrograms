local tUtils = require("TurtleUtils");
local sides = tUtils.sides;
local gs = tUtils.getSlot;

local executions = {...};

local dd = gs("computercraft:disk_drive");
turtle.select(dd);
tUtils.place(sides.forward);

local commands = {"startup", "label"}
local function parseCommand(str)
  for _, command in pairs(commands) do
    local formatted = string.format("%s=(.+)", command);
    local arg = str:match(formatted);
    if (arg) then return command, arg; end
  end
  return nil, str;
end

local function readAll(path)
  local file = fs.open(path, "r");
  local content = file.readAll();
  file.close();
  return content;
end

local function format()
  for i = 1, #executions do
    local exec = executions[i];
    local cmd, input = parseCommand(exec);
    if (cmd == "label") then disk.setLabel("front", input);
    else
      local inPath = input;
      local outPath = "/disk/"..inPath;
      if (cmd == "startup") then outPath = "/disk/startup.lua"; end
      if (fs.exists(outPath)) then fs.delete(outPath); end
      fs.copy(inPath, outPath);
    end
  end
end

for i = 1, 16 do
  local item = turtle.getItemDetail(i);
  if (item and item.name == "computercraft:turtle_normal") then
    tUtils.drop(i, sides.forward);
    format();
    tUtils.suck(sides.forward);
  end
end
turtle.select(1);
tUtils.dig(sides.forward);
