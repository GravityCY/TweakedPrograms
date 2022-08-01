local bt = require("bt");
local tu = require("tu");
local sides = bt.sides;

local isForward = true;
local mx, mz;

mx = tu.getInput(true, tu.types.number, "Enter Forward: ");
mz = tu.getInput(true, tu.types.number, "Enter Right: ");

local function right()
  if (isForward) then bt.turn(sides.right);
  else bt.turn(sides.left); end
end

for z = 1, mz do
  for x = 1, mx do
    bt.goDig(sides.forward);
    bt.dig(sides.up);
    bt.dig(sides.down);
  end
  if (z ~= mz) then
    right();
    bt.goDig(sides.forward);
    bt.dig(sides.up);
    bt.dig(sides.down);
    right();
    isForward = not isForward;
  end
end
