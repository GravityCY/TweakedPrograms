local m = {};

function m.wrap(mon)
  local pWrite = mon.write;
  
  function mon.print(str)
    local x, y = mon.getCursorPos();
    pWrite(str);
    mon.setCursorPos(1, y+1);
  end

  function mon.write(str)
    local newLine = str:find("\n");
    if (newLine) then 
      mon.print(str:sub(1, newLine - 1));
      if (newLine + 1 <= str:len()) then
        mon.write(str:sub(newLine + 1));
      end
    else pWrite(str); end
  end

  function mon.offsetY(offset)
    local x, y = mon.getCursorPos();
    mon.setCursorPos(x, y+(offset or 1));
  end

  function mon.offsetX(offset)
    local x, y = mon.getCursorPos();
    mon.setCursorPos(x+(offset or 1), y);
  end
  
  return mon;
end

return m;