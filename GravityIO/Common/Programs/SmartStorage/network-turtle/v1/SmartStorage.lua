-- TODO:
-- Auto Crafting DONE
--  Auto Crafting needs to ignore if you have enough resources and just try anyways
-- 
-- Make it so that program doesn't have to use only the storage inventories for storage and connect everything kind of.
-- 
-- Custom Auto Crafting using Exporters
-- 
-- Importers / Exporters
-- 
-- Shulker Loader, Load Specific Items into Shulkers with specific Display Names.
-- 
--  Example "Redstone" Named Shulker will be filled with redstone specified items.

local PerUtils = require("PerUtils");
local ItemUtils = require("ItemUtils");
local InvUtils = require("InvUtils");
local TableUtils = require("TableUtils");
local CraftingAPI = require("CraftingAPI");
local Localization = require("Localization");
local SNAPI = require("StorageNetworkAPI");

local crafterId = 22;

local mainDirectory = "/data/smart_storage/";
local dataPath = mainDirectory .. "data";
local dumpData = mainDirectory .. "dumpData";
local autoData = mainDirectory .. "autoData";
local patternDirectory = mainDirectory .. "patterns/";
local localeDirectory = mainDirectory .. "locale/";
local filterDirectory = mainDirectory .. "inv_data/";

CraftingAPI.setSaveDirectory(patternDirectory);
Localization.setSaveDirectory(localeDirectory);
Localization.init();
CraftingAPI.init();

-- Addresses
local inputAddr = nil;
local redEnableAddr = nil;
local overflowType = nil;
local interfaceType = nil;
local storageType = nil;
local crafterAddr = nil;
local dumperAddr = nil;

-- Peripherals
local inputPeriph = nil;
local overflowList = nil;
local interfaceList = nil;
local storageList = nil;
local enablePeriph = nil;
local modemPeriph = nil;
local crafterTurtle = nil;
local dumperTurtle = nil;

local tmx, tmy = nil, nil;

local doTasks = true;
local doAutocrafting = true;
local doPrint = true;

-- A list of list of filter items
-- filtersLookup["minecraft:chest_1"][1]
local filtersLookup = {};
-- A string indexed lookup table of item types and if they exist
-- filterLookup["minecraft:dirt"] ~= nil means it's a filter item
local filterLookup = {};
-- A string indexed lookup table of item types and their total amount in the storage
-- totalLookup["minecraft:dirt"] returns a total of dirt in the system
local totalLookup = {};
-- A string indexed lookup table of item types and how much they shouldn't exceed in storage
-- dumpLookup["minecraft:dirt"] returns 1000 meaning that dirt over 1000 will be dumped in to lava
local dumpLookup = {};
-- A string indexed lookup table of item types and how much to auto craft to keep a steady amount in storage.
-- autoLookup["minecraft:oak_planks"] returns 64 meaning that planks will always try to be autocrafted upto 64
local autoLookup = {};
local emptyList = {};
-- A string indexed lookup table of item tags and their total amount in the storage
-- tagLookup["minecraft:planks"] returns a total of planks in the system
local tagLookup = {};

local toTurtleSlot = {1, 2, 3, 5, 6, 7, 9, 10, 11};

local function getPeripheral()
  local _, addr = os.pullEvent("peripheral");
  sleep(0);
  return addr;
end

local function detectUI(current)
  term.clear();
  term.setCursorPos(1, 1);
  print(Localization.get("pDetectMode"));
  print()
  print(Localization.get("pDetect1"));
  print();
  print(Localization.get("pDetect2"));
  print(Localization.get("pSelect"):format(current));
end

