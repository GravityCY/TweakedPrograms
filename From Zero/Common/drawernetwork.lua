local tableutils = require("tableutils");
local itemutils = require("itemutils");

local buffer = peripheral.wrap("minecraft:barrel_0");
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

local function putAll()
  for bufferSlot, bufferItem in pairs(buffer.list()) do
    for _, drawer in ipairs(drawers) do
      local items = drawer.list();
      for slot = 1, drawer.size() do
        local item = items[slot];
        if (item == nil) then 
          buffer.pushItems(peripheral.getName(drawer), bufferSlot, 64, slot);
        else
          if (bufferItem.name == item.name) then
            buffer.pushItems(peripheral.getName(drawer), bufferSlot, 64, slot);
          end
        end
      end
    end
  end
end

local commands = {};
commands["list"] = function(args)
  if (args[1] == nil) then return end
  if (args[2] == nil) then return end
  local itemName = args[1] .. " " .. args[2];
  for countName, countNumber in pairs(count()) do
    if (countName:find(itemName)) then
      print(f("%s %s", countNumber, itemutils.format(countName)));
    end
  end
end

commands["put"] = function(args)
  if (args[1] == nil) then return end
  local type = args[1];
  if (type == "all") then putAll(); end
end

while true do
  term.clear();
  term.setCursorPos(1, 1);
  write("Command: ");
  local input = tableutils.toTable(read(), " ");
  local command = input[1];
  local f = commands[command];
  if (f ~= nil) then f(tableutils.splice(input, 2)); end
end