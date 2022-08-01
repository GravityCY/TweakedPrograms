local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local args = {...};

local x, y, z = 0, 0, 0;
local mx, my, mz = 0, 0, 0;

local iSlot = nil;
local isForward = true;

local diName = "occultism:stable_wormhole";

local function doRepeat(fn, times, ...)
  for i = 1, times do fn(...); end
end

local function getXYZ()
  if (#args == 0) then
    write("Enter X: ");
    x = tonumber(read());
    write("Enter Y: ");
    y = tonumber(read());
    write("Enter Z: ");
    z = tonumber(read());
  else
    x = tonumber(args[1]);
    y = tonumber(args[2]);
    z = tonumber(args[3]);
  end
end

local function checkInv()
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

local function dumpInventory()
  turtle.select(tUtils.getSlot(diName));
  tUtils.dig(sides.down);
  tUtils.place(sides.down);
  tUtils.dropAll(sides.down);
  turtle.select(1);
  tUtils.dig(sides.down);
end

local function home()
  if (isForward) then 
    tUtils.turn(sides.left);
    doRepeat(tUtils.goDig, mz, sides.forward);
    tUtils.turn(sides.left);
  else
    tUtils.turn(sides.right);
    doRepeat(tUtils.goDig, mz, sides.forward);
    tUtils.turn(sides.left);
  end
  doRepeat(tUtils.goDig, mx, sides.forward);
  tUtils.turn(sides.back);
  dumpInventory();
end

local function moveMine()
  tUtils.goDig(sides.forward);
  tUtils.dig(sides.up);
  tUtils.dig(sides.down);
end

local function xMove()
  if (isForward) then mx = mx + 1;
  else mx = mx - 1; end
end

local function yMove()
  my = my - 1;
end

local function zMove()
  mz = mz + 1;
end

local function corner()
  turn(isForward);
  moveMine();
  turn(isForward);
  isForward = not isForward;
end

local function layerDown()
  doRepeat(tUtils.turn, 2, sides.right);
  tUtils.goDig(sides.down);
  tUtils.dig(sides.down);
end

local function main()
  tUtils.dig(sides.up);
  tUtils.dig(sides.down);
  moveMine();
  xMove();
  for yNow = 1, y do
    for zNow = 1, z do
      for xNow = 1, x - 1 do
        if (tUtils.full()) then dumpInventory(); end
        moveMine();
        xMove();
      end
      if (zNow ~= z) then 
        corner(); 
        zMove();
      end
    end
    if (yNow ~= y) then 
      layerDown(); 
      yMove();
    end
  end
  home();
end

checkInv();
getXYZ();
main();