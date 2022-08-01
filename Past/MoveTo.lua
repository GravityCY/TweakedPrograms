local i = require("InvUtils");

local args = {...};
local inName = args[1];
local input = i.wrap(peripheral.find(inName));
local outName = args[2];
local output = peripheral.find(outName);

input.pushAll(output);
