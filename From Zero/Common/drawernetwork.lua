local tabu = require("tabutils");
local itemutils = require("itemutils");

local drawers = peripheral.find("storagedrawers:standard_drawers_4");

local f = string.format;

local function count()
  local kt = {};
  for _, drawer in ipairs(drawers) do
    for _, item in pairs(drawer.list()) do
      if (kt[item.name] == nil) then
        kt[item.name] = item.count;
      else
        kt[item.name] = kt[item.name] + item.count;
      end
    end
  end
  return kt;
end

local commands = {};
commands["list"] = function(args)
  local itemName = args[1] .. " " .. args[2];
  for countName, countNumber in pairs(count()) do
    if (countName:find(itemName)) then
      print(f("%s %s", countNumber, countName));
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