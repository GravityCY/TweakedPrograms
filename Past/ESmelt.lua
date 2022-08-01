local iu = require("InvUtils");
local pu = require("PeripheralUtils");

local args = {...};

local furnaceName = "minecraft:furnace";
local fuelRatio = args[1];

local inputAddr = nil;
local inputInv = nil;
local outputAddr = nil;
local outputInv = nil;
local fuelAddr = nil
local fuelInv = nil;
local smelteries = pu.blacklistSides(pu.get(furnaceName, true));

local speaker = peripheral.find("speaker");

local hasData = false;

local function load()
  local rf = fs.open("/data/esmelt/addrs.txt", "r");
  if (rf == nil) then return end
  inputAddr = rf.readLine();
  outputAddr = rf.readLine();
  fuelAddr = rf.readLine();
  rf.close();
  hasData = true;
end

local function save()
  local wf = fs.open("/data/esmelt/addrs.txt", "w");
  wf.write(inputAddr.."\n")
  wf.write(outputAddr.."\n")
  wf.write(fuelAddr.."\n")
  wf.close();
end

local function detect()
  local wasAdded, addr = true, nil;
  local function attach()
    _, addr = os.pullEvent("peripheral");
    wasAdded = true;
  end
  
  local function detach()
    _, addr = os.pullEvent("peripheral_detach");
    wasAdded = false;
  end
  parallel.waitForAll(attach, detach);
  return wasAdded, addr;
end

local function requestInput(req)
  write(req);
  return read();
end

local function setup()
  if (fuelRatio == nil) then fuelRatio = tonumber(requestInput("Enter Fuel Ratio: " )); end
  if (inputAddr == nil) then inputAddr = requestInput("Enter Address of Input: ") end
  if (outputAddr == nil) then outputAddr = requestInput("Enter Address of Output: ") end
  if (fuelAddr == nil) then fuelAddr = requestInput("Enter Address of Fuel: ") end
  inputInv = iu.wrap(inputAddr);
  outputInv = iu.wrap(outputAddr);
  fuelInv = iu.wrap(fuelAddr);
end

local function getUniqueCount()
  local uniques = {}
  for _, item in pairs(inputInv.list()) do
    if (uniques[item.name] == nil) then uniques[item.name] = item.count;
    else uniques[item.name] = uniques[item.name] + item.count end
  end
  return uniques;
end

local function extract()
  while true do
    local hasItem = false;
    for _, smeltery in pairs(smelteries) do
      local smeltingItem = smeltery.getItemDetail(1);
      smeltery.pushItems(outputAddr, 3, 64);
      if (smeltingItem) then hasItem = true; end
    end
    if (not hasItem) then break end
    sleep(1);
  end
end

local function smelt()
  local uniques = getUniqueCount();
  for itemName, amount in pairs(uniques) do
    local sTime = os.clock();
    if (amount >= fuelRatio) then
      print("Smelting " .. itemName .. " this may take a minute...");
      for _ = 1, amount / fuelRatio do
        for _, smeltery in ipairs(smelteries) do
          if (amount >= fuelRatio and fuelInv.pushAny(smeltery, 1, 2) == 1) then
            inputInv.push(smeltery, itemName, fuelRatio, 1);
            amount = amount - fuelRatio;
          else break end
        end
      end
      extract();
      print("Finished Smelting " .. itemName .. ".");
      local eTime = os.clock();
      print("Took " .. string.format("%0.2f", eTime - sTime ).. " seconds...");
      if (speaker) then speaker.playNote("harp", 1, 1); end
    end 
  end
end

load();
setup();
if (not hasData) then save(); end
while true do
  print("Waiting for Activation...");
  os.pullEvent("redstone");
  if (redstone.getInput("top")) then smelt(); end
end