local args = {...};

local repo = "https://raw.githubusercontent.com/GravityCY/cc-t/master/From%20Zero/"
local path = args[1];

local savePath = args[2]:lower() or args[1]:match("^.+/(.+)$"):lower();

if (fs.exists(savePath)) then fs.delete(savePath) end

shell.run("wget", repo .. path, savePath);