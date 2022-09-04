local barrel = peripheral.wrap("minecraft:barrel_2")
local file = fs.open("item_data", "w")
 
for slot, item in pairs(barrel.list()) do
    file.writeLine(slot)
    file.writeLine(item.name)
end
 
file.close()