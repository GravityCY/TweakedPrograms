local bt = require("BetterTurtle");
local sides = bt.sides;

local args = {...};

local dist = tonumber(args[1]);

local whitelist = {};

local function setupWhitelist()
  for i = 1, 16 do
    local item = turtle.getItemDetail(i);
    if (item ~= nil) then whitelist[item.name] = true; end
  end
end

local function setup()
  -- Args
  dist = args[1];
  if (args[1] == nil) then
    write("Enter Distance: ");
    dist = read();
  end
  dist = tonumber(dist);
  -- Whitelist
  setupWhitelist();
end

local function selectRange(from, to)
  for i = from, to do
    local item = turtle.getItemDetail(i);
    if (item ~= nil and whitelist[item.name] ~= nil) then return turtle.select(i); end
  end
end

local function select()
  local selectedSlot = turtle.getSelectedSlot();
  local selectedItem = turtle.getItemDetail(selectedSlot);
  if (selectedItem ~= nil and whitelist[selectedItem.name] ~= nil) then return true; end
  return selectRange(selectedSlot, 16) or selectRange(1, selectedSlot);
end

local function forward()
  bt.goDig(sides.forward);
  bt.dig(sides.up);
  bt.goDig(sides.down);
end

setup();

for i = 1, dist do
  forward();
  if (select()) then bt.placeDig(sides.down); end
end
