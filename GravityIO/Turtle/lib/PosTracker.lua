local t = {};
local directions = { px=0, pz=1, nx=2, nz=3 };
t.directions = directions;



local pos = Vector.new();
local facing = directions.px;

local function face(nface)
  local diff1 = (nface - facing) % 4;
  local diff2 = nface - facing - 4;
  local diff = diff2;
  if (math.abs(diff1) < math.abs(diff2)) then diff = diff1; end
  if (diff == 0) then return end

  local turns = math.abs(diff);
  local fn = nil;
  if (diff > 0) then
    fn = turtle.turnRight;
  elseif (diff < 0) then
    fn = turtle.turnLeft;
  end
  for i = 1, turns do fn(); end
  t.setFacing(nface);
end

t.face = face;

function t.forward()
  if (turtle.forward()) then
    local mx = 0;
    local mz = 0;
    if (facing == directions.px) then mx = 1; end
    if (facing == directions.nx) then mx = -1; end
    if (facing == directions.pz) then mz = 1; end
    if (facing == directions.nz) then mz = -1; end
    pos.add(mx, 0, mz);
  end
end

function t.back()
  if (turtle.back()) then
    local mx = 0;
    local mz = 0;
    if (facing == directions.px) then mx = -1; end
    if (facing == directions.nx) then mx = 1; end
    if (facing == directions.pz) then mz = -1; end
    if (facing == directions.nz) then mz = 1; end
    pos.add(mx, 0, mz);
  end
end

function t.goPos(gtx, gty, gtz)
  local dx = pos.x - gtx;
  local dy = pos.y - gty;
  local dz = pos.z - gtz;
  if (dx < 0) then face(directions.nx);
  elseif (dz > 0) then face(directions.px); end
  for x = 1, math.abs(dx) do t.forward(); end

  local vfn = nil;
  if (dy < 0) then vfn = t.down;
  elseif (dy > 0) then vfn = t.up; end
  for y = 1, math.abs(dy) do vfn(); end

  if (dz < 0) then face(directions.nz);
  elseif (dz > 0) then face(directions.pz); end
  for z = 1, math.abs(dz) do t.forward(); end
end

function t.up()
  if (turtle.up()) then
    pos.add(0, 1, 0);
  end
end

function t.down()
  if (turtle.down()) then
    pos.add(0, -1, 0);
  end
end

function t.right()
  turtle.turnRight();
  facing = facing + 1;
  if (facing == 4) then facing = directions.px; end
end

function t.left()
  turtle.turnLeft();
  facing = facing - 1;
  if (facing == -1) then facing = directions.nz; end
end

function t.setFacing(nfacing)
  facing = nfacing;
end

function t.getFacing()
  return facing;
end

function t.setPos(x, y, z)
  pos.set(x, y, z);
end

function t.getPos()
  return pos;
end

return t;