local iUtils = require("InvUtils");

local sleepTime = 2;

local arg = ...;

local inName = arg or "minecraft:barrel";
local outName = "tconstruct:chute";

local input = iUtils.wrap(peripheral.find(inName));
local inAnyCount = input.anyCount();

local outs = {peripheral.find(outName)};
local outCount = #outs;

while true do
  for index, out in pairs(outs) do 
    input.pushAny(out, inAnyCount / outCount); 
  end
  sleep(sleepTime);
end