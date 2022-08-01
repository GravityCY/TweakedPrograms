local t = {};

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
  print(str);
end

local function printCenterXY(str, index, size)
  term.setCursorPos(getCenterX(str), getCenterY(str, index, size));
  print(str);
end

local function printAll(strs) 
  for index, str in pairs(strs) do
    print(str);
  end
end

function t.select(list)
  local center = list.center or true;
  local header = list.header or "Select";
  local prefix = list.prefix or "> ";
  local postfix = list.postfix or "";
  local preSpaces = (" "):rep(prefix:len()/2);
  local postSpaces = (" "):rep(postfix:len()/2);
  local selections = list.selections;
  local size = #selections;
  local prev = 0;
  local selected = 1;


  local function increase(amount)
    prev = selected;
    selected = selected + amount;
    if (selected > size) then selected = 1; end
    if (selected < 1) then selected = size; end
  end

  local function select()
    return selected;
  end

  local function update()
    if (prev == selected) then return end
    term.clear();
    term.setCursorPos(1, 1);
    printCenterX(header);
    for index, selection in pairs(selections) do 
      local str = selection;
      if (index == selected) then str = prefix .. str .. postfix; end
      if (center) then printCenterXY(str, index, size);
      else print(str); end
    end
    local mx, my = term.getSize();
    term.setCursorPos(1, my - 1);
    printCenterX("Move: Arrows, Select: Enter, Cancel: Backspace.")
  end

  local cb = { [keys.enter]=select,
               [keys.up]=function() increase(-1) end,
               [keys.down]=function() increase(1) end };

  update();
  while true do
    local event, key = os.pullEvent("key");
    if (key == keys.backspace) then term.clear(); term.setCursorPos(1, 1); break end
    local fn = cb[key];
    if (fn) then 
      local res = fn();
      update();
      if (res) then 
        term.clear();
        term.setCursorPos(1, 1);
        return res 
      end
    end
  end
end

return t;