local tabu = require("tabu");

local drawers = peripheral.find("storagedrawers:standard_drawers_4");

local commands = {};
commands["list"] = function(args)
  for _, drawer in pairs(drawers) do
    for slot, item in pairs(drawer.list()) do
      
    end
  end
end

while true do
  term.clear();
  term.setCursorPos(1, 1);
  write("Command: ");
  local input = tabu.toTable(read(), " ");
  local command = input[1];
  local f = commands[command];
  if (f ~= nil) then f(tabu.splice(input, 2)); end
end