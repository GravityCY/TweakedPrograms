local pUtils = require("PeripheralUtils");

local inputName = "tconstruct:drain";
local outputName = "tconstruct:table";

local ingotCastName = "tconstruct:ingot_cast";
local nuggetCastName = "tconstruct:nugget_cast";

local inputPerph = peripheral.find(inputName);
local inputAddr = peripheral.getName(inputPerph);
local outputPerphs = pUtils.getAllNotSide(outputName);

local ingotMB = 144;
local nuggetMB = 16;

local ingotTables = {};
local nuggetTables = {};

for index, perph in pairs(outputPerphs) do
  local name = perph.getItemDetail(1).name;
  if (name == ingotCastName) then table.insert(ingotTables, perph); end
  if (name == nuggetCastName) then table.insert(nuggetTables, perph); end
end

while true do
  for index, fluid in pairs(inputPerph.tanks()) do
    local total = 0;
    for ingotIndex, ingotTable in pairs(ingotTables) do
      local fluidAmount = fluid.amount - total;
      if (fluidAmount >= ingotMB) then
        total = total + ingotTable.pullFluid(inputAddr, ingotMB, fluid.name);
      else break end
    end
    for nuggetIndex, nuggetTable in pairs(nuggetTables) do
      local fluidAmount = fluid.amount - total;
      if (fluidAmount <= ingotMB and fluidAmount >= nuggetMB) then
        total = total + nuggetTable.pullFluid(inputAddr, nuggetMB, fluid.name);
      else break end
    end
  end
  sleep(0.5);
end