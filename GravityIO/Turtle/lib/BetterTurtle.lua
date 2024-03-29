local t = {};

local Vector3 = require("Vector").Vector3;

local sides = {};
sides[0], sides.forward = "forward", 0;
sides[1], sides.right = "right", 1;
sides[2], sides.back = "back", 2;
sides[3], sides.left = "left", 3;
sides[4], sides.up = "up", 4;
sides[5], sides.down = "down", 5;

local directions = {};
directions[0], directions.px = "+x", 0;
directions[1], directions.pz = "+z", 1;
directions[2], directions.nx = "-x", 2;
directions[3], directions.nz = "-z", 3;

local hsides = {};
hsides[sides.left] = -1;
hsides[sides.back] = 2;
hsides[sides.right] = 1;

local blacklist = {};
blacklist["computercraft:turtle_normal"] = true;
blacklist["computercraft:turtle_advanced"] = true;
blacklist["computercraft:computer_normal"] = true;
blacklist["computercraft:computer_advanced"] = true;

local equip = {};
equip[sides.left] = nil;
equip[sides.right] = nil;

t.directions = directions;
t.sides = sides;
t.blacklist = blacklist;

local facing = directions.px;
local pos = Vector3.new();
local hasGPS = gps.locate() ~= nil;

local invSize = 16;

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

local equipSides = { [sides.left]=turtle.equipLeft,
                     [sides.right]=turtle.equipRight};

local function inBlacklist(id)
  return t.blacklist[id] ~= nil;
end

local function getDiff(prev, new)
  for i = 1, invSize do
    local pi = prev[i];
    local ni = new[i];
    if (not pi and ni) then return i end
    if ((pi and ni) and pi.count < ni.count) then return i end
  end
end

-- 3 -> 2
function t.face(nface)
  local diff = nface - facing;
  if (nface == 3 and facing == 0) then diff = -1; end
  if (nface == 0 and facing == 3) then diff = 1; end
  if (diff == 0) then return end
  local turns = math.abs(diff);
  local side = nil;
  if (diff > 0) then side = sides.right;
  elseif (diff < 0) then side = sides.left; end
  for i = 1, turns do t.turn(side); end
end

-- Will return a slot of an item based off ID
function t.getSlot(id)
  for slot = 1, invSize do
      local item = turtle.getItemDetail(slot);
      if (item and item.name == id) then return slot end
  end
end

-- Will return a slot of an item based off an item object
function t.getSlotTab(tab)
  for slot = 1, invSize do
      local item = turtle.getItemDetail(slot);
      if (item) then
          local same = false;
          for key, value in pairs(tab) do
              if (item[key] == value) then same = true;
              else same = false; break end
          end
          if (same) then return slot; end
      end
  end
end

-- Will return any slot that isn't empty
function t.getAnySlot()
  for i = 1, invSize do
    local item = turtle.getItemDetail(i);
    if (item ~= nil) then return i end
  end
end

-- Will return any slot that is empty
function t.getEmpty()
  for i = 1, invSize do
    local item = turtle.getItemDetail(i);
    if (item == nil) then return i; end
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
  if (item ~= nil and item.name == id) then return true end
  local s = t.getSlot(id);
  return s ~= nil and turtle.select(s);
end

function t.getSelectedItem()
  return turtle.getItemDetail(turtle.getSelectedSlot());
end

-- Returns whether there are no completely empty slots left
function t.isFull()
  local emptySlot = false;
  for i = 1, invSize do
    if (turtle.getItemDetail(i) == nil) then emptySlot = true; break end
  end
  return not emptySlot;
end

function t.list(detail)
  local itemMap = {};
  for i = 1, invSize do itemMap[i] = turtle.getItemDetail(i, detail); end
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
    if (turtle.getItemDetail(i)) then
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
      slot = getDiff(prev, new);
    else props = {fn()}; end
    if (props[1]) then return table.unpack(props), slot;
    else return table.unpack(props); end
  end
end

-- If Facing Z+ and want to go back I want to do Z-
-- Will move the turtle
function t.go(side)
  local fn = goSides[side];
  if (fn ~= nil) then
    local success, failReason = fn();
    if (success) then
      if (side == sides.forward) then
        local mx = 0;
        local mz = 0;
        if (facing == directions.px) then mx = 1; end
        if (facing == directions.nx) then mx = -1; end
        if (facing == directions.pz) then mz = 1; end
        if (facing == directions.nz) then mz = -1; end
        pos.add(mx, 0, mz);
      elseif (side == sides.back) then
        local mx = 0;
        local mz = 0;
        if (facing == directions.px) then mx = -1; end
        if (facing == directions.nx) then mx = 1; end
        if (facing == directions.pz) then mz = -1; end
        if (facing == directions.nz) then mz = 1; end
        pos.add(mx, 0, mz);
      elseif (side == sides.up) then
        pos.add(0, 1, 0);
      elseif (side == sides.down) then
        pos.add(0, -1, 0);
      end
    end
    return success, failReason;
  end
