local drive = peripheral.find("drive");
local opath = drive.getMountPath() .. "/levels.txt";

local file = fs.open(opath, "a");
file.write(turtle.getFuelLevel() .. "\n");
file.close();