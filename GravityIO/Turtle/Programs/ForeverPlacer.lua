
local function getSlot()
  for i = 1, 16 do
    local hasItem = turtle.getItemDetail(i) ~= nil;
    if (hasItem) then return i end
  end
end

turtle.select(getSlot());
while true do
  if (turtle.getItemDetail(_) == nil) then turtle.select(getSlot()) end
  turtle.place();
end