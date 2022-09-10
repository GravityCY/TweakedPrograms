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
local bufferAddr = nil;
local crafterAddr = nil;
local dumperAddr = nil;

-- Peripherals
local monitor = nil;
local inputPeriph = nil;
local recipePeriph = nil;
local bufferPeriph = nil;
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

local function isFilterItem(type)
  return filterLookup[type] ~= nil
end

local function getTotal(type)
  return totalLookup[type];
end

local function getFilledSlots()
  local x = 0
  for _, _ in pairs(SNAPI.list()) do x = x + 1 end
  return x
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

local function getPeripheral(obj)
  local t = type(obj);
  if (t == "string") then return peripheral.wrap(obj);
  elseif (t == "table") then return obj; end
end

local function toOverflow(from, slot, amount)
  local pushed = 0;
  for _, overflow in ipairs(overflowList) do
    local addr = peripheral.getName(overflow);
    local push = from.pushItems(addr, slot, amount - pushed);
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
  if (isFilterItem(type)) then
    local pulled = SNAPI.pullItems(addr, fromSlot, amount);
    addTotal(type, pulled);
  else toOverflow(addr, fromSlot, amount); end
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

local function doStore()
  for slot, item in pairs(inputPeriph.list()) do
    if (isFilterItem(item.name)) then
      pullItems(item.name, inputAddr, slot, 64);
    else toOverflow(inputPeriph, slot, 64); end
  end
end

local function doRestock()
  for addr, filterList in pairs(filtersLookup) do
    local interface = invLookup[addr];
    local interfaceItems = interface.list();
    for slot, type in pairs(filterList) do
      local item = interfaceItems[slot];
      local common = ItemUtils.get(type);
      local count = getTotal(type);
      if (count ~= nil and count > 0) then
        if (item == nil) then 
          push(addr, type, common.maxCount, slot)
        end
        if (item ~= nil and item.count < common.maxCount) then 
          push(addr, type, common.maxCount - item.count, slot);
        end
      end
    end
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

local function getNeed(cost)
  local need = {};
  for name, count in pairs(cost) do
    local total = getTotal(name) or 0;
    local needVal = count - total;
    if (needVal < 0) then needVal = 0; end
    need[name] = needVal;
  end
  return need;
end

local function getResources(items)
  local temp = {};
  local resources = {};
  temp[1] = items[4];
  temp[2] = items[5];
  temp[3] = items[6];
  temp[4] = items[13];
  temp[5] = items[14];
  temp[6] = items[15];
  temp[7] = items[22];
  temp[8] = items[23];
  temp[9] = items[24];
  for i = 1, 9 do
    local item = temp[i];
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

local toCrafterSlot = {1, 2, 3, 5, 6, 7, 9, 10, 11};

-- Check Stack Sizes
local function craft(product, want, sub)
  if (sub == nil) then sub = false; end
  if (CraftingAPI.exists(product)) then
    local recipe = CraftingAPI.get(product);
    local common = ItemUtils.get(recipe.product);
    if (want == nil) then want = recipe.count; end
    local times = math.ceil(want / recipe.count);
    local count = times * recipe.count;
    local costLookup = CraftingAPI.total(recipe, times);
    local needLookup = getNeed(costLookup);
    for type, need in pairs(needLookup) do
      if (need ~= 0) then
        print((Localization.get("craftNotEnough")):format(ItemUtils.format(type)));
        if (CraftingAPI.exists(type)) then
          print(Localization.get("craftHasSub"));
          print(Localization.get("craftWithSub"));
          if (not craft(type, need, true)) then return false; end
        else return false; end
      end
    end
    print((Localization.get("craftRecipe")):format(count, product));
    for slot, type in pairs(recipe.resources) do
      push(crafterAddr, type, times, toCrafterSlot[slot]);
    end
    for slot, type in pairs(recipe.resources) do
      bufferPeriph.push(crafterAddr, type, times, toCrafterSlot[slot]);
    end
    rednet.broadcast(nil, "craft-start");
    rednet.receive("craft-end");
    for i = 1, 16 do
      if (sub) then
        bufferPeriph.pullItems(crafterAddr, i, 64);
      else
        pullItems(recipe.product, crafterAddr, i, 64);
        for slot, item in pairs(bufferPeriph.list()) do
          pullItems(item.name, bufferAddr, slot, 64);
        end
      end
    end
    print((Localization.get("craftedRecipe"):format(count, product)));
    return true;
  else
    print("No such Pattern.");
  end
end

