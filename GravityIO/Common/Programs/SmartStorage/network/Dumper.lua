while true do
  for i = 1, 16 do
    local item = turtle.getItemDetail(i);
    if (item ~= nil) then
      turtle.select(i);
      turtle.dropDown();
    end
  end
  sleep(1);
end