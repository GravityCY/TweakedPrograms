local netutils = require("netutils");

local args = {...};

local repo = "https://raw.githubusercontent.com/GravityCY/cc-t/master/From%20Zero/"
local path = args[1];

local savePath = args[2] or args[1]:match("^.+/(.+)$");
if (netutils.saveDownload(repo..path, savePath)) then
  print("Downloaded " .. savePath .. ".");
else print("Couldn't Download."); end