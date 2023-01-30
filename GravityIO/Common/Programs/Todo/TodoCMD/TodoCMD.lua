local TodoList = require("TodoList");
local TableUtils = require("TableUtils");

TodoList.savePath = "/data/todo/todos";
TodoList.loadPath = TodoList.savePath;

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
  for string in input:gmatch("%S+") do table.insert(inTable, string); end
  return inTable;
end

local ops = {};
local aliases = {};

-- Add Operator
ops.add = {};
ops.add.desc="Adds a new Todo";
ops.add.fn = function(input)
  local todoTitle = input[1] or requestInput("Enter Title: ");
  local todoDescription = nil;
  if (not TodoList.exists(todoTitle)) then
    if (input[3] ~= nil) then
      todoDescription = TableUtils.toString(TableUtils.range(input, 2), " ");
    else
      todoDescription = requestInput("Enter Content: ");
    end
    TodoList.add(todoTitle, todoDescription);
    print("Added " .. todoTitle);
  else print("Already exists..."); end
end

-- Remove Operator
ops.remove = {};
ops.remove.desc = "Removes a Todo";
ops.remove.alias = {"rm"};
ops.remove.fn = function(input)
  local todoTitle = input[2] or requestInput("Enter Todo Title: ");
  if (TodoList.remove(todoTitle)) then print("Removed " .. todoTitle);
  else print("Todo does not exist..."); end
end

ops.edit = {};
ops.edit.desc = "Edits a Todo";
ops.edit.alias = {"ed"};
ops.edit.fn = function(input)
  local todoTitle = TableUtils.toString(input, " ");
  if (todoTitle == "") then todoTitle = requestInput("Enter Todo Title: "); end
  if (TodoList.exists(todoTitle)) then
    local todoDescription = TableUtils.toString(TableUtils.range(input, 3), " ") or requestInput("Enter Content: ");
    TodoList.edit(todoTitle, todoTitle, todoDescription):
    print("Succesfully edited " .. todoTitle .. ".");
  else print("Todo does not exist..."); end
end

-- List Operator
ops.list = {};
ops.list.alias = {"ls"};
ops.list.desc = "Lists all Todos";
ops.list.fn = function()
  local total = 0;
  for _, todo in pairs(TodoList.list()) do
    local formatted = todo.title .. ": " .. todo.description .. ".";
    print(formatted);
    total = total + 1;
  end
  if (total == 0) then print("No Todos... :("); end
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
    print(result);
  end
end

for _, op in pairs(ops) do
  if (op.alias) then
    for _, aliasName in ipairs(op.alias) do
      aliases[aliasName] = op;
    end
  end
end

term.clear();
term.setCursorPos(1, 1);
TodoList.load();
ops.help.fn();
while true do
  write("Type: ");
  local input = getInput();
  local opInput = input[1];
  term.clear();
  term.setCursorPos(1, 1);
  local op = ops[opInput] or aliases[opInput];
  if (op) then op.fn(TableUtils.range(input, 2));
  else ops.help.fn(); end
end