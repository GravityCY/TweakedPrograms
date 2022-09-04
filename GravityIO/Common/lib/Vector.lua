local Vector = {};

local Vector2 = {};
local Vector3 = {};

Vector.Vector2 = Vector2;
Vector.Vector3 = Vector3;

function Vector2.new(x, y)
  local t = {};
  t.x = x;
  t.y = y;
  return t;
end

function Vector2.abs(vector)
  return Vector2.new(math.abs(vector.x), math.abs(vector.y));
end

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

return Vector;