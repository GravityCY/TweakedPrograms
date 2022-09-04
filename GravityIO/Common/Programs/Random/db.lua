local db = require("dbapi");
local dbcl = db.connect("192.168.0.69:8080");

local args = {...};

local function writeFile(path, content)
  local file = fs.open(path, "w");
  file.write(content);
  file.close();
end

if (not dbcl) then write("Could Not Connect."); return end

local function requestInput(req)
  write(req);
  return read();
end

local fileName = args[1] or requestInput("Enter File Name: ");
local localPath = args[2] or fileName:match("^.+/(.+)$") or fileName;

local file = dbcl:getFile(fileName);
if (not file.exists) then write("No such file");
else writeFile(localPath, file.content); end