local function loadFilter()
  if (not fs.exists(filterDirectory)) then return end

  for _, namespace in ipairs(fs.list(filterDirectory)) do
    local namespacePath = filterDirectory .. namespace .. "/";
    if (fs.exists(namespacePath)) then
      for _, addr in ipairs(fs.list(namespacePath)) do
        local fullAddr = namespace .. ":" .. addr;
        if (peripheral.wrap(fullAddr) ~= nil) then
          filtersLookup[fullAddr] = {};
          local filterFile = fs.open(namespacePath .. addr, "r");
          while true do
            local line = filterFile.readLine();
            if (line == nil) then break end
            local slot = tonumber(line);
            local type = filterFile.readLine();
            filterLookup[type] = true;
            filtersLookup[fullAddr][slot] = type;
          end
          filterFile.close();
        else
          fs.delete(filterDirectory .. "/" .. addr);
        end
      end
    end
  end
end

local function saveFilter()
  for _, inv in ipairs(interfaceList) do
    local name = peripheral.getName(inv);
    local namespace = ItemUtils.namespace(name);
    local addr = ItemUtils.type(name);
    local path = ("%s%s/%s"):format(filterDirectory, namespace, addr);
    local file = fs.open(path, "w");
    for slot, item in pairs(inv.list()) do
      file.writeLine(slot)
      file.writeLine(item.name)
    end
    file.close();
  end
end

local function loadData()
  if (not fs.exists(dataPath)) then return end

  local f = fs.open(dataPath, "r");
  redEnableAddr = f.readLine();
  overflowType = f.readLine();
  interfaceType = f.readLine();
  storageType = f.readLine();
  crafterAddr = f.readLine();
  dumperAddr = f.readLine();
  crafterId = tonumber(f.readLine());
  f.close();
end

local function saveData()
  detectUI("Red Router Activation Block: ");
  redEnableAddr = getPeripheral();
  detectUI("Overflow Inventory\nJust Select 1 of the Inventories to Internally save the Type.");
  overflowType = peripheral.getType(getPeripheral());
  detectUI("Interface Inventory\nJust Select 1 of the Inventories to Internally save the Type.");
  interfaceType = peripheral.getType(getPeripheral());
  detectUI("Storage Inventory\nJust Select 1 of the Inventories to Internally save the Type.");
  storageType = peripheral.getType(getPeripheral());
  detectUI("Crafter Turtle: ");
  crafterAddr = getPeripheral();
  detectUI("Dumper Turtle: ");
  dumperAddr = getPeripheral();
  term.clear();
  term.setCursorPos(1, 1);
  write("Enter Crafting Turtle ID: ")
  crafterId = tonumber(read());

  local f = fs.open(dataPath, "w");
  f.writeLine(redEnableAddr);
  f.writeLine(overflowType);
  f.writeLine(interfaceType);
  f.writeLine(storageType);
  f.writeLine(crafterAddr);
  f.writeLine(dumperAddr);
  f.writeLine(crafterId);
  f.close();
end

local function loadDump()
  if (not fs.exists(dumpData)) then return end

  local f = fs.open(dumpData, "r");
  if (f == nil) then return end
  while true do
    local line = f.readLine();
    if (line == nil) then break end
    local item = line:match("%S+");
    local count = tonumber(line:match("%s(.+)"));
    dumpLookup[item] = count;
  end
end

-- Appends a single dump requirement to the file
local function saveDump(item, count)
  local f = fs.open(dumpData, "a");
  f.writeLine(item .. " " .. count);
  f.close();
end

-- Rewrites the whole file from the current dump requirement table
local function saveDumps()
  local f = fs.open(dumpData, "w");
  for item, count in pairs(dumpLookup) do
    f.writeLine(item .. " " .. count);
  end
  f.close();
end

-- Adds to the table and appends to file
local function addDump(item, count)
  dumpLookup[item] = count;
  saveDump(item, count);
end

-- Removes from the table and rewrites file
local function removeDump(item)
  dumpLookup[item] = nil;
  saveDumps();
end

local function saveAuto(type, count)
  local f = fs.open(autoData, "a");
  f.writeLine(type .. " " .. count);
  f.close();
end

local function saveAutos()
  local f = fs.open(autoData, "w");
  for type, count in pairs(autoLookup) do
    f.writeLine(type .. " " .. count);
  end
  f.close();
