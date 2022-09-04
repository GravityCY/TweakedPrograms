local p = require("Process");

local monitor = peripheral.find("monitor");

local mx, my = monitor.getSize();

local commonAddr = "minecraft:chest_24";

local smelt = p.new("minecraft:chest_28", commonAddr, "minecraft:chest_17", "minecraft:chest_31");
local smoke = p.new("minecraft:chest_25", commonAddr, "minecraft:chest_20", "minecraft:chest_32");
local wash = p.new("minecraft:chest_22", commonAddr, "minecraft:chest_30", "minecraft:chest_29");
local haunt = p.new("minecraft:chest_26", commonAddr, "minecraft:chest_34", "minecraft:chest_33");

local processes = {smelt, smoke, wash, haunt};
local process = smelt;
local index = 1;

local lifetime = 0;
local isDisabled = false;

local function setProcess(i)
  index = i;
  process = processes[i];
end

local function setDisabled(v)
  if (isDisabled == v) then return end
  isDisabled = v;
end

local function getIndex()
  if (index == 1) then
    return "Smelt";
  elseif (index == 2) then
    return "Smoke";
  elseif (index == 3) then
    return "Wash";
  elseif (index == 4) then
    return "Haunt"
  else
    return "WTF?";
  end
end

local function mainThread()
  while true do
    if (isDisabled) then sleep(1);
    else 
      for _, cp in ipairs(processes) do cp.main(); end
    end
  end
end

local function renderThread()
  while true do
    term.clear();
    term.setBackgroundColor(colors.white);
    term.setCursorPos(mx, my);
    term.write(" ");
    term.setCursorPos(1, my);
    term.write(" ");
    term.setBackgroundColor(colors.black);
    term.setCursorPos(1, 1)
    if (isDisabled) then 
      print("Currently Disabled."); 
      sleep(1);
    else
      print(string.format("Lifetime: %ds", lifetime))
      print()
      print(string.format("Items Smelted: %d", process.getTotal()))
      print(string.format("Most Recent Item: %s", process.getRecentItem()));
      print()
      print(string.format("Page: %s", getIndex()));
    end
    sleep(0.1);
    lifetime = lifetime + 0.1;
  end
end

local function redstoneThread()
  while true do
    os.pullEvent("redstone");
    if (redstone.getInput("front")) then setDisabled(true);
    else setDisabled(false); end
  end
end

local function touchThread()
  while true do
    local _, _, x, y = os.pullEvent("monitor_touch");
    if (index < #processes and x == mx and y == my) then
      setProcess(index + 1);
    elseif (index > 1 and x == 1 and y == my) then
      setProcess(index - 1);
    end
  end
end

term.redirect(monitor);
parallel.waitForAll(mainThread, renderThread, redstoneThread, touchThread);