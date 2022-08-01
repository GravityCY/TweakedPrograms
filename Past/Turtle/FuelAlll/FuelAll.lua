local tu = require("TurtleUtils");
local count = 0;
local fuel = 0;
local split = 0;

local clientCode = nil;

local function getFuelName()
  for i = 1, 16 do
    local item = turtle.getItemDetail(i);
    if (item ~= nil and item.name ~= "computercraft:turtle_normal" and item.name ~= "computercraft:disk_drive") then return item.name end
  end
end

local function getClientCode()
  local rf = fs.open("/Client.lua", "r");
  local content = rf.readAll();
  rf.close();
  return content;
end

clientCode = getClientCode();
count = tu.count("computercraft:turtle_normal");
fuel = tu.count(getFuelName());
split = fuel / count;

tu.selectID("computercraft:disk_drive");
turtle.place();

repeat sleep(1) until peripheral.wrap("front") ~= nil
local diskDrive = peripheral.wrap("front");
for i = 1, 16 do
  local item = turtle.getItemDetail(i);
  if (item ~= nil and item.name == "computercraft:turtle_normal") then
    turtle.select(i);
    turtle.drop();
    local mntPath = diskDrive.getMountPath();
    local start = mntPath .. "/startup.lua";
    if (fs.exists(start)) then fs.move(start, mntPath .. "/temp_prev_startup_.lua"); end
    local wf = fs.open(start, "w");
    wf.write(clientCode);
    wf.close();
    turtle.suck();
    turtle.placeUp();
    repeat sleep(1) until peripheral.wrap("top") ~= nil
    local client = peripheral.wrap("top");
    client.turnOn();
    client.getLabel();
  end
end