end

local function loadAuto()
  if (not fs.exists(autoData)) then return end

  local f = fs.open(autoData, "r");
  while true do
    local line = f.readLine();
    if (line == nil) then break end
    local type = line:match("%S+");
    local count = tonumber(line:match("%s(.+)"));
    autoLookup[type] = count;
  end
  
  f.close();
end

local function addAuto(type, count)
  if (autoLookup[type] ~= nil) then return false; end
  saveAuto(type, count);
  autoLookup[type] = count;
  return true;
end

local function removeAuto(type)
  if (autoLookup[type] == nil) then return false; end
  autoLookup[type] = nil;
  saveAutos();
  return true;
end

local function addTotal(name, count)
  
  totalLookup[name] = (totalLookup[name] or 0) + count;
end

local function updateTotal()
  for _, item in pairs(SNAPI.list()) do
    addTotal(item.name, item.count);
  end
end

local function getTotal(type)
  return totalLookup[type] or 0;
end

local function setup()
  if (not fs.exists(dataPath)) then saveData();
  else loadData(); end
  loadFilter();
  loadDump();
  loadAuto();

  overflowList = PerUtils.getType(overflowType, true);
  interfaceList = InvUtils.wrapList(PerUtils.blacklistSides(PerUtils.getType(interfaceType, true)));
  storageList = PerUtils.getType(storageType, true);
  enablePeriph = PerUtils.get(redEnableAddr);
  modemPeriph = peripheral.find("modem");
  crafterTurtle = PerUtils.get(crafterAddr);
  dumperTurtle = PerUtils.get(dumperAddr);
  inputAddr = modemPeriph.getNameLocal();
  inputPeriph = {
    pushItems = function(toAddr, fromSlot, amount, toSlot)
      local toPeriph = peripheral.wrap(toAddr);
      return toPeriph.pullItems(inputAddr, fromSlot, amount, toSlot);
    end,
    pullItems = function(fromAddr, fromSlot, amount, toSlot)
      local fromPeriph = peripheral.wrap(fromAddr);
      return fromPeriph.pushItems(inputAddr, fromSlot, amount, toSlot);
    end,
    list = function()
      local items = {};
      for i = 1, 16 do
        local item = turtle.getItemDetail(i);
        if (item ~= nil) then
          if (not ItemUtils.exists(item.name)) then
            item = turtle.getItemDetail(i, true);
            ItemUtils.add(item);
          else ItemUtils.wrap(item); end
        end
        items[i] = item;
      end
      return items;
    end
  };
  rednet.open(peripheral.getName(modemPeriph));

  tmx, tmy = term.getSize();

  for _, p in ipairs(storageList) do SNAPI.add(peripheral.getName(p)); end
  function crafterTurtle.list()
    rednet.send(crafterId, nil, "list-start");
    local _, message = rednet.receive("list-end");
    return message;
  end
  updateTotal();
end

local function isFilterItem(type)
  return filterLookup[type] ~= nil
end

local function toOverflow(fromAddr, slot, amount)
  local pushed = 0;
  for _, overflow in ipairs(overflowList) do
    local push = overflow.pullItems(fromAddr, slot, amount - pushed);
    pushed = pushed + push;
    if (pushed == amount) then break end
  end
  return pushed;
end

local function push(addr, type, amount, toSlot)
  local pushed = SNAPI.push(addr, type, amount, toSlot);
  addTotal(type, -pushed);
end

local function pull(addr, type, amount, toSlot)
  local pulled = SNAPI.pull(addr, type, amount, toSlot);
  addTotal(type, pulled);
end

local function pullItems(type, addr, fromSlot, amount)
  local pulled = SNAPI.pullItems(addr, fromSlot, amount);
  addTotal(type, pulled);
end

local function pushItems(type, addr, slot, amount)
  local pushed = SNAPI.pushItems(addr, slot, amount);
  addTotal(type, -pushed);
  return pushed;
