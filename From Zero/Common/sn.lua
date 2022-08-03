local tabu = require("tabu");

local commands = {};
commands["list"] = function(args) print(args) end

while true do
  local input = tabu.toTable(read(), " ");
  local command = input[1];
  local f = commands[command];
  if (f ~= nil) then f(tabu.toString(input, 2)); end
end