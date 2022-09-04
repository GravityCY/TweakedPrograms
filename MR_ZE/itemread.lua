local file = fs.open("item_data", "r")

while true do
  local slotString = file.readLine()
  if (slotString == nil) then break end
  local slot = tonumber(slotString)
  local type = file.readLine()
  local format = ("%s Slot: %d"):format(type, slot);
  print(format);
end

file.close()