end

local function pprint(...)
  if (doPrint) then print(...); end
end

local function printLookup(lookup, filter)
  term.clear();
  term.setCursorPos(1, 1);
  local index = 1;
  for type, count in pairs(lookup) do
    if (filter ~= nil) then
      if (type:find(filter)) then
        term.setTextColor(index);
        print(Localization.get("listItem"):format(count, type))
        index = math.max(index * 2 % 32768, 1);
      end
    else
      term.setTextColor(index);
      print(Localization.get("listItem"):format(count, type));
      index = math.max(index * 2 % 32768, 1);
    end
  end
  term.setTextColor(colors.white);
end

local function batch()
  local items = {};
  local functions = {};
  for index, inv in ipairs(interfaceList) do
    functions[index] = function() items[index] = inv.list() end
  end
  parallel.waitForAll(table.unpack(functions))
  return items;
end

local function toIndex(addr)
  for index, interface in ipairs(interfaceList) do
    if (interface.addr == addr) then return index; end
  end
end

-- Gets how much you'd need to craft in comparison to how much in storage
local function getNeed(cost, usedLookup)
  usedLookup = usedLookup or {};
  local need = {};
  for name, count in pairs(cost) do
    local total = getTotal(name);
    need[name] = math.max(count - math.max(total - (usedLookup[name] or 0), 0), 0);
  end
  return need;
end

local function getResources(items)
  local resources = {};
  for i = 1, 9 do
    local item = items[toTurtleSlot[i]];
    if (item ~= nil) then resources[i] = item.name; end
  end
  return resources;
end

local function getProduct(items)
  if (items[16] ~= nil) then return items[16].name; end
end

local function getCount(items)
  if (items[16] ~= nil) then return items[16].count; end
end

local function getPossible(recipe)
  local costLookup = CraftingAPI.total(recipe, 1);
  local smallest = 9999;
  for type, cost in pairs(costLookup) do
    local total = getTotal(type);
    smallest = math.min(smallest, math.ceil(total / cost));
  end
  return smallest * recipe.count;
end

-- This is a hard algorithm
-- so I need to somehow get how many barrels I can craft by seeing how many planks I can craft and how many slabs I can craft
-- Let's say I have 60 planks, 20 slabs I could say that I can craft 10 Barrels since 60 / 6 and 20 / 2 is 10
-- But let's say that I have 10 Oak Logs 
-- I could craft 40 planks for the barrel which would make a total of 100 planks and 20 slabs, 
-- still limited at crafting 10 barrels cause of the slabs
-- or 40 planks into 78 slabs which means I could craft 10 barrels still
-- or 40 more planks and split between the barrel and crafting the slabs
-- so I guess like 20 planks for the barrel and 20 planks for the slabs?
-- Which would mean 80 planks total and 56 slabs I thinks which would mean I can craft 13 barrels but alot of the slabs aren't used
-- so I how do I properly estimate how many planks to use for the slabs and how many planks to use for the barrel
-- local function getPossibleRecursive(recipe, usedLookup)
--   local costLookup = CraftingAPI.total(recipe, 1);
--   local smallest = math.huge;
--   for type, cost in pairs(costLookup) do
--     local total = getTotal(type);
--     local subrecipe = CraftingAPI.get(type);
--     local craftable = (subrecipe ~= nil and getPossibleRecursive(subrecipe, usedLookup)) or 0;
--     local possible = math.ceil((total + craftable - (usedLookup[type] or 0)) / cost) * recipe.count;
--     smallest = math.min(smallest, math.max(possible, 0));
--   end
--   return smallest;
-- end

