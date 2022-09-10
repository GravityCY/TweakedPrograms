local moveFrom = {
  "reinfbarrel:diamond_barrel_22",
  "reinfbarrel:diamond_barrel_23",
  "reinfbarrel:diamond_barrel_24",
  "reinfbarrel:diamond_barrel_25",
  "reinfbarrel:diamond_barrel_26",
  "reinfbarrel:diamond_barrel_27",
  "reinfbarrel:diamond_barrel_28",
  "reinfbarrel:diamond_barrel_29"
};
local moveTo = {
  "reinfbarrel:diamond_barrel_12",
  "reinfbarrel:diamond_barrel_13",
  "reinfbarrel:diamond_barrel_14",
  "reinfbarrel:diamond_barrel_15",
  "reinfbarrel:diamond_barrel_16",
  "reinfbarrel:diamond_barrel_17",
  "reinfbarrel:diamond_barrel_18",
  "reinfbarrel:diamond_barrel_19",
  "reinfbarrel:diamond_barrel_20",
  "reinfbarrel:diamond_barrel_21"
};

for index, addr in ipairs(moveFrom) do
  local inv = peripheral.wrap(addr);
  for slot, item in pairs(inv.list()) do
    inv.pushItems(moveTo[index], slot, 64);
  end
end