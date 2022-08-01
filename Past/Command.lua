local c = {};
local alias = {};
local commands = {};

function c.new(id, description, names, onCommand)
  local command = {};
  command.id = id or "Command";
  command.description = description or "Decription";
  command.onCommand = onCommand;
  command.names = names or {};
  return command;
end

function c.register(command)
  if (commands[command.id]) then return false; end
  commands[command.id] = command;
  for _, name in ipairs(command.names) do alias[name] = command.id; end
  return true;
end

function c.list()
  local l = {};
  for _, command in pairs(commands) do l[#l+1] = command; end
  return l;
end

function c.all()
  return commands;
end

function c.get(name)
  local command = commands[name];
  if (command) then return command;
  else return commands[alias[name]]; end
end

function c.exists(name)
  return commands[name] ~= nil;
end

return c; 