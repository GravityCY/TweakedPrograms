
local InvUtils = require("InvUtils");

local from = InvUtils.wrapList({peripheral.find("reinfbarrel:diamond_barrel")});
local to = InvUtils.wrapList({peripheral.find("reinfbarrel:gold_barrel")});

local temp = {};
for index, inv in ipairs(to) do
  if (inv.taken() ~= inv.size()) then
    table.insert(temp, inv);
  end
end
to = temp;

for index, inv in ipairs(from) do
  for slot, item in pairs(inv.list()) do
    local pushed = 0;
    for _, toInv in ipairs(to) do
      local push = inv.pushItems(peripheral.getName(toInv), slot, item.count - pushed);
      pushed = pushed + push;
      if (pushed == item.count) then break end
    end
  end
end