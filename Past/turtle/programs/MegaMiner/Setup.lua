local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local executions = {...};

tUtils.dig(sides.forward);
tUtils.selectID("computercraft:disk_drive");
tUtils.place(sides.forward);
repeat sleep(0) until (peripheral.wrap("front"))
local ddp = peripheral.wrap("front");

local processed = {};

local commands = {"startup", "label"}
local function parseCommand(str)
  for _, command in pairs(commands) do
    local pattern = "(.+)";
    local arg = str:match(command.."="..pattern);
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
  local mountPath = ddp.getMountPath();
  if (not mountPath) then
    turtle.suck();
    turtle.up();
    turtle.place();
    sleep(0);
    repeat sleep(0) until (peripheral.wrap("front"))
    peripheral.wrap("front").turnOn();
    local success, slot = tUtils.dig(sides.forward, true);
    turtle.down();
    turtle.drop();
  end
  for i = 1, #executions do
    local exec = executions[i];
    local cmd, input = parseCommand(exec);
    if (cmd == "label") then ddp.setDiskLabel(input);
    else
      local inPath = input;
      local outPath = string.format("/%s/%s", mountPath, inPath);
      if (cmd == "startup") then outPath = string.format("/%s/startup.lua", mountPath); end
      if (fs.exists(outPath)) then fs.delete(outPath); end
      fs.copy(inPath, outPath);
    end
  end
end

local function getTurtle()
  for i = 1, 16 do
    local item = turtle.getItemDetail(i, true);
    if (item and item.name == "computercraft:turtle_normal" and processed[item.nbt] == nil) then
      return i, item;
    end
  end
end

while true do
  local slot, turt = getTurtle();
  if (not turt) then break end
  tUtils.drop(slot, 1, sides.forward);
  format();
  local success, slot = tUtils.suck(sides.forward, true);
  processed[turtle.getItemDetail(slot, true).nbt] = true;
end
turtle.select(1);
tUtils.dig(sides.forward);
