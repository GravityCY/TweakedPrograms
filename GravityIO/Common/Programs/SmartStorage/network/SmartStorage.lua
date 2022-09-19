-- TODO:
-- Auto Crafting DONE
-- Auto Crafting needs to ignore if you have enough resources and just try anyways
-- Custom Auto Crafting using Exporters
-- Importers / Exporters
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

local mainDirectory = "/data/smart_storage/";
local dataPath = mainDirectory .. "data";
local dumpData = mainDirectory .. "dumpData";
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
local recipeAddr = nil;
local overflowType = nil;
local interfaceType = nil;
local storageType = nil;
local crafterAddr = nil;
local dumperAddr = nil;

-- Peripherals
local monitor = nil;
local inputPeriph = nil;
local recipePeriph = nil;
local overflowList = nil;
local interfaceList =nil;
local storageList = nil;
local enablePeriph = nil;
local modemPeriph = nil;
local crafterTurtle = nil;
local dumperTurtle = nil;

local size = nil;
local mx, my = nil, nil;

local isRestocking = false;
local isAutocrafting = false;
local renderSleep = 3;
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
-- A string indexed lookup table of item tags and their total amount in the storage
-- tagLookup["minecraft:planks"] returns a total of planks in the system
local tagLookup = {};

local toCrafterSlot = {1, 2, 3, 5, 6, 7, 9, 10, 11};
local toRegisterSlot = {4, 5, 6, 13, 14, 15, 22, 23, 24};

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
  local f = fs.open(dataPath, "r");
  inputAddr = f.readLine();
  redEnableAddr = f.readLine();
  overflowType = f.readLine();
  interfaceType = f.readLine();
  recipeAddr = f.readLine();
  storageType = f.readLine();
  crafterAddr = f.readLine();
  dumperAddr = f.readLine();
  f.close();
end

local function saveData()
  detectUI("Input Inventory: ");
  inputAddr = getPeripheral();
  detectUI("Red Router Activation Block: ");
  redEnableAddr = getPeripheral();
  detectUI("Overflow Inventory\nJust Select 1 of the Inventories to Internally save the Type.");
  overflowType = peripheral.getType(getPeripheral());
  detectUI("Interface Inventory\nJust Select 1 of the Inventories to Internally save the Type.");
  interfaceType = peripheral.getType(getPeripheral());
  detectUI("Recipe Register Inventory: ");
  recipeAddr = getPeripheral();
  detectUI("Storage Inventory\nJust Select 1 of the Inventories to Internally save the Type.");
  storageType = peripheral.getType(getPeripheral());
  detectUI("Crafter Turtle: ");
  crafterAddr = getPeripheral();
  detectUI("Dumper Turtle: ");
  dumperAddr = getPeripheral();

  local f = fs.open(dataPath, "w");
  f.writeLine(inputAddr);
  f.writeLine(redEnableAddr);
  f.writeLine(overflowType);
  f.writeLine(interfaceType);
  f.writeLine(recipeAddr);
  f.writeLine(storageType);
  f.writeLine(crafterAddr);
  f.writeLine(dumperAddr);
  f.close();
end

local function loadDump()
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

  inputPeriph = InvUtils.wrap(PerUtils.get(inputAddr));
  recipePeriph = InvUtils.wrap(PerUtils.get(recipeAddr));
  overflowList = PerUtils.getType(overflowType, true);
  interfaceList = InvUtils.wrapList(PerUtils.blacklistSides(PerUtils.getType(interfaceType, true)));
  storageList = PerUtils.getType(storageType, true);
  enablePeriph = PerUtils.get(redEnableAddr);
  modemPeriph = peripheral.find("modem", rednet.open);
  crafterTurtle = PerUtils.get(crafterAddr);
  dumperTurtle = PerUtils.get(dumperAddr);
  monitor = peripheral.find("monitor");

  monitor.setTextScale(0.5)
  mx, my = monitor.getSize();

  for _, p in ipairs(storageList) do SNAPI.add(peripheral.getName(p)); end
  function crafterTurtle.list()
    rednet.send(22, nil, "list-start");
    local _, message = rednet.receive("list-end");
    return message;
  end
  size = SNAPI.size();
  updateTotal();
