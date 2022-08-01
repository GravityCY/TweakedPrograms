local t = {};

function t.open(path, mode)
  local f = fs.open(path, mode .. "b");
  if (f == nil) then return end
  return t.wrap(f);
end

function t.wrap(f)
  if (f == nil) then return end
  if (f.read ~= nil) then
    function f.readByte()
      return f.read();
    end

    function f.readShort()
      return string.unpack("<h", f.read(2));
    end
    
    function f.readInt()
      return string.unpack("<i4", f.read(4));
    end
    
    function f.readString()
      return f.read(f.readInt());
    end
  elseif (f.write ~= nil) then
    function f.writeByte(byte)
      return f.write(byte);
    end

    function f.writeShort(short)
      return f.write(string.pack("<h", short));
    end

    function f.writeInt(int)
      return f.write(string.pack("<i4", int))
    end

    function f.writeString(string)
      f.writeInt(#string)
      return f.write(string);
    end
  end
  return f;
end

return t;