local function craftCMD(a1, a2)
  if (a1 == "list") then
    for _, recipe in ipairs(CraftingAPI.list()) do
      if (a2 ~= nil) then
        if (recipe.product:find(a2)) then
          print(recipe.product);
        end
      else print(recipe.product); end
    end
    elseif (a1 == "new") then
      print("When Ready, Add the Pattern into the Pattern Register");
      sleep(0.2);
      while true do
        local _, key = os.pullEvent("key_up");
        if (key == keys.enter) then break end
      end
      local items = recipePeriph.list();
      local resources = getResources(items);
      local product = getProduct(items);
      local count = getCount(items);
      CraftingAPI.add(CraftingAPI.Recipe(resources, product, count));
      pullItems(resources[1], recipeAddr, 4, 64);
      pullItems(resources[2], recipeAddr, 5, 64);
      pullItems(resources[3], recipeAddr, 6, 64);
      pullItems(resources[4], recipeAddr, 13, 64);
      pullItems(resources[5], recipeAddr, 14, 64);
      pullItems(resources[6], recipeAddr, 15, 64);
      pullItems(resources[7], recipeAddr, 22, 64);
      pullItems(resources[8], recipeAddr, 23, 64);
      pullItems(resources[9], recipeAddr, 24, 64);
      pullItems(product, recipeAddr, 17, 64);
    else
      local want = nil;
      if (a2 ~= nil) then want = tonumber(a2) end
      craft(a1, want);
    end
end

local function listCMD(a1)
  for type, count in pairs(totalLookup) do
    if (a1 ~= nil) then
      if (type:find(a1)) then
        print(("%d %s"):format(count, type))
      end
    else
      print(("%d %s"):format(count, type));
    end
  end
end

local function doDump()
  for item, req in pairs(reqLookup) do
    local total = totalLookup[item];
    if (total ~= nil and total >= req) then
      pushItems(item, total - req, dumperAddr);
    end
  end
end

local function tasks()
  updateTotal();
  while true do
    if (isPaused) then sleep(1);
    else
      doStore();
      doDump();
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
    sleep(10);
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
    elseif (cmd == "clean") then
      for slot, item in pairs(SNAPI.list()) do
        if (not isFilterItem(item.name)) then
          toOverflow(SNAPI, slot, 64);
        end
      end
    elseif (cmd == "clear") then
      term.clear();
      term.setCursorPos(1, 1);
    elseif (cmd == "exit") then
      print("Goodbye...");
      error();
    elseif (cmd == "pause") then
      isPaused = not isPaused;
      if (isPaused) then print("Pausing...");
      else print("Unpausing..."); end
    elseif (cmd == "filter") then
      saveFilter();
      loadFilter();
    elseif (cmd == "dump") then
      write("Enter Item Name: ")
      local itemName = read();
      write("Enter Amount: ");
      local itemAmount = tonumber(read());
      write("If " .. itemName .. " is over " .. itemAmount .. " then dump it into lava? Y/N: ");
      local confirm = read():lower();
      while true do
        if (confirm == "y") then
          reqLookup[itemName] = itemAmount;
          break
        elseif (confirm == "n") then break end
      end
    end
    if (#history >= 25) then table.remove(history, 1); end
    table.insert(history, userInStr);
  end
end

local function main()
  for _, barrel in ipairs(interfaceList) do
    invLookup[peripheral.getName(barrel)] = barrel;
  end
  loadFilter();
  parallel.waitForAll(tasks, renderMonitor, renderPC)
end

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
    pdui("Buffer Inventory: ");
    bufferAddr = getPeripheral();
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
    f.writeLine(bufferAddr);
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
    bufferAddr = f.readLine();
    crafterAddr = f.readLine();
    dumperAddr = f.readLine();
    f.close();
  end
  inputPeriph = InvUtils.wrap(peripheral.wrap(inputAddr));
  recipePeriph = InvUtils.wrap(peripheral.wrap(recipeAddr));
  bufferPeriph = InvUtils.wrap(bufferAddr);
  overflowList = PerUtils.get(overflowType, true);
  interfaceList = InvUtils.wrapList(PerUtils.blacklistSides(PerUtils.get(interfaceType, true)));
  storageList = {peripheral.find(storageType)};
  enablePeriph = peripheral.wrap(redEnableAddr);
  modemPeriph = peripheral.find("modem", rednet.open);
  crafterTurtle = peripheral.wrap(crafterAddr);
  dumperTurtle = peripheral.wrap(dumperAddr);
  monitor = peripheral.find("monitor");

  for _, p in ipairs(storageList) do SNAPI.add(peripheral.getName(p)); end

  monitor.setTextScale(0.5)
  size = SNAPI.size();
  mw, mh = monitor.getSize();
end

setup();
main();


