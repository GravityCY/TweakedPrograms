local t = {};
local varTypes = {["string"]="string", ["number"]="number"}
t.types = varTypes;

local function getCenterX(str)
  local mx, my = term.getSize();
  return math.ceil(mx / 2 - str:len() / 2);
end

local function getCenterY(str, index, size)
  local mx, my = term.getSize();
  return math.ceil((index-1) + my / 2 - size / 2);
end

local function printCenterX(str)
  local mx, my = term.getCursorPos();
  term.setCursorPos(getCenterX(str), my);
  write(str);
end

local function printCenterXY(str, index, size)
  term.setCursorPos(getCenterX(str), getCenterY(str, index, size));
  write(str);
end

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

function t.select(list)
  local center = list.center or true;
  local header = list.header or "Select";
  local prefix = list.prefix or "> ";
  local postfix = list.postfix or "";
  local selections = list.selections;
  local size = #selections;
  local selected = 1;

  local function render()
    term.clear();
    term.setCursorPos(1, 1);
    printCenterX(header);
    for index, selection in pairs(selections) do 
      local str = selection;
      if (index == selected) then str = prefix .. str .. postfix; end
      if (center) then printCenterXY(str, index, size);
      else write(str); end
    end
    local mx, my = term.getSize();
    term.setCursorPos(1, my - 1);
    printCenterX("Move: Arrows, Select: Enter, Cancel: Backspace.")
  end

  local function increase(amount)
    selected = (selected + amount - 1) % size + 1;
    render();
  end

  render();
  while true do
    local _, key = os.pullEvent("key");
    if (key == keys.backspace) then term.clear(); term.setCursorPos(1, 1); return 0
    elseif (key == keys.enter) then
      term.clear();
      term.setCursorPos(1, 1);
      return selected;
    elseif (key == keys.up) then increase(1);
    elseif (key == keys.down) then increase(-1); end
  end
end

return t;