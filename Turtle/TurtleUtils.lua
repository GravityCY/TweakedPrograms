local t = {};

local invSize = 16;

local sides = { right=0, left=1, back=2, forward=3, down=4, up=5 }
t.sides = sides;

local goSides = { [sides.forward]=turtle.forward,
                  [sides.down]=turtle.down,
                  [sides.up]=turtle.up,
                  [sides.back]=turtle.back };

local turnSides = { [sides.right]=turtle.turnRight,
                    [sides.left]=turtle.turnLeft,
                    [sides.back]=function() turtle.turnRight(); turtle.turnRight() end };

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

local getItemDetail = turtle.getItemDetail;

function t.getSlot(id)
    for slot = 1, invSize do
        local item = getItemDetail(slot);
        if (item and item.name == id) then return slot end
    end
end

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

function t.drop(slot, side)
  turtle.select(slot);
  local fn = dropSides[side];
  if (fn) then return fn(); end
end

function t.dropAll(side)
  for i = 1, invSize do
    local item = turtle.getItemDetail(i);
    if (item) then t.drop(i, side); end
  end
end

function t.full()
  local emptySlot = false;
  for i = 1, invSize do
    if (not turtle.getItemDetail(i)) then emptySlot = true; break end
  end
  return not emptySlot;
end

function t.go(side)
  local fn = goSides[side];
  if (fn) then return fn(); end
end

function t.turn(side)
  local fn = turnSides[side];
  if (fn) then return fn(); end
end

function t.dig(side)
  local fn = digSides[side];
  if (fn) then return fn(); end
end

function t.place(side)
  local fn = placeSides[side];
  if (fn) then return fn(); end
end

function t.inspect(side)
  local fn = inspectSides[side];
  if (fn) then return fn(); end
end

function t.goDig(side)
  while true do
    local goSuccess, goReason = t.go(side);
    -- if it went forward
    if (goSuccess) then return goSuccess
    else
      local digSuccess, digReason = t.dig(side);
      -- If it failed to dig and it was bedrock
      if (digReason and digReason == "Unbreakable block detected") then return goSuccess, digReason end
    end
  end
end

return t;