local pu = require("PeripheralUtils");
local tu = require("TableUtils");
local ku = require("KeyUtils");
local command = require("Command");

local dirPath = "/market/";
local marketData = dirPath .. "data";

local chatBox = peripheral.find("chatBox");

local drawers = pu.getSimilar("drawer", true);
local buffer = drawers[1];

local pieces = {};

local marketName = "";
local productMap = {};

function buffer.get(i)
  return buffer.list()[i];
end

local function totable(str, split) 
  local t = {};
  local pattern = string.format("[^%s]+", split);
  for istr in str:gmatch(pattern) do t[#t+1] = istr; end
  return t;
end

local function getInput()
  local input = read();
  return totable(input, " ");
end

local function onHelp(args)
  if (args and #args > 0) then
    local op = args[1];
    local cmd = command.get(op);
    if (cmd) then write(cmd.id .. " - " .. cmd.description);
    else write("No Such Command.."); end
  else
    for _, cmd in ipairs(command.list()) do
      if (cmd.id ~= "help") then
        write(cmd.id .. " - " .. cmd.description);
      end
    end
  end
end

local function onRegister(args)
  local product = buffer.get(1);
  local cost = nil;
  while true do
    if (not product) then
      term.clear();
      term.setCursorPos(1, 1);
      write("Add an Item to the Inventory under the Computer then Continue...");
      write("Press Enter To Continue.");
      ku.pullKey(keys.enter);
      product = buffer.get(1);
      else break end
  end
  write("Enter Amount of the Product: ");
  product.amount = tonumber(read());
  while true do
    if (not cost) then
      term.clear();
      term.setCursorPos(1, 1);
      write("Add an Item to the Inventory under the Computer then Continue...");
      write("Press Enter To Continue.");
      ku.pullKey(keys.enter);
      cost = buffer.get(1);
      else break end
  end
  write("Enter Amount of the Cost: ");
  cost.amount = tonumber(read());
end

local help = command.new("help", "Gives Information about Commands", nil, onHelp);
local register = command.new("register", "Registers A Product", {"reg"}, onRegister);

command.register(help);
command.register(register);

local function main()
  term.clear();
  term.setCursorPos(1, 1);
  help.onCommand();
  while true do
    write("Enter Command: ");
    local input = getInput();
    local op = input[1];
    local command = command.get(op);
    if (command) then command.onCommand(tu.range(input, 2)); end
    -- if (op == "cost") then
    --   local pName = input[2];
    --   if (not pName) then pName = requestInput("Enter Product ID: "); end
    --   local drawer = getDrawer(pName);
    --   if (drawer) then productMap[pName] = drawer.list()[2];
    --   else print("No such Product"); end
    -- elseif (op == "print") then
    --   local pName = input[2];
    --   if (not pName) then pName = requestInput("Enter Product ID: "); end
    --   local product = productMap[pName];
    --   if (product) then print(product.name);
    --   else print("No such Product or Product has no cost"); end
    -- elseif (op == "help") then
    --   local inputCommand = input[2];
    --   if (inputCommand) then
    --     local commandDesc = commands[inputCommand];
    --     if (commandDesc) then print(commandDesc);
    --     else print("No such command...") end
    --   else help(); end
    -- end
  end
end

main();