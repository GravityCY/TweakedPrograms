local invUtils = require("InvUtils");
local iForm = invUtils.format;
local invW = invUtils.wrap;

local payInv = invW(peripheral.find("minecraft:chest"));
local stockInv = invW(peripheral.find("minecraft:barrel"));

local product = {name="minecraft:dirt", count=1};
local cost = {name="thermal:silver_coin", count=4};

local speaker = peripheral.find("speaker");
local monitor = peripheral.find("monitor");

monitor.setTextScale(0.5);

-- write("Product Name: ");
-- local pName = read();
-- write("Product Count: ");
-- local pCount = tonumber(read());
-- write("Cost Name: ");
-- local cName = read();
-- write("Cost Count: ");
-- local cCount = tonumber(read());

term.clear();
term.setCursorPos(1, 1);

-- product = {name=pName, count=pCount};
-- cost = {name=cName, count=cCount};

local sMsg = string.format("Product:\n%s %s\nCost:\n%s %s", product.count, iForm(product.name), cost.count, iForm(cost.name));
local status = nil;

term.redirect(monitor);

while true do
  term.clear();
  term.setCursorPos(1, 1);
  print(sMsg);
  if (status) then print(status); end
  os.pullEvent("redstone"); 
  if (redstone.getInput("back")) then
    status = nil;
    if (payInv.count(cost.name) >= cost.count) then
      if (stockInv.count(product.name) >= product.count) then
        stockInv.pull(payInv, cost.name, cost.count);
        payInv.pull(stockInv, product.name, product.count);
        status = "Success!";
        speaker.playNote("bell");
      else 
        speaker.playNote("bass"); 
        status = "Product Out of Stock..."; 
      end
    else 
      speaker.playNote("bass"); 
      status = "Not Enough Coins...";
    end
  end
end
