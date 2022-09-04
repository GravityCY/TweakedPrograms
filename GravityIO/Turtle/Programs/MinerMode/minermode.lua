local bt = require("bt");
local bf = require("binaryfile");
local sides = bt.sides;

local spacing = 5;
local length = 8;
local width = 3;

local position = 1;
local branch = 1;

local allowedFuel = 1000;

local isForward = true;

local function doRep(fn, times, ...)
  for i = 1, times do fn(...); end
end

local function getDistance(tempBranch)
  return math.abs(tempBranch - position) * (width + spacing);
end

local function goDig()
  bt.goDig(sides.forward);
  bt.dig(sides.up);
  bt.dig(sides.down);
end

local function turn(right)
  if (right) then turtle.turnRight();
  else turtle.turnLeft(); end
end

local function toBranch()
  doRep(bt.goDig, getDistance(branch), sides.forward);
  bt.turn(sides.left);
  bt.goDig(sides.forward);
  position = branch;
end

local function toShaft()
  if (isForward) then
    bt.turn(sides.left);
    doRep(bt.goDig, width - 1, sides.forward);
    bt.turn(sides.left);
    doRep(bt.goDig, length + 1, sides.forward);
  else
    bt.turn(sides.right);
    doRep(bt.goDig, width - 1, sides.forward);
    bt.turn(sides.left);
    doRep(bt.goDig, 2, sides.forward)
  end
  isForward = true;
  bt.turn(sides.left);
end

local function setBranch(value)
  branch = value;
  local sf = bf.open("minermode.save", "w");
  sf.writeByte(branch);
  sf.close();
end

local function digBranch()
  for x = 1, width do
    if (x == 1) then doRep(goDig, length);
    else doRep(goDig, length - 1); end
    if (x ~= width) then
      turn(isForward)
      goDig()
      turn(isForward)
      isForward = not isForward;
    end
  end
end

local function digBranches()
  digBranch();
  toShaft();
  doRep(bt.goDig, width - 1, sides.forward);
  bt.turn(sides.right);
  bt.goDig(sides.forward);
  digBranch();
  toShaft();
  doRep(bt.goDig, width - 1, sides.forward);
  bt.turn(sides.back);
  setBranch(branch + 1);
end

local function toHome()
  local lowSpace = bt.occupied() > 8;
  local lowFuel = turtle.getFuelLevel() < allowedFuel;
  if (lowSpace or lowFuel) then
    bt.turn(sides.back);
    doRep(bt.goDig, getDistance(1) + 11, sides.forward);
    if (lowSpace) then
      bt.turn(sides.right);
      doRep(bt.goDig, 6, sides.forward);
      bt.dropAll(sides.forward);
      bt.turn(sides.back);
      doRep(bt.goDig, 6, sides.forward);
      bt.turn(sides.right);
    end
    if (lowFuel) then
      bt.turn(sides.left);
      doRep(bt.goDig, 6, sides.forward);
      turtle.select(bt.empty());
      turtle.suck(1);
      turtle.refuel();
      turtle.down();
      turtle.drop();
      turtle.up();
      bt.turn(sides.back);
      doRep(bt.goDig, 6, sides.forward);
      bt.turn(sides.left);
    end
    bt.turn(sides.back);
    doRep(bt.goDig, 11, sides.forward);
    position = 1;
  end
end

local function main()
  local sf = bf.open("minermode.save", "r");
  turtle.select(1);
  doRep(bt.goDig, 6, sides.forward);
  bt.turn(sides.left);
  doRep(bt.goDig, 11, sides.forward);
  if (sf ~= nil) then
    branch = sf.readByte();
    sf.close();
  end
  while true do
    toBranch();
    digBranches();
    toHome();
  end
end

local function ui()
  while true do
    term.clear();
    term.setCursorPos(1, 1);
    print("Current Branch: " .. branch);
    print("Branch Length: " .. length);
    print("Branch Width: " .. width);
    print("Branch Spacing: " .. spacing);
    print("Fuel Level: " .. turtle.getFuelLevel());
    sleep(1);
  end
end

parallel.waitForAny(main, ui);