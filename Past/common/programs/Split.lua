local iUtils = require("InvUtils");

local args = {...};

local inName = args[1];
local outName = args[2];

if (not inName) then
  write("Enter the ID of the block to split: ");
  inName = read();
end
if (not outName) then
  write("Enter the ID of the blocks you want to split into: ");
  outName = read();
end

local input = iUtils.wrap(peripheral.find(inName));
local outs = {peripheral.find(outName)};

input.splitAny(outs);
