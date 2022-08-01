local t = {};
local varTypes = {["string"]="string", ["number"]="number"}
t.types = varTypes;

local function requestInput(message)
  term.clear();
  term.setCursorPos(1, 1);
  if (message ~= nil) then term.write(message); end
  local input = read();
  term.clear();
  return input;
end

local function getInput(varType, message)
  local input = ""
  while true do
    input = requestInput(message);
    if (varType == varTypes.number) then input = tonumber(input); end
    if (input ~= nil and (input ~= "" or input ~= " ")) then break end
  end
  return input;
end

function t.getInput(required, varType, message)
  if (required) then return getInput(varType, message); end
  return requestInput(message);
end

return t;