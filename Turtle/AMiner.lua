local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local args = {...};

local ix, iy, iz = 0, 0, 0;
local mx, my, mz = 0, 0, 0;
local iSlot = nil;

local up = true;
local right = true;
local isForward = true;
local goRight = true;

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
  if (mz ~= 0) then turn(right); end
  if (my % 2 ~= 0) then tUtils.turn(sides.back); end
  tUtils.go(sides.back);
  dumpInventory();
end

local function moveMine()
  tUtils.goDig(sides.forward);
end

local function corner()
  turn(goRight);
  moveMine();
  turn(goRight);
  goRight = not goRight;
  isForward = not isForward;
end

local function layer()
  doRepeat(tUtils.turn, 2, sides.right);
  vertical(up);
  isForward = not isForward;
end

local function xMove()
  if (isForward) then mx = mx + 1;
  else mx = mx - 1; end
  moveMine();
end

local function yMove()
  local add = 1;
  my = my + add;
  layer();
end

local function zMove()
  local add = (my % 2 ~= 0 and -1) or 1;
  mz = mz + add;
  corner();
end

local function main()
  local absx, absy, absz = math.abs(ix), math.abs(iy), math.abs(iz);
  xMove();
  for y = 1, absy do
    for z = 1, absz do
      for x = 1, absx - 1 do
        if (tUtils.full()) then dumpInventory(); end
        xMove();
      end
      if (z ~= absz) then zMove(); end
    end
    if (y ~= absy) then yMove(); end
  end
  home();
end

hasDumpInventory();
setup();
main();