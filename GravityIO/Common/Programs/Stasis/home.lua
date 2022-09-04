local modem = peripheral.find("modem");
rednet.open(peripheral.getName(modem));

local id = 9;

rednet.send(id, nil, "stasis");
