local s = string.format;

local cd = "/disk/";
local co = "/";
local fileName = "Code.lua";

local lfn = s("%s%s", co, fileName);
local rfn = s("%s%s", cd, fileName);

if (fs.exists(rfn)) then fs.delete(rfn); end
fs.copy(lfn, rfn);