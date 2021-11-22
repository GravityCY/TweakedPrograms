
turtle.select(1);
while true do
  if (not turtle.getItemDetail(_, true)) then turtle.suckUp(); end
  turtle.placeDown();
end