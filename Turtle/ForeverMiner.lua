local t = require("TurtleUtils");
local sides = t.sides;

local auto = peripheral.find("weakAutomata");

auto.setFuelConsumptionRate(3);

local function quit(reason)
  print(reason);
  error();
end

turtle.select(1);
while true do
  if (turtle.getFuelLevel() <= 500) then quit("Low Fuel Level") end
  local pick = turtle.getItemDetail(_, true);
  if (pick.maxDamage - pick.damage <= 50) then quit("Low Durability"); end
  auto.digBlock();
  auto.collectItems(64);
  if (t.full()) then t.dropRange(2, 16, 64, sides.down); end
  sleep(auto.getOperationCooldown("dig") / 1000);
end