end

local function isFilterItem(type)
  return filterLookup[type] ~= nil
end

local function getFilledSlots()
  local x = 0
  for _, _ in pairs(SNAPI.list()) do x = x + 1 end
  return x
end

local function toOverflow(fromAddr, slot, amount)
  local pushed = 0;
  for _, overflow in ipairs(overflowList) do
    local push = 0;
    if (fromAddr == "snapi") then
      push = SNAPI.pushItems(overflow.addr, slot, amount - pushed);
    else
      push = overflow.pullItems(fromAddr, slot, amount - pushed);
    end
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

local function toList()
  local t = {}
  local index = 1
  for type, count in pairs(totalLookup) do
    t[index] = {name=type, count=count}
    index = index + 1
  end
  table.sort(t, function(x, y) return x.count > y.count end)
  return t
end

local function pprint(...)
  if (doPrint) then print(...); end
end

local function printLookup(lookup, filter)
  term.clear();
  term.setCursorPos(1, 1);
  for type, count in pairs(lookup) do
    if (filter ~= nil) then
      if (type:find(filter)) then
        print(Localization.get("listItem"):format(count, type))
      end
    else
      print(Localization.get("listItem"):format(count, type));
    end
  end
end

local function printMonitor(str, color)
  local _, y = monitor.getCursorPos();
  local pc = monitor.getTextColor();
  monitor.setTextColor(color or pc);
  monitor.write(str)
  monitor.setCursorPos(1, y+1);
  monitor.setTextColor(pc);
end

local function printItems()
  local x = 2;
  local column = 1;
  for _, item in pairs(toList()) do
    local _, cy = monitor.getCursorPos();
    if (item.count > 0) then
      if (cy ~= my) then
        monitor.setCursorPos(x, cy);
        printMonitor(Localization.get("monitorItemLine"):format(item.count, ItemUtils.format(item.name)));
      else
        if (column == 2) then break end
        column = column + 1;
        x = mx / 2;
        monitor.setCursorPos(x, 6);
      end
    end
  end
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

-- Gets how much you'd need to craft
local function getNeed(cost, usedLookup)
  usedLookup = usedLookup or {};
  local need = {};
  for name, count in pairs(cost) do
    local total = getTotal(name);
    need[name] = math.max(count - total + (usedLookup[name] or 0), 0);
  end
  return need;
end

local function getResources(items)
  local resources = {};
  for i = 1, 9 do
    local item = items[toRegisterSlot[i]];
    if (item ~= nil) then resources[i] = item.name; end
  end
  return resources;
end

local function getProduct(items)
  if (items[17] ~= nil) then return items[17].name; end
end

local function getCount(items)
  if (items[17] ~= nil) then return items[17].count; end
end

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
        push(crafterAddr, type, math.min(smallest, times - sent), toCrafterSlot[i]);
      end
      sent = sent + smallest;
      rednet.send(22, nil, "craft-start");
      rednet.receive("craft-end");
      for slot, item in pairs(crafterTurtle.list()) do
        pullItems(item.name, crafterAddr, slot, 64);
      end
    end
  end
end

local function doStore()
  for slot, item in pairs(inputPeriph.list()) do
    if (isFilterItem(item.name)) then
      pullItems(item.name, inputAddr, slot, 64);
    else toOverflow(inputAddr, slot, 64); end
  end
end

local function doRestock()
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

local function doDump()
  for item, dump in pairs(dumpLookup) do
    local total = totalLookup[item];
    if (total ~= nil and total >= dump) then
      push(dumperAddr, item, total - dump);
    end
  end
end

