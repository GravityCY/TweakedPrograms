local Command = require("Command");
local pu = require("PerUtils");
local diskDrive = (pu.find("drive"))[1];
local invsInput = pu.getType("inventory");

local name = "Test";
local programs = {};

local cmdPrograms = Command.new("programs", "adds programs", 1, -1);
cmdPrograms.setFunction(function(args)
  for _, path in ipairs(args) do
    table.insert(programs, path);
  end
end);

local cmdHelp = Command.new("help", "helps");
cmdHelp.setFunction(function() 
  for alias, cmd in pairs(Command.getCommands()) do
    print(("%s - %s"):format(alias, cmd.description));
  end
end)

Command.add(cmdPrograms);
Command.add(cmdHelp);

local function isQuote(char)
  return char == "\"" or char == "'";
end

local function parse(input)
  local args = {};

  local i = 1;
  while true do
    local str = "";
    local quote = nil;
    while true do
      if (i > #input) then break end
      local char = input:sub(i, i);
      if (quote == nil and str ~= "" and char == " ") then break end

      if (isQuote(char)) then
        if (quote == nil) then quote = char;
        elseif (quote ~= char) then str = str .. char;
        else break end
      elseif ((quote ~= nil and char == " ") or (char ~= " ")) then str = str .. char; end
      i = i + 1;
    end
    i = i + 1;
    if (str == "") then break end
    table.insert(args, str);
  end
  return args;
end

local function main()
  while true do
    local inputString = read();
    local inputArgs = parse(inputString);
    local state, errorMessage = Command.parse(inputArgs);
    print(errorMessage);
  end
end

main();