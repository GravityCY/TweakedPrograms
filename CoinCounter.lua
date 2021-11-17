local invUtils = require("InvUtils");
local nameFormat = invUtils.format;
local strFormat = string.format;

local storage = peripheral.find("occultism:storage_controller");
local mon = peripheral.find("monitor");

local sleepTime = 5;

local conversions = { ["thermal:gold_coin"]=64, 
                      ["thermal:silver_coin"]=1};

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

mon.setTextScale(0.5);
term.redirect(mon);
while true do
  term.clear();
  term.setCursorPos(1, 1);
  local totalSilver = 0;
  local coins = getCoins();
  for coin, amount in pairs(coins) do
    local value = conversions[coin] * amount;
    totalSilver = totalSilver + value;
  end
  print(strFormat("Total Value of all Coins: %s", totalSilver));
  for coin, amount in pairs(coins) do
    local value = conversions[coin] * amount;
    local nameFormatted = nameFormat(coin);
    local strFormatted = strFormat("%s %s (%s)", amount, nameFormatted, value);
    print(strFormatted)
  end
  sleep(sleepTime);
end