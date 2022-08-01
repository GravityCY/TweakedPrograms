local t = {};
local sides = {["up"]=0, ["down"]=1, ["right"]=2, ["left"]=3, ["forward"]=4, ["back"]=5};

local digSides = {[sides.up]=turtle.digUp, [sides.down]=turtle.digDown, [sides.forward]=turtle.dig};
local goSides = {[sides.up]=turtle.up, [sides.down]=turtle.down, [sides.forward]=turtle.forward, [sides.back]=turtle.back};
local turnSides = {[sides.left]=turtle.turnLeft, [sides.right]=turtle.turnRight, [sides.back]=function() turtle.turnRight(); turtle.turnRight(); end};
local dropSides = {[sides.down]=turtle.dropDown, [sides.up]=turtle.dropUp, [sides.forward]=turtle.drop, [sides.back]=function(amount) turtle.turnRight(); turtle.turnRight(); turtle.drop(amount) end};
local placeSides = {[sides.down]=turtle.placeDown, [sides.forward]=turtle.place, [sides.up]=turtle.placeUp};

t.sides = sides;

function t.select(name)
  for i = 1, 16 do
    local item = turtle.getItemDetail(i);
    if (item ~= nil and item.name == name) then
      turtle.select(i);
      return true;
    end
  end
  return false;
end

function t.dig(side)
  local f = digSides[side];
  if (f ~= nil) then return f(); end
end

function t.go(side)
  local f = goSides[side];
  if (f ~= nil) then return f(); end
end

function t.turn(side)
  local f = turnSides[side];
  if (f ~= nil) then return f(); end
end

function t.place(side, name)
  local f = placeSides[side];
  if (name ~= nil and t.select(name)) then return false end
  if (f ~= nil) then return f(); end
end

function t.goDig(side)
  local tries = 1;
  while true do
    local success = t.go(side);
    if (success) then break
    else
      t.dig(side);
      tries = tries + 1;
    end
  end
  return tries;
end

function t.drop(slot, amount, side)
  side = side or sides.forward;
  slot = slot or turtle.getSelectedSlot();
  local f = dropSides[side];
  if (turtle.getItemCount(slot) ~= 0 and f ~= nil) then
    turtle.select(slot);
    f(amount)
  end
end

function t.dropAll(side)
  for i = 1, 16 do t.drop(i, 64, side); end
end

return t;