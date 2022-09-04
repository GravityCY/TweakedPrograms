local t = {}
t.savePath = "/data/todos";
t.loadPath = "/data/todos";

local todos = {};

local function append(title, description)
  local file = fs.open(t.savePath, "a");
  file.write(title .. "\n");
  file.write(description .. "\n");
  file.close();
end

local function Todo(title, description)
  return {title=title, description=description};
end

function t.exists(title) 
  return todos[title] ~= nil;
end

function t.add(title, description)
  if (t.exists(title)) then return false; end
  todos[title] = description;
  append(title, description);
end

function t.remove(title)
  if (not t.exists(title)) then return false; end
  todos[title] = nil;
  t.save();
  return true;
end

function t.edit(title, newTitle, newDescription)
  if (not t.exists(title)) then return false end
  t.remove(title)
  todos[newTitle] = newDescription;
  t.save();
  return true;
end

function t.save()
  local file = fs.open(t.savePath, "w");
  for title, content in pairs(todos) do
    file.write(title .. "\n");
    file.write(content .. "\n");
  end
  file.close();
end

function t.load()
  local file = fs.open(t.loadPath, "r");
  if (file == nil) then return end
  while true do
    local line = file.readLine();
    if (line == nil) then break end
    local title, description = line, file.readLine();
    todos[title] = description;
  end
  file.close();
end

function t.list()
  local tl = {};
  for title, desc in pairs(todos) do
    table.insert(tl, Todo(title, desc));
  end
  return tl;
end

return t;