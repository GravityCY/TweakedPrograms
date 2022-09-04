local BinaryFile = require("BinaryFile");
local Vector = require("Vector");
local Vector3 = Vector.Vector3;
local Vector2 = Vector.Vector2;

local termSize = Vector2.new(term.getSize());

local blobs = {};
local markers = {};

local cam = Vector2.new(0, 0);
local cx, cy = 0, 0;
local origin = Vector2.new(0, 0);
local gx, gy, gz = nil, nil, nil;
local focus = Vector2.new(-1, -1);
local fx, fy = -1, -1;

local sx, sz = 0, 0;

local doCenter = true;

local function newBlob(x, y)
  local b = {};
  b.icon = "X";
  b.name = nil;
  b.x, b.y = x, y;
  return b;
end

local function get2D(map, x, y)
  if (not map[x]) then map[x] = {}; end
  return map[x][y];
end

local function set2D(map, x, y, value)
  if (not map[x]) then map[x] = {}; end
  map[x][y] = value;
end

local function getBlob(vec)
  local blob = get2D(blobs, vec.x, vec.y);
  if (not blob) then blobs[vec.x][vec.y] = newBlob(vec.x, vec.y); end
  return blobs[vec.x][vec.y];
end

local function toScreen(vec)
  return Vector2.new(cam.x + math.ceil(termSize.x / 2) + vec.x, cam.y + math.ceil(termSize.y / 2) + vec.y);
end

local function toWorld(vec)
  return Vector2.new(vec.x - math.floor(termSize.x / 2) - cam.x, vec.y - math.floor(termSize.y / 2) - cam.y);
end

local function doDrawBlobs()
  local i = 1;
  for y = 1, termSize.y do
    for x = 1, termSize.x do
      local pos = Vector2.new(x, y);
      term.setCursorPos(pos.x, pos.y);
      local wp = toWorld(pos);
      if (wp.x ~= focus.x or wp.y ~= focus.y) then
        local blob = getBlob(wp.x, wp.y);
        local icon = blob.icon;
        term.write(icon);
      end
      i = i + 1;
    end
  end
end

local function toGrid(vec1, vec2)
  return Vector3.new(math.floor(vec1.x - vec2.x / 16), math.floor(vec1.y, vec2.y / 16));
end

local function hasMoved(nGrid)
  return nGrid.x ~= fx and nGrid.z ~= fz;
end

local function locate()
  return Vector3.new(gps.locate());
end

local function draw()
  term.setCursorPos(toScreen(focus.x, focus.y));
  term.write("_");
  doDrawBlobs();
end

local function load()
  local file = fs.open("/position.map", "rb");
  gx, gy, gz = file.readInt(), file.readInt();
  while true do
    local x = file.readInt();
    if (not x) then break end
    local y = file.readInt();
    local blob = getBlob(x, y);
    blob.name = file.readString();
    blob.icon = file.readString();
    set2D(markers, x, y, blob);
  end
  file.close();
end

local function save()
  local file = fs.open("/position.map", "wb");
  file.writeInt = function(int)
    if (not int) then return end
    file.write(string.pack("<i4", int));
  end 
  file.writeString = function(str)
    file.writeInt(#str);
    file.write(str);
  end
  file.writeInt(gx);
  file.writeInt(gy);
  file.writeInt(gz);
  for x, xTab in pairs(markers) do
    for y, marker in pairs(xTab) do
      file.writeInt(x);
      file.writeInt(y);
      file.writeString(marker.name);
      file.writeString(marker.icon);
    end
  end
  file.close();
end

local function MainThread()
  local sb = getBlob(0, 0);
  sb.icon = "S";
  while true do
    local pos = locate();
    if (pos.x == nil or pos.y == nil or pos.z == nil) then
      term.clear() 
      term.setCursorPos(1, 1);
      write("Couldn't Locate");
      return
    end
    term.clear();
    local nGrid = toGrid(pos, grid)
    local moved = hasMoved(nGrid);
    fx, fy = ngx, ngy;
    if (doCenter) then camcx, cy = -fx, -fy; end
    if (moved) then draw() end
    sleep(0.5);
  end
end

local function InputThread()
  while true do
    local event, a1, a2, a3, a4 = os.pullEvent();
    if (event == "mouse_click") then
      local btn, x, y = a1, a2, a3;
      local wx, wy = toWorld(x, y);
      local blob = getBlob(wx, wy);
      if (btn == 1) then
        doLoop = false;
        term.clear();
        term.setCursorPos(1, 1);
        write("Enter Name: ");
        blob.name = read();
        write("Enter Icon: " );
        blob.icon = read();
        set2D(markers, wx, wy, blob);
        doLoop = true;
        save();
      elseif (btn == 2) then
        doLoop = false;
        term.clear();
        term.setCursorPos(1, 1);
        if (blob.name) then write(blob.name);
        else write("Does not have a name...") end
        write("Press Any Key to Continue.");
        os.pullEvent("char");
        doLoop = true;
      elseif (btn == 3) then 
        set2D(markers, wx, wy, nil); 
        set2D(blobs, wx, wy, newBlob());
        save();
      end
    elseif (event == "key_up") then
      local key = a1;
      if (key == keys.left) then
        doCenter = false;
        cx = cx + 1;
      elseif (key == keys.right) then
        doCenter = false;
        cx = cx - 1;
      elseif (key == keys.up) then
        doCenter = false;
        cy = cy + 1;
      elseif (key == keys.down) then
        doCenter = false;
        cy = cy - 1;
      elseif (key == keys.l) then
        doLoop = false;
        term.clear();
        term.setCursorPos(1, 1);
        for x, xTab in pairs(markers) do
          for y, marker in pairs(xTab) do
            write(marker.name .. ", X: " .. gx + x * 16 .. ", Z: " .. gz + y * 16);
          end
        end
        write("Press Any Key to Continue.");
        os.pullEvent("char");
        doLoop = true;
      end
    end
  end
end

load();
if (gx == nil or gy == nil  or gz == nil ) then
  gx, gy, gz = gps.locate(); 
  if (gx == nil or gy == nil or gz == nil) then write("Could not Locate...") error() 
  else save(); end
end
parallel.waitForAll(MainThread, InputThread);