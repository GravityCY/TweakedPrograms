local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local args = {...};

local ix, iy, iz = 0, 0, 0;
local ax, ai, az = 0, 0, 0;
local mx, my, mz = 0, 0, 0;
local iSlot = nil;

local up = true;
local right = true;
local isForward = true;
local goRight = true;
local away = true;

local diName = "occultism:stable_wormhole";

local function doRepeat(fn, times, ...)
  for i = 1, times do fn(...); end
end

local function setup()
  if (#args == 0) then
    write("Enter X (Exclusive): ");
    ix = tonumber(read());
    write("Enter Y (Inclusive): ");
    iy = tonumber(read());
    write("Enter Z (Inclusive): ");
    iz = tonumber(read());
  else
    ix = tonumber(args[1]);
    iy = tonumber(args[2]);
    iz = tonumber(args[3]);
  end
  ax, ay, az = math.abs(ix), math.abs(iy), math.abs(iz);
  if (iy < 0) then up = false; end
  if (iz < 0) then right = false; goRight = false end
end

local function hasDumpInventory()
  iSlot = tUtils.getSlot(diName);
  if (not iSlot) then
    print("Please insert a Wormhole for me to dump items.");
    error();
  end
end

local function turn(right)
  local side = sides.left;
  if (right) then side = sides.right end
  tUtils.turn(side);
end

local function vertical(up)
  local side = sides.down;
  if (up) then side = sides.up; end
  tUtils.goDig(side);
end

local function dumpInventory()
  turtle.select(tUtils.getSlot(diName));
  tUtils.turn(sides.back);
  tUtils.dig(sides.forward);
  tUtils.place(sides.forward);
  tUtils.dropAll(sides.forward);
  turtle.select(1);
  tUtils.dig(sides.forward);
  tUtils.turn(sides.back);
end

local function home()
  local tx,ty,tz = mx-1, -my, mz;
  if (not right) then tz = -tz; end
  if (not up) then ty = -ty; end
  if (isForward) then tx, tz = -tx, -tz; end
  print(tx,ty,tz);
  tUtils.goPos(tx, ty, tz);
  if (mz == 0) then
    if (not isForward) then
      tUtils.turn(sides.back);
    end
  else turn(right); end
  tUtils.go(sides.back);
  dumpInventory();
end

local function digVertical()
  if (my+1 < iy) then tUtils.dig(sides.up); end
  if (my-1 >= 0) then tUtils.dig(sides.down); end
end

local function moveMine()
  tUtils.goDig(sides.forward);
  digVertical();
end

local function corner()
  turn(goRight);
  moveMine();
  turn(goRight);
  goRight = not goRight;
  isForward = not isForward;
end

local function layer(times)
  doRepeat(tUtils.turn, 2, sides.right);
  doRepeat(vertical, times, up);
  digVertical();
  isForward = not isForward;
  away = not away;
end

local function xMove()
  local add = 1;
  if (not isForward) then add = -1; end
  mx = mx + add;
  moveMine();
end

local function yMove()
  local add = iy - my - 1;
  if (iy - my - 1 >= 3) then add = 3 end
  my = my + add;
  layer(add);
end

local function zMove()
  local add = -1;
  if (away) then add = 1; end
  print("Corner : " .. add);
  mz = mz + add;
  corner();
end

local function main()
  local limitX, limitY, limitZ = ax, ay, az;
  if (ay >= 3) then 
    limitY = math.ceil(ay / 3); 
    vertical(true);
    my = 1;
  end
  xMove();
  for y = 1, limitY do
    for z = 1, limitZ do
      for x = 1, limitX - 1 do
        xMove();
        if (tUtils.full()) then dumpInventory(); end
      end
      if (z ~= limitZ) then zMove(); end
    end
    if (y ~= limitY) then yMove(); end
  end
  home();
end

hasDumpInventory();
setup();
main();