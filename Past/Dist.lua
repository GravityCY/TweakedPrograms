local Vector3 = {};

function Vector3.new(x, y, z)
  local t = {};
  t.x = x;
  t.y = y;
  t.z = z;
  return t;
end

function Vector3.abs(vector)
  return math.abs(vector.x), math.abs(vector.y), math.abs(vector.z);
end

local function tobool(obj, default)
  local t = type(obj);
  if (obj == nil) then return default; end
  if (t == "string") then
    if (obj == "true") then return true;
    elseif (obj == "false") then return false; end
  elseif(t == "number") then return obj ~= 0; end
end

local args = {...};

local doX = tobool(args[1], true);
local doY = tobool(args[2], false);
local doZ = tobool(args[3], true);

local px, py, pz = gps.locate();
if (not px) then print("Could not locate."); return end
local pvec = Vector3.new(px, py, pz);
print("Position 1 has been set.");
os.pullEvent("key");
local cx, cy, cz = gps.locate();
if (not cx) then print("Could not locate."); return end 
local cvec = Vector3.new(cx, cy, cz);
local diff = 0;
if (doX) then diff = diff + math.abs(pvec.x - cvec.x) end
if (doY) then diff = diff + math.abs(pvec.y - cvec.y) end
if (doZ) then diff = diff + math.abs(pvec.z - cvec.z) end
print("Position 2 has been set.");
print(diff);