local args = {...};

local repo = "https://raw.githubusercontent.com/GravityCY/cc-t/master/Past/"
local path = args[1];

local savePath = args[2] or args[1]:match("^.+/(.+)$");
local dfh = http.get(repo .. path);
local data = dfh.readAll();
local wfh = fs.open(savePath, "w");
wfh.write(data);
