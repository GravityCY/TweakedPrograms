-- TODO:
-- Auto Crafting
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

local args = {...};
local isPaused = false;
local renderSleep = 3;

local mainDirectory = "/data/smart_storage/";
local dataPath = mainDirectory .. "data";
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
local mw, mh = nil, nil;

-- A string indexed lookup table of peripheral addresses and their respective inventories
local invLookup = {};
-- A list of list of filter items
-- filtersLookup["minecraft:chest_1"][1]
local filtersLookup = {};
-- A string indexed lookup table of item types and if they exist
-- filterLookup["minecraft:dirt"] ~= nil means it's a filter item
local filterLookup = {};
-- A string indexed lookup table of item types and their total amount in the storage
-- totalLookup["minecraft:dirt"] returns a total of dirt in the system
local totalLookup = {};
local reqLookup = {};
-- A string indexed lookup table of item tag and their total amount in the storage
-- tagLookup["minecraft:dirt"] returns a total of dirt in the system
local tagLookup = {};

local function getPeripheral()
  local _, addr = os.pullEvent("peripheral");
  sleep(0);
  return addr;
end

local function pdui(current)
  term.clear();
  term.setCursorPos(1, 1);
  print("------------ Peripheral Detection Mode ------------");
  print("")
  print("Will detect any Peripheral being enabled.");
  print();
  print("Enable a Modem by Right Clicking it while inactive");
  print("Please Select: " .. current);
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

local function setup()
  if (not fs.exists(dataPath)) then
    pdui("Input Inventory: ");
    inputAddr = getPeripheral();
    pdui("Red Router Activation Block: ");
    redEnableAddr = getPeripheral();
    pdui("Overflow Inventory\nJust Select 1 of the Inventories to Internally save the Type.");
    overflowType = peripheral.getType(getPeripheral());
    pdui("Interface Inventory\nJust Select 1 of the Inventories to Internally save the Type.");
    interfaceType = peripheral.getType(getPeripheral());
    pdui("Recipe Register Inventory: ");
    recipeAddr = getPeripheral();
    pdui("Storage Inventory\nJust Select 1 of the Inventories to Internally save the Type.");
    storageType = peripheral.getType(getPeripheral());
    pdui("Crafter Turtle: ");
    crafterAddr = getPeripheral();
    pdui("Dumper Turtle: ");
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
  else
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

  for _, p in ipairs(storageList) do SNAPI.add(peripheral.getName(p)); end

  monitor.setTextScale(0.5)
  size = SNAPI.size();
  mw, mh = monitor.getSize();

  function crafterTurtle.list()
    rednet.send(22, nil, "list-start");
    local _, message = rednet.receive("list-end");
    return message;

  end

  for _, barrel in ipairs(interfaceList) do invLookup[barrel.addr] = barrel; end
  loadFilter();
end

local function isFilterItem(type)
  return filterLookup[type] ~= nil
end

local function getTotal(type)
  return totalLookup[type] or 0;
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

local function addTotal(name, count)
  local common = ItemUtils.get(name);
   if (common.tags ~= nil) then
    for tag, _ in pairs(common.tags) do
      tagLookup[tag] = (tagLookup[tag] or 0) + count;
    end
  end
  totalLookup[name] = (totalLookup[name] or 0) + count;
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

local function updateTotal()
  for _, item in pairs(SNAPI.list()) do
    addTotal(item.name, item.count);
  end
end

local function toList()
  local t = {}
  local index = 1
  for item, count in pairs(totalLookup) do
    t[index] = {name=item, count=count}
    index = index + 1
  end
  table.sort(t, function(x, y) return x.count > y.count end)
  return t
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
    local length, height = monitor.getCursorPos()
    if item.count > 64 then
      if height ~= mh then
        monitor.setCursorPos(x, height);
        printMonitor(item.count .." ".. ItemUtils.format(item.name));
      else
        if (column == 2) then break end
        column = column + 1;
        x = mw / 2;
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
  for item, req in pairs(reqLookup) do
    local total = totalLookup[item];
    if (total ~= nil and total >= req) then
      parallel.waitForAll(push(dumperAddr, item, total - req));
    end
  end
end