--#region
-- Problems that need solving
  -- Recipes that have resources that one needs the other resource in order to be crafted can be problematic
    -- A Barrel for example needs planks and slabs, slabs need planks, for example;
    -- Lets say you have 6 planks, the barrel recipe thinks it has enough planks but needs 2 slabs which need planks, you craft slabs using up the planks and then the barrel doesn't
    -- have enough planks even though the initial check says it does
    -- You'd need to either somehow detect that the planks are needed for the parent recipe when crafting slabs, and instead of using the planks, craft new ones
    -- OR do another check at the end of the parent recipe I guess
    -- OR Each subrecipe gets a total of what it's parent recipe needs, for example:
    -- A barrel needs 2 slabs, 6 planks
    -- You need 2 slabs and 0 planks cause you have enough planks
    -- You need to craft 2 slabs which needs 3 planks, so you say
    -- There's 6 planks in system but my parent recipe needs 6 planks so realistically there's 0 in storage
    -- So basically itemsInStorage - itemsParentNeeds == how much I really have in storage 
    -- And I think any subrecipes of subrecipes that would SOMEHOW need planks will need to know the top parent will still need 6 planks cause I think it's possible
    -- to somehow make it think that there is enough in storage if you ONLY give it the immediate parents needs 
    -- so basically merge the tables from recipe to subrecipe to subrecipe etc.

  -- Sending Recipes that need items higher than the items stack sizes is problematic
    -- Let's say you need 512 Oak Planks, you will need 128 logs to be crafted, logs have a stack size of 64
    -- You will need to send 64 logs to the turtles slot twice
    -- Kinda like for i = 1, 128 / 64 do 
    -- But for cases that have variable stack sizes like 1 item stack size is 16 and the other is 64
    -- You'd need to work based off of the lowest stack size
    -- An Eye of Ender for Example; if you want 32 eyes of ender
    -- The blaze powder stack size is 64, the ender pearl stack size is 16
    -- You'd need to send 16 blaze powder since that's less than it's stack size
    -- Then 16 Ender Pearls, and 16 blaze powder and craft once.
    -- Then again 16 ender pearls, craft once again.
    -- How the fuck do you implements all this shit

  -- Sending Recipes that produce more stacks than the turtles inventory is problematic
    -- 17 Diamond Pickaxes will take up 17 slots of the turtle when it only has 16
    -- You will need to send resources worth 16 diamond pickaxes once and then resources worth 1 diamond pickaxe once again.
    -- or send all the resources for 17 diamond pickaxes, and craft only 16, since turtle.craft() can take an argument of how many to craft

-- Somehow check you have all of the required items before trying to craft anything, even the subrecipes if out of resources.
--#endregion

local function isEnough(recipe, times, parentUsed)
  parentUsed = parentUsed or {};
  local costLookup = CraftingAPI.total(recipe, times);
  local needLookup = getNeed(costLookup, parentUsed);
  for type, need in pairs(needLookup) do
    parentUsed[type] = (parentUsed[type] or 0) + need;
  end
  for type, need in pairs(needLookup) do
    if (need ~= 0) then
      local sub = CraftingAPI.get(type);
      pprint(Localization.get("craftNeedMore"):format(need, type));
      if (sub ~= nil) then
        if (not isEnough(sub, math.ceil(need / sub.count), parentUsed)) then
          pprint(Localization.get("craftNotEnoughToCraft"):format(need, type));
          return false;
        end
      else
        pprint((Localization.get("craftNotSubrecipe")):format(type, need));
        return false;
      end
    else
    end
  end
  return true
end

local function getTotalCost(recipe, times)
  local totalCost = {};
  local costLookup = CraftingAPI.total(recipe, times);
  for type, cost in pairs(costLookup) do
    totalCost[type] = {};
    totalCost[type].cost = cost;
    local sub = CraftingAPI.get(type);
    if (sub ~= nil) then
      totalCost[type].resources = getTotalCost(sub, math.ceil(cost / sub.count));
    end
  end
  return totalCost;
end

