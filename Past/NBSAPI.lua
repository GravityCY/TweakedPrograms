local nbs = {};

local instrumentNames = { "harp", "bass", "basedrum",
              "snare", "hat", "guitar",
              "flute", "bell", "chime",
              "xylophone", "iron_xylophone",
              "cow_bell", "didgeridoo", "bit",
              "banjo", "pling" };

              
local function open(filePath, mode)
  local file = fs.open(filePath, mode);
  if (mode == "rb") then
    function file.readByte()
      return file.read();
    end

    function file.readShort()
      return string.unpack("<h", file.read(2));
    end
    
    function file.readInt()
      return string.unpack("<i4", file.read(4));
    end
    
    function file.readString(length)
      return file.read(length);
    end
  end
  return file;
end

local function getTickColumn(handle)
  local column = { notes = {} };
  local tickJumps = handle.readShort();
  if (tickJumps ~= 0) then
    while true do
      local note = {};
      local layerJumps = handle.readShort();
      if (layerJumps == 0) then break end
      note.instrument = instrumentNames[handle.read() + 1];
      note.key = handle.read() - 33;
      note.volume = handle.read();
      note.stereo = handle.read();
      note.pitch = handle.readShort();
      column.notes[#column.notes + 1] = note;
    end
  end
  column.nextTick = tickJumps;
  return column;
end

function nbs.play(song, speaker, volume)
  if (song.columns) then
    for _, column in ipairs(song.columns) do
      for _, note in ipairs(column.notes) do
        speaker.playNote(note.instrument, volume or note.volume, note.key);
      end
      sleep(column.nextTick * 1 / song.tempo);
    end
    return true;
  else return false; end
end

local function newSong()
  local song = {};
  function song.play(speaker, volume)
    nbs.play(song, speaker, volume);
  end
  return song;
end

function nbs.load(filePath)
  local h = open(filePath, "rb");
  local byte = h.read() + h.read();
  local song = newSong();
  if (byte == 0) then
    h.read();
    h.read();
    song.length = h.readShort();
    h.readShort();
    song.name = h.readString(h.readInt());
    song.author = h.readString(h.readInt());
    song.originalAuthor = h.readString(h.readInt());
    song.desc = h.readString(h.readInt());
    song.tempo = h.readShort() / 100;
    h.read(23);
    song.midiName = h.readString(h.readInt());
    h.read(4)
    local columns = {};
    while true do
      local column = getTickColumn(h);
      if (#column.notes == 0) then break end
      columns[#columns + 1] = column;
    end
    song.columns = columns;
  else h.close() return end
  h.close();
  return song;
end

return nbs;