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

local horizSides = {};
horizSides.back = 0;
horizSides.left = 1;
horizSides.forward = 2;
horizSides.right = 3;


local goSides = { [sides.forward]=turtle.forward,
                 [sides.down]=turtle.down,
                 [sides.up]=turtle.up,
                 [sides.back]=turtle.back };

local turnSides = { [sides.right]=turtle.turnRight,
                    [sides.left]=turtle.turnLeft,
                    [sides.back]=function() turtle.turnRight(); turtle.turnRight(); end};

local digSides = { [sides.forward]=turtle.dig,
                   [sides.down]=turtle.digDown,
                   [sides.up]=turtle.digUp,
                   [sides.back]=function() turtle.turnRight(); turtle.turnRight(); turtle.dig(); end};

local placeSides = { [sides.forward]=turtle.place,
                     [sides.down]=turtle.placeDown,
                     [sides.up]=turtle.placeUp };

local inspectSides = { [sides.forward]=turtle.inspect,
                       [sides.down]=turtle.inspectDown,
                       [sides.up]=turtle.inspectUp };
local compareSides = { [sides.forward]=turtle.compare,
                       [sides.down]=turtle.compareDown,
                       [sides.up]=turtle.compareUp };                    
local dropSides = { [sides.forward]=turtle.drop,
                    [sides.down]=turtle.dropDown,
                    [sides.up]=turtle.dropUp };

local suckSides = { [sides.forward]=turtle.suck,
                    [sides.up]=turtle.suckUp,
                    [sides.down]=turtle.suckDown };

local t = {};
t.sides = sides;
t.blacklist = blacklist;
t.facing = sides.forward;

local invSize = 16;

local getItemDetail = turtle.getItemDetail;

local function inBlacklist(side)
  local _, block = t.inspect(side);
  return block ~= nil and t.blacklist[block.name] ~= nil;
end

local function diff(prev, new)
  for i = 1, invSize do
    local pi = prev[i];
    local ni = new[i];
    if (not pi and ni) then return i end
    if ((pi and ni) and pi.count < ni.count) then return i end
  end
end

function t.setFacing(side)
  t.facing = side;
end

function t.getFacing()
  return t.facing;
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

-- Will return any slot that isn't empty
function t.getAnySlot()
  for i = 1, invSize do
    local item = getItemDetail(i);
    if (item) then return i end
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
  local item = t.getSelectedItem();
  if (item ~= nil and item.name == id) then return end
  local s = t.getSlot(id);
  if (s) then return turtle.select(s); end
  return false;
end

function t.getSelectedItem()
  return turtle.getItemDetail(turtle.getSelectedSlot());
end

function t.selectItem(item, detail)
  for i = 1, invSize do
    local tItem = turtle.getItemDetail(i, detail);
    for key, value in pairs(item) do
      if (tItem) then
        
      end
    end
  end
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
  for i = 1, invSize do itemMap[i] = getItemDetail(i, detail); end
  return itemMap
end

-- Will inspect block
function t.inspect(side)
  local fn = inspectSides[side];
  if (fn) then return fn(); end
end

function t.compare(side)
  local fn = compareSides[side];
  if (fn) then return fn(); end
end

-- Will drop an amount in the specified slot
function t.drop(slot, amount, side)
  slot = slot or turtle.getSelectedSlot();
  amount = amount or 64;
  side = side or sides.forward;
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
function t.dropAll(side, blacklist)
  blacklist = blacklist or {};
  for i = 1, invSize do
    local item = turtle.getItemDetail(i);
    if (item ~= nil and blacklist[item.name] == nil) then t.drop(i, 64, side); end
  end
end

-- Will suck
function t.suck(side, getSlot)
  getSlot = getSlot or false;
  local fn = suckSides[side];
  if (fn) then 
    local props = nil;
    local slot = nil;
    if (getSlot) then 
      local prev = t.list();
      props = {fn()};
      local new = t.list();
      slot = diff(prev, new);
    else props = {fn()}; end
    if (props[1]) then return table.unpack(props), slot;
    else return table.unpack(props); end
  end
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
function t.goPos(ix, iy, iz, onFail)
  local frontSide = (ix > 0 and sides.forward) or sides.back;
  local vertSide = (iy > 0 and sides.up) or sides.down;
  local horizonSide = (iz > 0 and sides.right) or sides.left;
  for x=1, math.abs(ix) do
    if (not t.go(frontSide)) then
      if (onFail ~= nil) then onFail(frontSide) end
    end
  end
  for y=1, math.abs(iy) do
    if (not t.go(vertSide)) then 
      if (onFail ~= nil) then onFail(vertSide); end
    end
  end
  if (iz ~= 0) then t.turn(horizonSide); end
  for z=1, math.abs(iz) do
    if (not t.go(sides.forward)) then 
      if (onFail ~= nil) then onFail(sides.forward); end
    end
  end
end

-- Will turn (supports sides.back)
function t.turn(side)
  local fn = turnSides[side];
  if (fn) then
    return fn();
  end
end

-- Will dig
function t.dig(side, getSlot)
  getSlot = getSlot or false;
  local fn = digSides[side];
  if (fn and not inBlacklist(side)) then 
    local props = nil;
    local slot = nil;
    if (getSlot) then 
      local prev = t.list();
      props = {fn()};
      local new = t.list();
      slot = diff(prev, new);
    else props = {fn()}; end
    if (props[1]) then return table.unpack(props), slot
    else return table.unpack(props); end
  end
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

function t.placeDig(side)
  while true do
    local success = t.place(side);
    if (success) then break
    else t.dig(side); end
  end
end

-- Will keep trying to place a block and if failing will wait
function t.placeWait(side)
  while true do
    local success = t.place(side);
    if (success) then break
    else sleep(0.25); end
  end
end

function t.placeID(side, id)
  t.selectID(id);
  return t.place(side);
end

function t.isFluid(side)
  local found, block = t.inspect(side);
  return found and block.name == "minecraft:lava" or block.name == "minecraft:water";
end

function t.isBlock(side)
  local found, block = t.inspect(side);
  return found and block.name ~= "minecraft:lava" and block.name ~= "minecraft:water";
end

return t;