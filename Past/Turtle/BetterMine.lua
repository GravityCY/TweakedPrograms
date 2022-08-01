local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local args = {...};

local ix, iz = 0, 0;
local ax, az = 0, 0;
local mx, mz = 0, 0;
local iSlot = nil;
local doReturn = true;
local xInclusive = false;

local right = true;
local isForward = true;
local goRight = true;
local away = true;

local function doRepeat(fn, times, ...)
  for i = 1, times do fn(...); end
end

local function requestInput(request)
  write(request);
  return read();
end

local function setup()
  ix, iz, doReturn, xInclusive = args[1], args[2], args[3], args[4];
  if (ix == nil) then ix = requestInput("Enter X (Exclusive): "); end
  if (iz == nil) then iz = requestInput("Enter Z (Inclusive): "); end
  if (doReturn == nil) then doReturn = requestInput("Should Return (True/False): "); end
  ix, iz, doReturn, xInclusive = tonumber(ix), tonumber(iz), doReturn:lower() == "true", (xInclusive ~= nil and xInclusive:lower() == "true");
  ax, az = math.abs(ix), math.abs(iz);
  if (not xInclusive) then ax = ax - 1; end
  if (iz < 0) then right = false; goRight = false end
end

local function turn(right)
  local side = sides.left;
  if (right) then side = sides.right end
  tUtils.turn(side);
end

local function home()
  local tx, tz = mx - 1, mz;
  if (not right) then tz = -tz; end
  if (isForward) then tx, tz = -tx, -tz; end
  tUtils.goPos(tx, 0, tz);
  if (mz == 0) then
    if (not isForward) then
      tUtils.turn(sides.back);
    end
  else turn(right); end
  tUtils.go(sides.back);
end

local function moveMine()
  tUtils.goDig(sides.forward);
  tUtils.dig(sides.up);
  tUtils.dig(sides.down);
end

local function corner()
  turn(goRight);
  moveMine();
  turn(goRight);
  goRight = not goRight;
  isForward = not isForward;
end

local function xMove()
  local add = 1;
  if (not isForward) then add = -1; end
  mx = mx + add;
  moveMine();
end

local function zMove()
  local add = -1;
  if (away) then add = 1; end
  mz = mz + add;
  corner();
end

local function main()
  if (not xInclusive) then xMove(); end
  for z = 1, az do
    for x = 1, ax do xMove(); end
    if (z ~= az) then zMove(); end
  end
  if (doReturn) then home(); end
end

setup();
main();