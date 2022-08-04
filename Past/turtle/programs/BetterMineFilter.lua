local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local args = {...};

local ix, iz = 0, 0;
local ax, az = 0, 0;
local mx, mz = 0, 0;
local iSlot = nil;
local doReturn = true;

local right = true;
local isForward = true;
local goRight = true;
local away = true;

tUtils.blacklist["minecraft:coal_ore"] = true;
tUtils.blacklist["minecraft:iron_ore"] = true;
tUtils.blacklist["minecraft:deepslate_iron_ore"] = true;
tUtils.blacklist["minecraft:gold_ore"] = true;
tUtils.blacklist["minecraft:deepslate_gold_ore"] = true;
tUtils.blacklist["minecraft:diamond_ore"] = true;
tUtils.blacklist["minecraft:deepslate_diamond_ore"] = true;
tUtils.blacklist["minecraft:lapis_ore"] = true;
tUtils.blacklist["minecraft:deepslate_lapis_ore"] = true;

local function doRepeat(fn, times, ...)
  for i = 1, times do fn(...); end
end

local function requestInput(request)
  write(request);
  return read();
end

local function setup()
  ix, iz, doReturn = args[1], args[2], args[3];
  if (not ix) then ix = requestInput("Enter X (Exclusive): "); end
  if (not iz) then iz = requestInput("Enter Z (Inclusive): "); end
  if (not doReturn) then doReturn = requestInput("Should Return (True/False): "); end
  ix, iz, doReturn = tonumber(ix), tonumber(iz), doReturn:lower() == "true";
  ax, az = math.abs(ix), math.abs(iz);
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
  xMove();
  for z = 1, az do
    for x = 1, ax - 1 do xMove(); end
    if (z ~= az) then zMove(); end
  end
  if (doReturn) then home(); end
end

setup();
main();