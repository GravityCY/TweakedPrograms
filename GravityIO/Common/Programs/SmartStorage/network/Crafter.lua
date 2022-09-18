local modem = peripheral.find("modem", rednet.open);

while true do
  local _, _, protocol = rednet.receive();
  print(("Received %s Message"):format(protocol));
  if (protocol == "craft-start") then
    turtle.craft();
    sleep(0.05);
    print("Crafted");
    rednet.broadcast(nil, "craft-end");
  elseif (protocol == "list") then
    local items = {};
    for i = 1, 16 do
      items[i] = turtle.getItemDetail(i);
    end
    sleep(0.1);
    rednet.broadcast(items, "list");
  end
end