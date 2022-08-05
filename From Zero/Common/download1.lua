local netutils = require("netutils");
local args = {...};

local repo = "https://raw.githubusercontent.com/GravityCY/cc-t/master/Past/"
local path = args[1];

local savePath = args[2] or args[1]:match("^.+/(.+)$");
netutils.saveDownload(repo..path, savePath);