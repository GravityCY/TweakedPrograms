local tu = require("TableUtils");

local c = {};

function c.new(name, description, min, max)
  local cmd = {};
  cmd.name = name;
  cmd.description = description;
  cmd.min = min or 0;
  cmd.max = max or 0;

  function cmd.setArgRange(nmin, nmax)
    cmd.min = nmin;
    cmd.max = nmax;
  end

  function cmd.setDesc(ndesc)
    cmd.description = ndesc;
  end

  function cmd.setName(nname)
    cmd.name = nname;
  end

  function cmd.setFunction(fn)
    cmd.fn = fn;
  end

  return cmd;
end

local states = {};
states.TooManyArguments = 0;
states.TooLittleArguments = 1;
states.UnknownCommand = 2;
states.Success = 3;
states.NoArguments = 4;
c.states = states;

local errorMessages = {};
errorMessages[states.TooManyArguments] = "%s can only take %d arguments.";
errorMessages[states.TooLittleArguments] = "%s needs atleast %d arguments.";
errorMessages[states.UnknownCommand] = "Command %s does not exist.";
errorMessages[states.NoArguments] = "Enter something...";
c.errorMessages = errorMessages;

local commands = {};

local function printHelp()
  for name, command in pairs(commands) do
    print(("%s - %s"):format(name, command.description));
  end
end

local function getHelp()
  return c.get("help");
end

function c.get(name)
  return commands[name];
end

function c.add(command)
  commands[command.name] = command;
end

function c.getCommands()
  return commands;
end

function c.parse(inputTab)
  local cmdArg = inputTab[1];
  local cmd = commands[cmdArg];
  if (cmd ~= nil) then
    if (cmd.min == 0 and cmd.max == 0) then
      cmd.fn();
      return states.Success;
    elseif (#inputTab >= cmd.min) then
      if (#inputTab <= cmd.max) then
        cmd.fn(tu.range(inputTab, 2, 2 + cmd.max));
        return states.Success;
      end
      return states.TooManyArguments, errorMessages[states.TooManyArguments]:format(cmd.name, cmd.max);
    end
    return states.TooLittleArguments, errorMessages[states.TooLittleArguments]:format(cmd.name, cmd.min);
  end
  local cmdHelp = getHelp();
  if (cmdHelp ~= nil) then cmdHelp.fn(); end
  if (cmdArg ~= nil) then
    return states.UnknownCommand, errorMessages[states.UnknownCommand]:format(cmdArg);
  else
    return states.NoArguments, errorMessages[states.NoArguments];
  end
end

return c;