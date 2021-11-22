local sides = {};
sides[0], sides.right = "right", 0;
sides[1], sides.left = "left", 1;
sides[2], sides.back = "back", 2;
sides[3], sides.forward = "forward", 3;
sides[4], sides.down = "down", 4;
sides[5], sides.up = "up", 5;
local blacklist = {};
blacklist["computercraft:turtle_normal"] = true;
blacklist["computercraft:turtle_advanced"] = true;
blacklist["computercraft:computer_normal"] = true;
blacklist["computercraft:computer_advanced"] = true;

local goSides = { [sides.forward]=turtle.forward,
                 [sides.down]=turtle.down,
                 [sides.up]=turtle.up,
                 [sides.back]=turtle.back };

local turnSides = { [sides.right]=turtle.turnRight,
                    [sides.left]=turtle.turnLeft,
                    [sides.back]=function() turtle.turnRight(); turtle.turnRight(); end};

local digSides = { [sides.forward]=turtle.dig,
                  [sides.down]=turtle.digDown,
                  [sides.up]=turtle.digUp };

local placeSides = { [sides.forward]=turtle.place,
                     [sides.down]=turtle.placeDown,
                     [sides.up]=turtle.placeUp };

local inspectSides = { [sides.forward]=turtle.inspect,
                       [sides.down]=turtle.inspectDown,
                       [sides.up]=turtle.inspectUp };

local dropSides = { [sides.forward]=turtle.drop,
                    [sides.down]=turtle.dropDown,
                    [sides.up]=turtle.dropUp };

local suckSides = { [sides.forward]=turtle.suck,
                    [sides.up]=turtle.suckUp,
                    [sides.down]=turtle.suckDown };

local t = {};
t.sides = sides;
t.blacklist = blacklist;

local invSize = 16;

local getItemDetail = turtle.getItemDetail;

local function inBlacklist(side)
  local _, block = t.inspect(side);
  if (block) then return t.blacklist[block.name] ~= nil;
  else return false end
end

-- Will return a slot of an item based off ID
function t.getSlot(id)
  for slot = 1, invSize do
      local item = getItemDetail(slot);
      if (item and item.name == id) then return slot end
  end
end

-- Will return a slot of an item based off an item object
function t.getSlotTab(tab)
  for slot = 1, invSize do
      local item = getItemDetail(slot);
      if (item) then
          local same = false;
          for key, value in pairs(tab) do
              if (item[key] == value) then same = true; end
          end
          if (same) then return slot; end
      end
  end
end

-- Will count how much of an item there is
function t.count(id)
  local count = 0;
  for slot = 1, invSize do
    local item = turtle.getItemDetail(slot);
    if (item and item.name == id) then count = count + item.count end
  end
  return count;
end

-- Will return whether an ID is a variation of a turtle
function t.isTurtle(id)
  return (id == "computercraft:turtle_normal" or id == "computercraft:turtle_advanced");
end

-- Will select an item based off ID
function t.selectID(id)
  local s = t.getSlot(id);
  if (s) then return turtle.select(s); end
  return false;
end

-- Returns whether there are no completely empty slots left
function t.full()
  local emptySlot = false;
  for i = 1, invSize do
    if (not turtle.getItemDetail(i)) then emptySlot = true; break end
  end
  return not emptySlot;
end

function t.list(detail)
  local itemMap = {};
  for i = 1, invSize do
    local item = getItemDetail(i, detail);
    if (item) then itemMap[i] = item end
  end
  return itemMap
end

-- Will inspect block
function t.inspect(side)
  local fn = inspectSides[side];
  if (fn) then return fn(); end
end

-- Will drop an amount in the specified slot
function t.drop(slot, amount, side)
  turtle.select(slot);
  local fn = dropSides[side];
  if (fn) then return fn(amount); end
end

function t.dropRange(fromSlot, toSlot, amount, side)
  for i = fromSlot, toSlot do 
    if (getItemDetail(i)) then
      t.drop(i, amount, side); 
    end
  end
end

-- Will drop all items from a turtles inventory
function t.dropAll(side)
  for i = 1, invSize do
    local item = turtle.getItemDetail(i);
    if (item) then t.drop(i, 64, side); end
  end
end

-- Will suck
function t.suck(side)
  local fn = suckSides[side];
  if (fn) then return fn(); end
end

-- Will move the turtle
function t.go(side)
  local fn = goSides[side];
  if (fn) then return fn(); end
end

--[[
  Will go to a position relative to it's self
  5, 1, 2 means:
  (x) 5 times forward relative to it's current facing direction, 
  (y) 1 times up, 
  (z) 2 times to the right relative to it's facing direction [Will turn right once and then forward 2 times]

  -5, -1, -2 means:
  (x) 5 backward relative to it's current facing direction,
  (y) 1 times down,
  (z) 2 times to the left relative to it's facing direction [Will turn left once and then forward 2 times]
  
  Execution Flow: X then Y then Z meaning:
  it will always go forward or back first, then up or down, then right or left.
]]--
function t.goPos(ix, iy, iz)
  local frontSide = (ix > 0 and sides.forward) or sides.back;
  local vertSide = (iy > 0 and sides.up) or sides.down;
  local horizonSide = (iz > 0 and sides.right) or sides.left;
  for x=1, math.abs(ix) do
    t.go(frontSide);
  end
  for y=1, math.abs(iy) do
    t.go(vertSide);
  end
  if (iz ~= 0) then t.turn(horizonSide); end
  for z=1, math.abs(iz) do
    t.go(sides.forward);
  end
end

-- Will turn (supports sides.back)
function t.turn(side)
  local fn = turnSides[side];
  if (fn) then return fn(); end
end

-- Will dig
function t.dig(side)
  local fn = digSides[side];
  if (fn and not inBlacklist(side)) then return fn(); end
end

-- Will keep trying to dig and if failing waits
function t.digWait(side)
  while true do
    local success = t.dig(side);
    if (success) then break
    else sleep(0.25) end
  end
end

-- Will keep trying to move if failing and tries digging towards the moving direction
function t.goDig(side)
  while true do
    local goSuccess, goReason = t.go(side);
    if (goSuccess) then return goSuccess
    else
      local digSuccess, digReason = t.dig(side);
      -- If it failed to dig and it was bedrock
      if (digReason and digReason == "Unbreakable block detected") then return goSuccess, digReason end
    end
  end
end

-- Will keep trying to move if failing and will wait
function t.goWait(side)
  while true do
    local goSuccess, goReason = t.go(side);
    -- if it went forward
    if (goSuccess) then return goSuccess
    else sleep(0.5) end
  end
end

function t.place(side)
  local fn = placeSides[side];
  if (fn) then return fn(); end
end

-- Will keep trying to place a block and if failing will wait
function t.placeWait(side)
  while true do
    local success = t.place(side);
    if (success) then break
    else sleep(0.25); end
  end
end

return t;