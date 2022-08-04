
local args = {...};

local function requestInput(req)
  write(req);
  return read();
end

local dist = tonumber(args[1]) or tonumber(requestInput("Enter Distance: "));
local height = tonumber(args[2]) or tonumber(requestInput("Enter Height: "));

local isForward = true;

local function place()
  if (not turtle.getItemDetail()) then
    for i = 1, 16 do
      if (turtle.getItemDetail(i)) then turtle.select(i); break end
    end
  end
  turtle.placeDown();
end

local function forward()
  if (isForward) then return turtle.forward();
  else return turtle.back(); end
end

turtle.up();
place();
local travel = dist - 1;
for y = 1, height do
  local moves = 0;
  local hasObstacle = false;
  for z = 1, travel do
    if (forward()) then place();
    else hasObstacle = true; moves = z; break end 
  end
  if (y ~= height) then
    if (hasObstacle) then travel = moves - 1;
    else travel = dist - 1; end
    turtle.up(); 
    place(); 
    isForward = not isForward;
  end
end