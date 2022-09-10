local modem = peripheral.find("modem", rednet.open);

while true do
  rednet.receive("craft-start");
  print("Received Craft Message");
  turtle.craft();
  sleep(0.05);
  print("Crafted");
  rednet.broadcast(nil, "craft-end");
end