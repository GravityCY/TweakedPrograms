local tabu = require("TableUtils");

local Todo = {}

local todos = {};

local sizeArg = ...;
local size = 1;
if (sizeArg) then size = tonumber(sizeArg); end
local monitor = peripheral.find("monitor");
monitor.setTextScale(size);

local computer = term.current();

Todo.new = function(todoName, todoContent)
  return {name=todoName, content=todoContent};
end

local function requestInput(request)
  local input = nil;
  while (input == nil or input == "") do
    write(request);
    input = read();
  end
  return input;
end

local function getInput()
  local input = read();
  local inTable = {};
  for string in input:gmatch("%S+") do tableutils.insert(inTable, string); end
  return inTable;
end

local function prepFile()
  if (not fs.exists("/data/todos.list")) then
    fs.open("/data/todos.list", "w").close();
  end
end

local function save()
  local file = fs.open("/data/todos.list", "w");
  for title, content in pairs(todos) do
    file.write(title .. " " .. content .. "\n");
  end
  file.close();
end

local function load()
  local file = fs.open("/data/todos.list", "r");
  local data = file.readAll();
  for line in data:gmatch("[^\n]+") do
    local title, content = line:match("(%S+) (.+)") 
    todos[title] = content;
  end
  file.close();
end

local function mprint(...)
  if (monitor) then
    term.redirect(monitor);
    write(...);
    term.redirect(computer);
  else write(...) end
end

local ops = {};
local aliases = {};

-- Add Operator
ops.add = {};
ops.add.desc="Adds a new Todo";
ops.add.fn = function(input)
  local todoName = input[2] or requestInput("Enter Title: ");
  local todoContent = tabu.toString(input, 3, nil, " ") or requestInput("Enter Content: ");
  if (not todos[todoName]) then 
    todos[todoName] = todoContent;
    local file = fs.open("/data/todos.list", "a");
    file.write(todoName .. " " .. todoContent);
    file.close();
    write("Succesfully added " .. todoName);
  else write("Name Already Exists"); end
end

-- Remove Operator
ops.remove = {};
ops.remove.desc = "Removes a Todo";
ops.remove.alias = {"rm"};
ops.remove.fn = function(input)
  local todoName = input[2] or requestInput("Enter Todo Title: ");
  if (todos[todoName]) then 
    todos[todoName] = nil;
    save();
    write("Successfully deleted " .. todoName .. ".");
  else write("Todo does not exist..."); end
end

ops.edit = {};
ops.edit.desc = "Edits a Todo";
ops.edit.alias = {"ed"};
ops.edit.fn = function(input)
  local todoName = input[2] or requestInput("Enter Todo Title: ");
  if (todos[todoName]) then
    local todoContent = tabu.toString(input, 3, nil, " ") or requestInput("Enter Content: ");
    todos[todoName] = todoContent;
    save();
    write("Succesfully edited " .. todoName .. ".");
  else write("Todo does not exist..."); end
end

-- List Operator
ops.list = {};
ops.list.alias = {"ls"};
ops.list.desc = "Lists all Todos";
ops.list.fn = function()
  local total = 0;
  monitor.clear();
  monitor.setCursorPos(1, 1);
  for todoName, todoContent in pairs(todos) do
    local formatted = string.format("%s: %s.", todoName, todoContent);
    write(formatted);
    mprint(formatted);
    total = total + 1;
  end
  if (total == 0) then write("No Todos... :("); mprint("No Todos... :("); end
end

-- Help Operator
ops.help = {}
ops.help.desc = "Displays This Page";
ops.help.fn = function() 
  for opName, op in pairs(ops) do
    local result = "";
    if (op.alias) then
      result = opName .. " ( ";
      for _, alias in ipairs(op.alias) do
        result = result .. alias .. " "
      end
      result = result .. "): " .. op.desc;
    else result = string.format("%s: %s.", opName, op.desc); end
    write(result);
  end
end

for opName, op in pairs(ops) do
  if (op.alias) then
    for _, aliasName in ipairs(op.alias) do
      aliases[aliasName] = op;
    end
  end
end

term.clear();
term.setCursorPos(1, 1);
prepFile();
load();
ops.help.fn();
while true do
  write("Type: ");
  local input = getInput();
  local opInput = input[1];
  term.clear();
  term.setCursorPos(1, 1);
  local op = ops[opInput] or aliases[opInput];
  if (op) then op.fn(input);
  else ops.help.fn(); end
end