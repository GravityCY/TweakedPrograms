--[[
  Synopsis of the program:
    many barrels, each barrels text file is named after the barrel
    each barrel gets a list of items inside
    format
    modularity by a specific interface block type
--]]


local barrels = {peripheral.find("minecraft:chest")}

for index, barrel in ipairs(barrels) do
  local name = peripheral.getName(barrel);
  local format = string.gsub(name, ":", "_");
  local file = fs.open("/chest_data/" .. format, "w");
  for slot, item in pairs(barrel.list()) do
    file.writeLine(slot)
    file.writeLine(item.name)
  end
  file.close();
end

-- local file = fs.open("item_data", "w")
-- for slot, item in pairs(barrel.list()) do
--     file.writeLine(slot)
--     file.writeLine(item.name)
-- end
 
-- file.close()

-- local function test()
--   local a = 1
--   local b = "something"
--   local c = {["ass"]="stuff", "asd"};
--   return a, b, c
-- end

-- local t = {["minecraft:barrel_1"]={"minecraft:dirt"}}

-- t["minecraft:barrel_1"][1]