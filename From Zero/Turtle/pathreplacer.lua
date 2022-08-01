local bt = require("bt");
local tu = require("tu");
local sides = bt.sides;

local dist = tu.getInput(true, tu.types.number, "Enter Distance: ");

local function selectAny()
  for i = turtle.getSelectedSlot(), 16 do
    local item = turtle.getItemDetail(i);
    if (item ~= nil) then return turtle.select(i) end
  end
  for i = 1, 16 do
    local item = turtle.getItemDetail(i);
    if (item ~= nil) then return turtle.select(i) end
  end
end

for i = 1, dist do
  bt.goDig(sides.forward);
  bt.dig(sides.up)
  bt.dig(sides.down);
  if (not bt.place(sides.down)) then
    selectAny();
  end
end