local function doCraft()
  if (not isAutocrafting) then return end

  doPrint = false;
  for type, req in pairs(autoLookup) do
    local total = getTotal(type);
    if (total < req) then craft(type, req - total); end
  end
  doPrint = true;
end

local function tasks()
  while true do
    if (isRestocking) then sleep(1);
    else
      parallel.waitForAll(doStore, doDump, doCraft)
      if (enablePeriph.getInput("top")) then doRestock(); end
    end
  end
end

local function renderMonitor() 
  local filledSlots = 0;
  while true do
    local newFilledSlots = getFilledSlots();
    monitor.clear();
    monitor.setCursorPos(1,1);
    monitor.setCursorBlink(false);
    local centColor = colors.lightGray;
    local slotColor = colors.lightGray;
    if (newFilledSlots > filledSlots) then
      centColor = colors.green;
      slotColor = colors.red;
    elseif (newFilledSlots < filledSlots) then
      centColor = colors.red;
      slotColor = colors.green;
    end
    printMonitor(Localization.get("fillPercentText"));
    printMonitor(Localization.get("fillPercentNum"):format(newFilledSlots / size * 100), centColor);
    printMonitor(Localization.get("freeSlotsText"));
    printMonitor(Localization.get("freeSlotsNum"):format(size - newFilledSlots), slotColor);
    printMonitor(Localization.get("itemsStored"));
    printItems();
    filledSlots = newFilledSlots;
    sleep(renderSleep);
  end
end

local function craftCMD(a1, a2, a3)
  if (a1 == "list") then
    local filterType = a2;
    for _, recipe in ipairs(CraftingAPI.list()) do
      if (filterType ~= nil) then
        if (recipe.product:find(filterType)) then
          print(Localization.get("craftListItem"):format(recipe.product));
        end
      else print(Localization.get("craftListItem"):format(recipe.product)); end
    end
  elseif (a1 == "new") then
    print(Localization.get("craftNew1"));
    print(Localization.get("craftNew2"));
    read();
    local items = recipePeriph.list();
    local resources = getResources(items);
    local product = getProduct(items);
    local count = getCount(items);
    CraftingAPI.add(CraftingAPI.Recipe(resources, product, count));
    for i = 1, 9 do
      local slot = toRegisterSlot[i];
      local item = items[slot];
      if (item ~= nil) then
        pullItems(resources[i], recipeAddr, slot, 64);
      end
    end
    pullItems(product, recipeAddr, 17, 64);
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
      if (autoLookup[type] == nil) then
        print("Can't delete something that doesn't exist, no such autocraft.");
        return
      end
      autoLookup[type] = nil;
      print("Removed " .. type .. ".");
    elseif (a2 == "pause") then
      isAutocrafting = not isAutocrafting;
      if (isAutocrafting) then print("Unpausing...");
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
        autoLookup[name] = count;
      else
        print("That isn't a valid recipe, how can I craft something of which does not exist...");
      end
    end
  else
    local want = nil;
    if (a2 ~= nil) then want = tonumber(a2) end
    isRestocking = true;
    craft(a1, want);
    isRestocking = false;
  end
end

local function listCMD(filter)
  printLookup(totalLookup, filter);
end

local function cleanCMD()
  for slot, item in pairs(SNAPI.list()) do
    if (not isFilterItem(item.name)) then
      toOverflow("snapi", slot, 64);
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
  isRestocking = not isRestocking;
  if (isRestocking) then print(Localization.get("pause"));
  else print(Localization.get("unpause")); end
end

local function filterCMD()
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
      if (dumpLookup[name] == nil) then
        print("No such Item.");
        return
      end
      removeDump(name);
      print("Removed " .. name .. ".");
    end
  else
    local name = a1;
    local count = a2;
    if (name == nil) then
      write("Enter Item Name: ")
      name = read();
    end
    if (count == nil) then
      write("Enter Amount: ");
      count = read();
    end
    count = tonumber(count);
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

setup();
parallel.waitForAll(tasks, renderMonitor, renderPC)

