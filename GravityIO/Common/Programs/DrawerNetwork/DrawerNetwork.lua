local tableutils = require("tableutils");
local itemutils = require("itemutils");

local buffer = peripheral.wrap("minecraft:barrel_0");
local controllers = {peripheral.find("storagedrawers:controller")};

local f = string.format;

local history = {};

local function count()
  local kt = {};
  for _, controller in ipairs(controllers) do
    for _, item in pairs(controller.list()) do
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
  local put = {};
  for bufferSlot, bufferItem in pairs(buffer.list()) do
    for _, controller in ipairs(controllers) do
      local fin = false;
      local items = controller.list();
      for slot = 1, controller.size() do
        local item = items[slot];
        if (item == nil) then 
          local pushed = buffer.pushItems(peripheral.getName(controller), bufferSlot, 64, slot);
          put[bufferItem.name] = (put[bufferItem.name] or 0) + pushed;
          fin = true;
        else
          if (bufferItem.name == item.name) then
            local pushed = buffer.pushItems(peripheral.getName(controller), bufferSlot, 64, slot);
            put[bufferItem.name] = (put[bufferItem.name] or 0) + pushed;
            if (pushed == bufferItem.count) then fin = true; end
          end
        end
        if (fin) then break end
      end
    end
  end
  return put;
end

local function get(type, count)
  local need = count;
  for _, controller in ipairs(controllers) do
    for slot, item in pairs(controller.list()) do
      if (item.name == type) then
        if (item.count > count) then
          need = need - controller.pushItems(peripheral.getName(buffer), slot, count);
        else
          need = need - controller.pushItems(peripheral.getName(buffer), slot, item.count - 1);
        end
      end
      if (need == 0) then return count end
    end
  end
  return need - count;
end

local commands = {};

commands["list"] = function(args)
  local itemName = "";
  if (args[1] ~= nil) then itemName = args[1]; end
  if (args[2] ~= nil) then itemName = itemName .. " " .. args[2]; end
  for countName, countNumber in pairs(count()) do
    local formatName = itemutils.format(countName);
    if (formatName:lower():find(itemName:lower())) then
      print(f("%s %s", countNumber, formatName));
    end
  end
end

commands["put"] = function(args)
  if (args[1] == nil) then return end
  local type = args[1];
  local put = nil;
  if (type == "all") then
    put = putAll();
  end
  if (put == nil) then return end
  for name, count in pairs(put) do
    print("Put " .. count .. " " .. itemutils.format(name));
  end
end

commands["get"] = function(args)
  if (args[1] == nil) then return end
  if (args[2] == nil) then return end
  local type = args[1];
  local count = args[2];
  local got = get(type, tonumber(count));
  print("Got " .. got .. " " .. itemutils.format(type));
end

local function printCommands()
  for name, _ in pairs(commands) do
    print(name)
  end
end

-- test

term.clear();
term.setCursorPos(1, 1);
while true do
  printCommands();
  write("Command: ");
  local inputString = read();
  local inputTable = tableutils.toTable(inputString, " ");
  local command = inputTable[1];
  local f = commands[command];
  if (f ~= nil) then f(tableutils.splice(inputTable, 2)); end
  history[#history + 1] = inputString;
  if (#history >= 11) then table.remove(history, 1); end
end