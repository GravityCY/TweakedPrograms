local function toTable(input)
  local args = {};

  local i = 1;
  while true do
    local str = "";
    local quote = nil;
    while true do
      local char = input:sub(i, i);
      if (char == "") then break end
      if (char == "\"" or char == "\'") then
        if (not quote) then 
          quote = char;
          i = i + 1;
          char = input:sub(i, i);
        elseif (char == quote) then break end
      end
      if (not quote) then
        if (char == " ") then 
          if (str ~= "") then break end
        else str = str .. char; end
      else str = str .. char; end
      i = i + 1;
    end
    i = i + 1;
    if (str == "") then break end
    table.insert(args, str);
  end
  return args;
end

local ops = {};
local opsList = {};

local function printHelp(command, doPrintExample, doPrintDescription)
  if (doPrintExample == nil) then doPrintExample = true; end
  if (doPrintDescription == nil) then doPrintDescription = false; end
  local str = command.name;
  if (doPrintDescription) then str = str .. " - " .. command.description; end
  print(str);
  if (doPrintExample and command.example) then print(command.example); end
end

local function newOP(name, desc, fn, example)
  local op = {};
  op.name = name;
  op.description = desc;
  op.fn = fn;
  op.example = example;
  ops[name] = op;
  opsList[#opsList+1] = op;
end

if (isDebug) then
  newOP("debug", "Debug", function(args)
    term.clear();
    term.setCursorPos(1, 1);
    if (args[2] == "inv") then
      for i, v in ipairs(sn.getInventories()) do print(v); end
    elseif (args[2] == "import") then
      for i, v in ipairs(importerAddrs) do print(v); end 
    elseif (args[2] == "buffer") then
      print(sn.getBuffer());
    end
  end)
end

newOP("craft", "Crafts Items using the Crafty Turtle Connected to the Network", function(args)
end, "craft 'minecraft:cobblestone' to Craft a Registered Recipe by that id.\ncraft new - Registers a new Recipe.\ncraft list - Lists all Registered Recipes.")

newOP("buffer", "Sets detection mode to Buffer, any inventory you add, will be marked as a buffer", function()

end)

newOP("storage", "Sets detection mode to Storage, any inventory you add, will be marked as storage.", function(args)

end);

newOP("import", "Imports Items into the network from a specific address", function()

end)

newOP("export", "Exports an Item into an Inventory", function()

end)

newOP("list", "Lists Items by a Filter", function(args) 

end);

newOP("compact", "Compacts Items (Inefficiently)", function(args)

end)

newOP("sort", "Sorts all Items alphabetically (Using Their IDS)", function() 

end);

newOP("full", "Displays how full the Storage Network is", function()

end)

newOP("get", "Gets an Item using it's ID and puts it into the buffer chest", function(args)

end);

newOP("put", "Puts an Item from the buffer chest in the system", function(args)

end);

newOP("help", "Lists all Commands", function(args) 
  term.clear();
  term.setCursorPos(1, 1);
  print("Commands: ");
  if (args and args[2]) then
    local op = ops[args[2]];
    if (op) then printHelp(op, true, true);
    else print("No such Command."); end
  else
    for _, op in pairs(opsList) do
      printHelp(op, false, false);
    end
  end
end)

newOP("exit", "Exits the program", function()

end)

local modem = peripheral.find("modem");
modem.open(6969);
while true do
  write("Enter Command: ");
  local input = read();
  local args = toTable(input);
  local op = args[1];
  local command = ops[op];
  if (command) then modem.transmit(1, 1, input);
  else ops.help.fn(); end
end