end

function t.getFacing()
  return facing;
end

function t.setFacing(new)
  facing = new;
end

function t.getPos()
  return pos.clone();
end

function t.setPos(x, y, z)
  pos.set(x, y, z);
end

function t.goPos(gtx, gty, gtz)
  local dx = gtx - pos.x;
  local dy = gty - pos.y;
  local dz = gtz - pos.z;
  if (dx > 0) then t.face(directions.px)
  elseif (dx < 0) then t.face(directions.nx); end
  for x = 1, math.abs(dx) do t.go(sides.forward); end

  local vs = nil;
  if (dy < 0) then vs = sides.down;
  elseif (dy > 0) then vs = sides.up; end
  for y = 1, math.abs(dy) do t.go(vs); end

  if (dz < 0) then t.face(directions.nz);
  elseif (dz > 0) then t.face(directions.pz); end
  for z = 1, math.abs(dz) do t.go(sides.forward); end
end

-- Will turn (supports sides.back)
function t.turn(side)
  local fn = turnSides[side];
  if (fn) then
    local new = (facing + hsides[side]) % 4;
    t.setFacing(new)
    return fn();
  end
end

-- Will dig
function t.dig(side, getSlot)
  local exists, block = t.inspect(side);
  if (not exists) then return false, "nothing to dig"; end

  if (getSlot == nil) then getSlot = false; end

  local fn = digSides[side];
  if (fn ~= nil and not inBlacklist(block.name)) then
    local props = nil;
    local slot = nil;
    if (getSlot) then 
      local prev = t.list();
      props = {fn()};
      local new = t.list();
      slot = getDiff(prev, new);
    else props = {fn()}; end
    if (props[1]) then return table.unpack(props), slot
    else return table.unpack(props); end
  end
end

function t.till(side)
  local exists = t.inspect(side);
  if (exists) then return false, "block in the way"; end
  local fn = digSides[side];
  if (fn ~= nil) then fn(); end
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
      if (digReason ~= nil and digReason == "Unbreakable block detected") then return goSuccess, digReason end
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
  if (turtle.getItemDetail() == nil) then return false end
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
  return t.selectID(id) and t.place(side);
end

function t.isFluid(side)
  local found, block = t.inspect(side);
  return found and block.state ~= nil and block.state.level ~= nil;
end

function t.isBlock(side)
  return not t.isFluid(side);
end

function t.setupEquip()
  if (not t.isFull()) then
    turtle.select(t.getEmpty());
  
    turtle.equipLeft();
    local left = turtle.getItemDetail();
    if (left ~= nil) then
      equip[sides.left] = left;
      turtle.equipLeft();
    end
  
    turtle.equipRight();
    local right = turtle.getItemDetail();
    if (right ~= nil) then
      equip[sides.right] = right;
      turtle.equipRight();
    end

    function t.getEquip(side)
      return equip[side];
    end

    function t.equip(side)
      if (equip[side] ~= nil) then return false end
      local item = t.getSelectedItem();
      equip[side] = item;
      local fn = equipSides[side];
      if (fn ~= nil) then fn(); end
      return true;
    end
    
    function t.unequip(side)
      if (equip[side] == nil or t.isFull()) then return false end
      equip[side] = nil;
      local fn = equipSides[side];
      if (fn ~= nil) then fn(); end
      return true;
    end

    return true;
  end
  return false;
end

function t.setupGPS()
  if (hasGPS and turtle.getFuelLevel() >= 1) then
    local x, y, z = gps.locate();
    t.setPos(x, y, z);
    if (t.inspect(sides.forward) == nil) then
      t.go(sides.forward);
      local nx, _, nz = gps.locate();
      local dx, dz = nx - x, nz - z;
      if (dx ~= 0) then
        if (dx == 1) then
          t.setFacing(directions.px);
        elseif dx == -1 then
          t.setFacing(directions.nx);
        end
      elseif (dz ~= 0) then
        if (dz == 1) then
          t.setFacing(directions.pz);
        elseif (dz == -1) then
          t.setFacing(directions.nz);
        end
      end
      return true;
    end
  end
  return false;
end

return t;