local function getTotalNeed(recipe, times, parentUsed)
  parentUsed = parentUsed or {};
  local totalNeed = {};
  local costLookup = CraftingAPI.total(recipe, times);
  local needLookup = getNeed(costLookup, parentUsed)
  for type, need in pairs(needLookup) do
    parentUsed[type] = (parentUsed[type] or 0) + need;
  end
  for type, need in pairs(needLookup) do
    totalNeed[type] = {need=need};
    if (need ~= 0) then
      local sub = CraftingAPI.get(type);
      if (sub ~= nil) then
        totalNeed[type].resources = {};
        local subneed = getTotalNeed(sub, math.ceil(need / sub.count), parentUsed);
        for itemNeeded, itemData in pairs(subneed) do
          totalNeed[type].resources[itemNeeded] = itemData;
        end
      end
    end
  end
  return totalNeed;
end

local function craft(product, want, usedLookup)
  local sub = usedLookup ~= nil;
  usedLookup = usedLookup or {};
  local recipe = CraftingAPI.get(product);
  if (recipe == nil) then return end
  want = want or recipe.count;
  local times = math.ceil(want / recipe.count);
  if (sub or isEnough(recipe, times)) then
    local count = recipe.count * times;
    local costLookup = CraftingAPI.total(recipe, times);
    local needLookup = getNeed(costLookup, usedLookup);
    for type, need in pairs(needLookup) do
      usedLookup[type] = (usedLookup[type] or 0) + need;
    end
    if (sub == nil) then
      pprint(Localization.get("craftRecipe"):format(count, product))
    else
      pprint(Localization.get("craftSubrecipe"):format(count, product))
    end
    for type, need in pairs(needLookup) do
      if (need ~= 0) then
        craft(type, need, usedLookup);
      end
    end
    local smallest = 64;
    for type, _ in pairs(costLookup) do
      local common = ItemUtils.get(type);
      if (common.maxCount < smallest) then
        smallest = common.maxCount;
      end
    end
    local sent = 0;
    for _ = 1, math.ceil(times / smallest) do
      for i, type in pairs(recipe.resources) do
        push(crafterAddr, type, math.min(smallest, times - sent), toTurtleSlot[i]);
      end
      sent = sent + smallest;
      rednet.send(crafterId, nil, "craft-start");
      rednet.receive("craft-end");
      for slot, item in pairs(crafterTurtle.list()) do
        pullItems(item.name, crafterAddr, slot, 64);
      end
    end
  end
end

