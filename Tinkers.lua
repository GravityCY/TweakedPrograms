local i = require("InvUtils");

local inName = "minecraft:barrel";
local input = i.wrap(peripheral.find(inName));
local outName = "tconstruct:chute";
local output = peripheral.find(outName);

while true do
  input.pushAll(output);
  sleep(1);
end