
local tu = require("TurtleUtils");
local sides = tu.sides;

local args = {...};

local ix, iy, iz = args[1], args[2], args[3];

if (ix == nil) then write("Enter Forward: " ) ix = read(); end
if (iy == nil) then write("Enter Vertical Repeats: " ) iy = read(); end
if (iz == nil) then write("Enter Horiizontal: " ) iz = read(); end

ix, iy, iz = tonumber(ix), tonumber(iy), tonumber(iz);
local x, y, z = ix, iy, iz;

local isEven = iz % 2 == 0;
local vert = nil;
if (iy > 0) then
  y = iy;
  vert = sides.up;
else
  y = math.abs(iy);
  vert = sides.down;
end

local function bmine(x, z)
  shell.run("bmine", x, z, "false", "true");
end

bmine(1, 1);
for i = 1, y do
  bmine(x - 1, z);
  if (i ~= y) then
    for _ = 1, 3 do tu.goDig(vert); end
    tu.turn(sides.back);
    if (isEven) then z = z * -1; end
    tu.dig(sides.up);
    tu.dig(sides.down);
  end
end

write("Finished");
error();