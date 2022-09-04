local m = {};

function m.getCenterX(str)
  local mx, my = term.getSize();
  return math.ceil(mx / 2 - str:len() / 2);
end

function m.getCenterY(str, index, size)
  local mx, my = term.getSize();
  return math.ceil((index-1) + my / 2 - size / 2);
end

function m.wrap(mon)
  local pWrite = mon.write;
  mon.mx, mon.my = mon.getSize();
  
  function mon.print(str)
    local x, y = mon.getCursorPos();
    pWrite(str);
    mon.setCursorPos(1, y + 1);
  end

  function mon.write(str)
    str = tostring(str);
    local strLen = #str;
    local newLine = str:find("\n");
    if (newLine) then 
      mon.print(str:sub(1, newLine - 1));
      if (newLine + 1 <= strLen) then
        mon.write(str:sub(newLine + 1));
      end
    else pWrite(str); end
  end

  function mon.zero()
    mon.setCursorPos(1, 1);
  end

  function mon.offsetY(offset)
    offset = offset or 1;
    local x, y = mon.getCursorPos();
    mon.setCursorPos(x, y+offset);
  end

  function mon.offsetX(offset)
    offset = offset or 1;
    local x, y = mon.getCursorPos();
    mon.setCursorPos(x+offset, y);
  end
  
  return mon;
end

function m.wrapList(mons)
  local wt = {};
  for i, mon in ipairs(mons) do
    wt[i] = m.wrap(mon);
  end
  return wt;
end

return m;