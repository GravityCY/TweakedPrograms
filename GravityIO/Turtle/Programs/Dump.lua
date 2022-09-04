local tu = require("TurtleUtils");

local id, side = ...;

local function getSimilar(name)
  for i = 1, 16 do
    local item = turtle.getItemDetail(i);
    if (item and item.name:find(name)) then return i end
  end
end

while true do 
  local slot = getSimilar(id);
  if (not slot) then break end
  tu.drop(slot, 64, tu.sides[side]);
end