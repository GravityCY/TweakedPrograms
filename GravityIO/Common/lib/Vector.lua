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

function Vector3.new(x, y, z)
  local v = {};
  v.x = 0;
  v.y = 0;
  v.z = 0;

  if (x ~= nil) then v.x = x; end
  if (y ~= nil) then v.y = y; end
  if (z ~= nil) then v.z = z; end

  function v.set(nx, ny, nz)
    if (nx ~= nil) then v.x = nx; end
    if (ny ~= nil) then v.y = ny; end
    if (nz ~= nil) then v.z = nz; end
  end

  function v.add(nx, ny, nz)
    if (nx ~= nil) then v.x = v.x + nx; end
    if (ny ~= nil) then v.y = v.y + ny; end
    if (nz ~= nil) then v.z = v.z + nz; end
  end

  function v.clone()
    return Vector3.new(v.x, v.y, v.z);
  end

  return v;
end

return Vector;