local function tasks()
  updateTotal();
  while true do
    if (isPaused) then sleep(1);
    else
      parallel.waitForAll(doStore, doDump)
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
    printMonitor("Storage Fill Percent:")
    printMonitor(string.format("%.2f%%", newFilledSlots / size * 100), centColor);
    printMonitor("Free Slots:");
    printMonitor(size - newFilledSlots, slotColor);
    printMonitor("Items Stored:");
    printItems();
    filledSlots = newFilledSlots;
    sleep(renderSleep);
  end
end

local toCrafterSlot = {1, 2, 3, 5, 6, 7, 9, 10, 11};

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

local toRegisterSlot = {4, 5, 6, 13, 14, 15, 22, 23, 24};

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
      print(("Need %d more %s"):format(need, type));
      if (sub ~= nil) then
        if (not isEnough(sub, math.ceil(need / sub.count), parentUsed)) then
          print(("Don't have enough to craft %d %s"):format(need, type));
          return false;
        end
      else
        print(("%s is not a subrecipe"):format(type));
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
      print(("Crafting %d %s"):format(count, product))
    else
      print(("Crafting %d %s for parent recipe."):format(count, product))
    end
    for type, need in pairs(needLookup) do
      if (need ~= 0) then
        print(("Need %d %s"):format(need, type));
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
    for x = 1, math.ceil(times / smallest) do
      for i, type in pairs(recipe.resources) do
        push(crafterAddr, type, math.min(smallest, times - sent), toCrafterSlot[i]);
      end
      sent = sent + smallest;
      rednet.send(22, nil, "craft-start");
      rednet.receive("craft-end");
      local turtleItems = crafterTurtle.list();
      for slot, item in pairs(turtleItems) do
        pullItems(recipe.product, crafterAddr, slot, 64);
      end
    end
  end
end

local function craftCMD(a1, a2)
  if (a1 == "list") then
    local filterType = a2;
    for _, recipe in ipairs(CraftingAPI.list()) do
      if (filterType ~= nil) then
        if (recipe.product:find(filterType)) then
          print(recipe.product);
        end
      else print(recipe.product); end
    end
    elseif (a1 == "new") then
      print("Add the recipe into the Recipe Register.");
      print("Press Enter when Done");
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
    elseif (a1 == "del") then
      local name = a2;
      if (name == nil) then
        write("Enter Name: ");
        name = read();
      end
      if (not CraftingAPI.exists(name)) then
        print("No such Crafting Recipe.");
        return
      end
      CraftingAPI.remove(name);
      print("Removed " .. name);
    else
      local want = nil;
      if (a2 ~= nil) then want = tonumber(a2) end
      isPaused = true;
      craft(a1, want);
      isPaused = false;
    end
end

local function listCMD(filterType)
  for type, count in pairs(totalLookup) do
    if (filterType ~= nil) then
      if (type:find(filterType)) then
        print(("%d %s"):format(count, type))
      end
    else
      print(("%d %s"):format(count, type));
    end
  end
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
  print("Goodbye...");
  error();
end

local function pauseCMD()
  isPaused = not isPaused;
  if (isPaused) then print("Pausing...");
  else print("Unpausing..."); end
end

local function filterCMD()
  saveFilter();
  loadFilter();
end

local function dumpCMD(name, amount)
  if (name == nil) then
    write("Enter Item Name: ")
    name = read();
  end
  if (amount == nil) then
    write("Enter Amount: ");
    amount = tonumber(read());
  end
  write("If " .. name .. " is over " .. amount .. " then dump it into lava? Y/N: ");
  local confirm = read():lower();
  while true do
    if (confirm == "y") then
      reqLookup[name] = amount;
      break
    elseif (confirm == "n") then break end
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
    if (cmd == "craft") then craftCMD(userIn[2], userIn[3]);
    elseif (cmd == "list") then listCMD(userIn[2]);
    elseif (cmd == "clean") then cleanCMD();
    elseif (cmd == "clear") then clearCMD();
    elseif (cmd == "exit") then exitCMD();
    elseif (cmd == "pause") then pauseCMD();
    elseif (cmd == "filter") then filterCMD();
    elseif (cmd == "dump") then dumpCMD(); end
    if (#history >= 25) then table.remove(history, 1); end
    table.insert(history, userInStr);
  end
end

setup();
parallel.waitForAll(tasks, renderMonitor, renderPC)

