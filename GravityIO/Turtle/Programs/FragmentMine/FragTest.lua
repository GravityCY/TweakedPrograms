local mx, my = 10, 5;
local workers = 9;

local split = math.ceil((mx * my) / workers);

term.clear();
term.setCursorPos(1, 1);

local function toPosition(index)
  return index % mx, math.ceil(index / mx);
end


local function loop()
  for i = 1, workers do
    for s = 1, split do
      local sx, sy = toPosition(s + split * (i - 1));
      if (sx <= mx and sy <= my) then
        if (sx == 0) then sx = mx; end
        if (sy == 0) then sy = my; end
        term.setCursorPos(sx, sy);
        term.write(tostring(i))
      end
    end
  end
end

loop();