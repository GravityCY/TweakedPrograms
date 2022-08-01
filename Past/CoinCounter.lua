local monUtils = require("MonUtils");
local invUtils = require("InvUtils");

local nameFormat = invUtils.format;
local strFormat = string.format;

local storage = peripheral.find("occultism:storage_controller");
local mon = peripheral.find("monitor");

local out = {};

if (not storage) then
  print("Please connect to storage controller via modems");
  error();
end

if (mon) then 
  mon.setTextScale(2); 
  out = mon;
else out = term; end

out = monUtils.wrap(out);

local sleepTime = 5;

local conversions = { ["thermal:gold_coin"]={gold=1, silver=64}, 
                      ["thermal:silver_coin"]={gold=0.015625, silver=1}};

local function getCoins()
  local map = {};
  for slot, item in pairs(storage.list()) do
    if (item.name:find("coin")) then 
      local prev = map[item.name];
      map[item.name] = (prev or 0) + item.count; 
    end
  end
  return map;
end

while true do
  out.clear();
  out.setCursorPos(1, 1);
  local totalSilver = 0;
  local totalGold = 0;
  local coins = getCoins();
  for coin, amount in pairs(coins) do
    local value = conversions[coin].silver * amount;
    totalSilver = totalSilver + value;
  end
  for coin, amount in pairs(coins) do
    local value = conversions[coin].gold * amount;
    totalGold = totalGold + value;
  end
  print(strFormat("Total Value of all Silver: %s", totalSilver));
  print(strFormat("Total Value of all Gold: %s", totalGold));
  for coin, amount in pairs(coins) do
    local value = conversions[coin].silver * amount;
    local nameFormatted = nameFormat(coin);
    local strFormatted = strFormat("%s %s (%s)", amount, nameFormatted, value);
    print(strFormatted)
  end
  sleep(sleepTime);
end