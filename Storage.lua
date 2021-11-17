local iUtils = require("InvUtils");
local format = iUtils.format;

local storage = peripheral.find("occultism:storage_controller");
local mon = peripheral.find("monitor");

local perSecond = 1;
local sleepTime = 5;
--[[ 
  Set starting count of all unique items
  set all unique items to the present table
  then print the present table items - the starting count items / timeSlept * perSecond
--]]

local function unique()
  local unique = {};
  for slot, item in pairs(storage.list()) do
    local prev = unique[item.name];
    unique[item.name] = prev or 0 + item.count;
  end
  return unique;
end

local function diff(tab, tab1)
  local diffMap = {}
  for key, value in pairs(tab) do diffMap[key] = value - tab1[key]; end
  return diffMap;
end

term.redirect(mon);
mon.setTextScale(0.5);
while true do
  term.clear();
  term.setCursorPos(1, 1);
  local startMap = unique();
  sleep(sleepTime);
  local diffMap = diff(unique(), startMap);
  for k,v in pairs(diffMap) do
    local itemTime = v / sleepTime * perSecond;
    if (itemTime >= 0.1 or itemTime <= -0.1) then 
      print(string.format("%.2f", itemTime) .. " " .. format(k) .. " per " .. perSecond .. " second(s)"); 
    end
  end
  sleep(sleepTime);
end