local tu = require("TurtleUtils");
local sides = tu.sides;
local fn = function(side) tu.goDig(side); end
tu.goPos(-2, 3, -3, fn)