local function storeTask()
  for slot, item in pairs(inputPeriph.list()) do
    if (isFilterItem(item.name)) then
      pullItems(item.name, inputAddr, slot, item.count);
    else toOverflow(inputAddr, slot, item.count); end
  end
  if (#emptyList == 0) then return end
  for _, inv in ipairs(emptyList) do
    for slot, item in pairs(inv.list()) do
      if (isFilterItem(item.name)) then
        pullItems(item.name, inv.addr, slot, item.count);
      else toOverflow(inv.addr, slot, item.count); end
    end
  end
  emptyList = {};
end

local function restockTask()
  local batchItems = batch();
  for addr, filterList in pairs(filtersLookup) do
    local interfaceItems = batchItems[toIndex(addr)];
    for slot, type in pairs(filterList) do
      local item = interfaceItems[slot];
      local common = ItemUtils.get(type);
      if (item == nil or item.count < common.maxCount) then
        local total = getTotal(type);
        local count = (item and item.count) or 0;
        if (total ~= nil and total > 0) then
          push(addr, type, common.maxCount - count, slot)
        end
      end
    end
  end
end

local function dumpTask()
  for item, dump in pairs(dumpLookup) do
    local total = totalLookup[item];
    if (total ~= nil and total >= dump) then
      push(dumperAddr, item, total - dump);
    end
  end
end

local function craftTask()
  if (not doAutocrafting) then return end

  doPrint = false;
  for type, req in pairs(autoLookup) do
    local total = getTotal(type);
    if (total < req) then craft(type, req - total); end
  end
  doPrint = true;
end

local function tasks()
  while true do
    if (not doTasks) then sleep(1);
    else
      parallel.waitForAll(storeTask, dumpTask, craftTask)
      if (enablePeriph.getInput("top")) then restockTask(); end
      sleep(0);
    end
  end
end

local function printNeed(need, x, index)
  x = x or 1;
  index = index or 1;

  local _, y = term.getCursorPos();
  for type, data in pairs(need) do
    term.setCursorPos(x, y);
    term.setTextColor(index);
    print("Need " .. data.need .. " " .. type);
    y = math.min(y + 1, tmy);
    if (data.resources ~= nil) then
      printNeed(data.resources, x + 1, index * 2);
      y = math.min(y + 1, tmy);
    end
  end
  term.setTextColor(colors.white);
end

local function printCost(cost, x, index)
  x = x or 1;
  index = index or 1;

  local _ , y = term.getCursorPos();
  for type, data in pairs(cost) do
    term.setCursorPos(x, y);
    term.setTextColor(index);
    print("Cost " .. data.cost .. " " .. type);
    y = math.min(y + 1, tmy);
    if (data.resources ~= nil) then
      printCost(data.resources, x + 1, index * 2);
      y = math.min(y + 1, tmy);
    end
  end
  term.setTextColor(colors.white);
end

local function craftCMD(a1, a2, a3)
  if (a1 == "list") then
    local filterType = a2;
    local index = 1;
    for _, recipe in ipairs(CraftingAPI.list()) do
      if (filterType ~= nil) then
        if (recipe.product:find(filterType)) then
          term.setTextColor(index);
          print(Localization.get("craftListItem"):format(recipe.product));
          index = math.max(index * 2 % 32768, 1);
        end
      else
        term.setTextColor(index);
        print(Localization.get("craftListItem"):format(recipe.product));
        index = math.max(index * 2 % 32768, 1);
      end
    end
  elseif (a1 == "new") then
    term.clear();
    term.setCursorPos(1, 1);
    write(Localization.get("craftNew"));
    doTasks = false;
    while true do
      local _, key = os.pullEvent("key");
      if (key == keys.enter) then break end
    end
    local items = inputPeriph.list();
    local resources = getResources(items);
    local product = getProduct(items);
    local count = getCount(items);
    CraftingAPI.add(CraftingAPI.Recipe(resources, product, count));
    for i = 1, 9 do
      local slot = toTurtleSlot[i];
      local item = items[slot];
      if (item ~= nil) then
        pullItems(resources[i], inputAddr, slot, item.count);
      end
    end
    pullItems(product, inputAddr, 16, count);
    term.clear();
    term.setCursorPos(1, 1);
    print(Localization.get("craftNewComplete"):format(product));
    doTasks = true;
  elseif (a1 == "delete") then
    local name = a2;
    if (name == nil) then
      write("Enter Name: ");
      name = read();
    end
    if (not CraftingAPI.exists(name)) then
      print(Localization.get("craftDelNoRecipe"));
      return
    end
    CraftingAPI.remove(name);
    print(Localization.get("craftDelRecipe"):format(name));
  elseif (a1 == "auto") then
    if (a2 == "list") then
      local filter = a3;
      printLookup(autoLookup, filter);
    elseif (a2 == "delete") then
      local type = a3;
      if (removeAuto(type)) then print("Removed " .. type .. ".");
      else print("Can't delete something that doesn't exist, no such autocraft."); end
    elseif (a2 == "pause") then
      doAutocrafting = not doAutocrafting;
      if (doAutocrafting) then print("Unpausing...");
      else print("Pausing..."); end
    else
      local name = a2;
      local count = a3;
      if (name == nil) then
        write("Enter Name: ");
        name = read();
      end
      if (count == nil) then
        write("Enter Count: ");
        count = read();
      end
      count = tonumber(count);
      if (CraftingAPI.exists(name)) then
        print(name .. " will now try to be autocrafted to reach " .. count);
        addAuto(name, count);
      else
        print("That isn't a valid recipe, how can I craft something of which does not exist...");
      end
    end
  elseif (a1 == "need") then
    local product = a2;
    local times = tonumber(a3 or "") or 1;
    if (product == nil) then
      write("Enter Recipe Name: ");
      product = read();
    end
    local recipe = CraftingAPI.get(product);
    if (recipe == nil) then
      print("No such Recipe.");
      return
    end
    local need = getTotalNeed(recipe, times);
    printNeed(need);
  elseif (a1 == "cost") then
    local product = a2;
    local times = tonumber(a3) or 1;
    if (product == nil) then
      write("Enter Recipe Name: ");
      product = read();
    end
    local recipe = CraftingAPI.get(product);
    if (recipe == nil) then
      print("No such Recipe.");
      return
    end
    local cost = getTotalCost(recipe, times);
    printCost(cost);
  else
    local want = nil;
    if (a2 ~= nil) then want = tonumber(a2) end
    doTasks = false;
    craft(a1, want);
    doTasks = true;
  end
end

local function listCMD(filter)
  printLookup(totalLookup, filter);
end

local function cleanCMD()
  for slot, item in pairs(SNAPI.list()) do
    if (not isFilterItem(item.name)) then
      local pushed = 0;
      for _, overflow in ipairs(overflowList) do
        local pushAmount = SNAPI.pushItems(overflow.addr, slot, item.count - pushed);
        pushed = pushed + pushAmount;
        if (pushed == item.count) then break end
      end
      addTotal(item.name, -pushed);
    end
  end
end

local function clearCMD()
  term.clear();
  term.setCursorPos(1, 1);
end

local function exitCMD()
  print(Localization.get("exit"));
  error();
end

local function pauseCMD()
  doTasks = not doTasks;
  if (not doTasks) then print(Localization.get("pause"));
  else print(Localization.get("unpause")); end
end

local function filterCMD()
  filterLookup = {};
  saveFilter();
  loadFilter();
end

local function dumpCMD(a1, a2)
  if (a1 == "list") then
    local filter = a2;
    printLookup(dumpLookup, filter);
  elseif (a1 == "delete") then
    local name = a2;
    if (name == nil) then
      write("Enter Name: ");
      name = read();
    end
    if (dumpLookup[name] == nil) then
      print("No such Item.");
      return
    end
    removeDump(name);
    print("Removed " .. name .. ".");
  else
    local name = a1;
    local countStr = a2;
    if (name == nil) then
      write("Enter Item Name: ")
      name = read();
    end
    if (countStr == nil) then
      write("Enter Amount: ");
      countStr = read();
    end
    local count = tonumber(countStr);
    if (count == nil) then
      print(countStr .. " is not a number...");
      return
    end
    write("If " .. name .. " is over " .. count .. " then dump it into lava? Y/N: ");
    local confirm = read():lower();
    while true do
      if (confirm == "y") then addDump(name, count); break
      elseif (confirm == "n") then break end
    end
  end
end

local function renderPC()
  term.clear();
  term.setCursorPos(1, 1);
  local history = {};
  while true do
    write("Input: ");
    local userInStr = read(nil, history);
    local userIn = TableUtils.toTable(userInStr, " ");
    local cmd = userIn[1];
    if (cmd == "craft") then craftCMD(userIn[2], userIn[3], userIn[4]);
    elseif (cmd == "list") then listCMD(userIn[2]);
    elseif (cmd == "clean") then cleanCMD();
    elseif (cmd == "clear") then clearCMD();
    elseif (cmd == "exit") then exitCMD();
    elseif (cmd == "pause") then pauseCMD();
    elseif (cmd == "filter") then filterCMD();
    elseif (cmd == "dump") then dumpCMD(userIn[2], userIn[3]); end
    if (#history >= 25) then table.remove(history, 1); end
    table.insert(history, userInStr);
  end
end

local function onAttach()
  while true do
    local _, addr = os.pullEvent("peripheral");
    table.insert(emptyList, PerUtils.get(addr));
  end
end

setup();
parallel.waitForAll(tasks, renderPC, onAttach);

