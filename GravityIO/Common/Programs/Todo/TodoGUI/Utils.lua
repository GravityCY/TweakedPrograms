local t = {};

local function getAverage(a, b)
  return (a + b) / 2;
end

local function getCenterX(x, mx, str)
  local cx = getAverage(x, mx);
  return cx - #str / 2;
end

function t.printCenterX(x, mx, y, str)
  term.setCursorPos(getCenterX(x, mx, str), y);
  print(str);
end

function t.printCenterY(x, y, my, str)
  term.setCursorPos(x, getAverage(y, my));
  print(str);
end

function t.printCenterXY(x, mx, y, my, str)
  term.setCursorPos(getCenterX(x, mx, str), getAverage(y, my));
  print(str);
end

return t;