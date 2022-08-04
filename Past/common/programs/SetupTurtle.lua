write("Enter Buffer Address: ");
local tinv = peripheral.wrap(read());
local drive = peripheral.find("drive");
local daddr = peripheral.getName(drive);

local programs = {"TurtleUtils.lua", "RandomName.lua", "bmine.lua", "bminef.lua", "db.lua", "dbapi.lua"};

for slot, item in pairs(tinv.list()) do
  if (item.name:find("turtle")) then
    tinv.pushItems(daddr, slot, 64, 1);
    sleep(0.1);
    local mpath = drive.getMountPath();
    for _, program in ipairs(programs) do
      local outPath = mpath .. "/" .. program;
      if (not fs.exists(program)) then shell.run("db", program); end
      if (fs.exists(outPath)) then fs.delete(outPath) end
      fs.copy(program, outPath);
    end
    tinv.pullItems(daddr, 1, 64, slot);
  end
end