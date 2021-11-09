local args = {...};

local function getDist()
  if (#args == 0) then
    write("Enter Distance: ");
    return tonumber(read());
  else
    return tonumber(args[1]);
  end
end

local dist = getDist();

local function forward()
  local found = turtle.inspect();
  if (found) then
    turtle.dig();
  end
  turtle.forward();
end

local function up()
  local found = turtle.inspectUp();
  if (found) then
    turtle.digUp();
  end
  turtle.up();
end

local function down()
  local found = turtle.inspectDown();
  if (found) then
    turtle.digDown();
  end
  turtle.down();
end

local function goBack()
  for distNow = 1, dist do
    if (distNow ~= 1) then turtle.up(); end
    turtle.back();
  end
end

for distNow = 1, dist do
  forward();
  turtle.digUp();
  if (distNow ~= dist) then down();
  else turtle.digDown(); end
end

goBack();
