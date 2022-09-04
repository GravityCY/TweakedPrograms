local dist = ...;

local function request(req)
  write(req);
  return read();
end

local function move()
  for i = 1, dist do
    turtle.dig();
    turtle.forward();
    turtle.digDown();
    turtle.down();
    turtle.placeDown();
  end
end

if (dist ~= nil) then dist = tonumber(dist);
else dist = tonumber(request("Enter Distance: ")); end

move();

