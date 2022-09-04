local modem = peripheral.find("modem");
rednet.open(peripheral.getName(modem));

local pid = 7;

while true do
  print("Locking Stasis Chamber");
  redstone.setOutput("front", true);
  redstone.setOutput("top", false);
  local id = rednet.receive("stasis");
  print("Received Message from " .. id);
  if (pid == id) then
    print("Unlocking Stasis");
    redstone.setOutput("front", false);
    redstone.setOutput("top", true);
    sleep(0.2);
  end
end