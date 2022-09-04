local pos = 1;
while true do
  turtle.select(pos);
  turtle.place();
  if (not turtle.getItemDetail()) then pos = pos % 16 + 1; end
end