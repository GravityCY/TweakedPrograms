local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local args = {...};

local x,y,z;

local iSlot;

local isForward = true;

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
  iSlot = tUtils.getSlot("minecraft:barrel");
  if (not iSlot) then
    print("Please insert a Barrel for me to dump items.");
    error();
  end
end

local function doRepeat(fn, times, ...)
  for i = 1, times do fn(...); end
end

local function turn(right)
  local side = sides.left;
  if (right) then side = sides.right end
  tUtils.turn(side);
end

local function home()
  local zIsEven = z % 2 == 0;
  local yIsEven = y % 2 == 0;
  doRepeat(tUtils.goDig, y - 1, sides.up);
  if (yIsEven) then
    doRepeat(tUtils.turn, 2, sides.right);
  else
    if (zIsEven) then tUtils.turn(sides.right);
    else
      doRepeat(tUtils.turn, 2, sides.right);
      doRepeat(tUtils.goDig, x - 1, sides.forward);
      tUtils.turn(sides.right);
    end
    doRepeat(tUtils.goDig, z - 1, sides.forward);
    tUtils.turn(sides.right);
  end
end

local function dumpInventory(cx, cy, cz)
  local distX = cx;
  if (not isForward) then distX = x - cx; end
  if (cz == 1) then tUtils.turn(sides.back);
  else 
    if (isForward) then
      tUtils.turn(sides.left);
      doRepeat(tUtils.goDig, z - cz + 1, sides.forward);
      tUtils.turn(sides.left);
    else
      tUtils.turn(sides.right);
      doRepeat(tUtils.goDig, z - cz + 1, sides.forward);
      tUtils.turn(sides.left);
    end
  end
  doRepeat(tUtils.goDig, distX, sides.forward);
  sleep(5);
end

local function moveMine()
  tUtils.goDig(sides.forward);
  tUtils.dig(sides.up);
  tUtils.dig(sides.down);
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
  turtle.select(iSlot);
  tUtils.place(sides.down);
  for yNow = 1, y do
    for zNow = 1, z do
      for xNow = 1, x do
        if (zNow == 1 and xNow == 4) then
          dumpInventory(xNow, yNow, zNow);
        end
        moveMine();
      end
      if (zNow ~= z) then corner(); end
    end
    if (yNow ~= y) then layerDown(); end
  end
  home();
end

checkInv();
getXYZ();
main();