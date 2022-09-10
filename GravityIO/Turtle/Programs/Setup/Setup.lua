local PerUtils = require("PerUtils");

local args = { ... };

local drive = peripheral.find("drive");
local driveAddr = peripheral.getName(drive);
local invs = PerUtils.getByKey("list", true);
local modem = peripheral.find("modem");
local addr = modem.getNameLocal();

local nbt = "4d1eb2f00be8854cd02b4ae0ca1c04b2";

local dupeFiles = {};

local function copyFiles()
  local mountPath = drive.getMountPath();
  for _, filePath in ipairs(dupeFiles) do
    local out = mountPath .. "/" .. filePath;
    if (fs.exists(filePath)) then
      if (fs.exists(out)) then fs.delete(out) end
      fs.copy(filePath, out);
    end
  end
end

local function setupId(inv, slot)
  inv.pushItems(driveAddr, slot, 1, 1);
  copyFiles();
  inv.pullItems(driveAddr, 1, 1);
end

local function setupNon(inv, slot)
  inv.pushItems(addr, slot, 1, 1);
  turtle.place();
  repeat sleep(0) until peripheral.wrap("front") ~= nil;
  peripheral.wrap("front").turnOn();
  turtle.dig();
  inv.pullItems(addr, 1, 1, inv.size());
  inv.pushItems(driveAddr, inv.size(), 1, 1);
  copyFiles();
  inv.pullItems(driveAddr, 1, 1);
end

turtle.select(1);

if (args[1] ~= nil) then
  if (fs.exists(args[1])) then
    local f = fs.open(args[1], "r");
    while true do
      local line = f.readLine();
      if (line == nil) then break end
      table.insert(dupeFiles, line);
    end
    f.close();
  end
else
  while true do
    write("Enter File Path to Include (Type Fin to Finish): ");
    local input = read():lower();
    if (input == "fin") then break end
    table.insert(dupeFiles, input);
  end
end

for _, inv in ipairs(invs) do
  for slot, item in pairs(inv.list()) do
    if (item.name == "computercraft:turtle_normal") then
      if (item.nbt == nbt) then
        for i = 1, item.count do
          setupNon(inv, slot);
        end
      else
        setupId(inv, slot);
      end
    end
  end
end
