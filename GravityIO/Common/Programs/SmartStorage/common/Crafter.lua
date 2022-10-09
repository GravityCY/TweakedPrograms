local modem = peripheral.find("modem", rednet.open);

local storageId = 27;

while true do
  local _, _, protocol = rednet.receive();
  print(("Received %s protocol"):format(protocol));
  if (protocol == "craft-start") then
    turtle.craft();
    sleep(0.1);
    rednet.send(storageId, nil, "craft-end");
  elseif (protocol == "list-start") then
    local items = {};
    for i = 1, 16 do
      items[i] = turtle.getItemDetail(i);
    end
    sleep(0.1);
    rednet.send(storageId, items, "list-end");
  end
end