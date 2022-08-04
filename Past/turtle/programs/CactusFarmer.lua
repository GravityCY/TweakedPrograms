local tUtils = require("TurtleUtils");
local turn = tUtils.turn;
local go = tUtils.go;
local goDig = tUtils.goDig;
local dig = tUtils.dig;
local inspect = tUtils.inspect;

local side = sides.left;

local sleepTime = 60;

local sizeX = 9;
local sizeZ = 9;

local cactusGot = 0;

local function doRepeat(fn, times, ...)
  for i = 1, times do fn(...); end
end

local function goHome()
  local zIsEven = sizeZ % 2 == 0;
  if (zIsEven) then turn(sides.left);
  else
    turn(sides.back);
    doRepeat(go, sizeX - 1, sides.forward);
    turn(sides.left);
  end
  doRepeat(go, sizeZ - 1, sides.forward);
  turn(sides.left);
  doRepeat(go, 2, sides.back);
  doRepeat(go, 2, sides.down);
end

local function forward()
  go(sides.forward);
  local found, block = inspect(sides.down);
  if (found) then
    goDig(sides.down);
    dig(sides.down);
    go(sides.up);
    cactusGot = cactusGot + 2;
  end
end

local function corner()
  turn(side);
  forward();
  turn(side);
  if (side == sides.right) then side = sides.left
  else side = sides.right end
end

local function main()
  while true do
    cactusGot = 0;
    local sTime = os.clock();
    doRepeat(go, 2, sides.up);
    doRepeat(forward, 2);
    for zNow = 1, sizeZ do
      for xNow = 1, sizeX - 1 do forward(); end
      if (zNow ~= sizeZ) then corner(); end
    end
    goHome();
    local eTime = os.clock();
    write(string.format("Took %s seconds.", eTime - sTime));
    write(string.format("Got %s Cacti", cactusGot));
    write(string.format("Sleeping for %s seconds", sleepTime));
    sleep(sleepTime);
  end
end

main();
