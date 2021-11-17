local s = string.format;

shell.run("Setup.lua");

local co = "/";
local cd = "/disk/";
local fileName1 = "Mine.lua";
local fileName2 = "TurtleUtils.lua";
local sf1 = s("%s%s", co, fileName1);
local sf2 = s("%s%s", co, fileName2);
local sfm1 = s("%s%s", cd, fileName1);
local sfm2 = s("%s%s", cd, fileName2);

if (fs.exists(sfm1)) then fs.delete(sfm1); end
fs.copy(sf1, sfm1);
if (fs.exists(sfm2)) then fs.delete(sfm2); end
fs.copy(sf2, sfm2);