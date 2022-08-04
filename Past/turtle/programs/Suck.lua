local tu = require("TurtleUtils");
local side = ...;
while tu.suck(tu.sides[side]) do sleep(0) end