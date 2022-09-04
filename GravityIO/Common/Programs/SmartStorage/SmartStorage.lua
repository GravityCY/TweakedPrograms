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

local mainDirectory = "/data/smart_storage/";
local generalFile = mainDirectory .. "general";
local patternDirectory = mainDirectory .. "patterns/";
local localeDirectory = mainDirectory .. "locale/";
local filterDirectory = mainDirectory .. "inv_data/";

CraftingAPI.setSaveDirectory(patternDirectory);
Localization.setSaveDirectory(localeDirectory);
Localization.init();
CraftingAPI.init();

local inputAddr = nil;
local recipeAddr = nil;
local bufferAddr = nil;
local overflowType = nil;
local interfaceType = nil;

local args = {...};

local function reqInput(req)
  write(req);
  return read();
end

if (not fs.exists(generalFile)) then
  inputAddr = reqInput(Localization.get("inAddr"));
  recipeAddr = reqInput(Localization.get("recAddr"));
  bufferAddr = reqInput(Localization.get("bufAddr"));
  overflowType = reqInput(Localization.get("overType"));
  interfaceType = reqInput(Localization.get("interType"));
  local f = fs.open(generalFile, "w");
  f.writeLine(inputAddr);
  f.writeLine(recipeAddr);
  f.writeLine(bufferAddr);
  f.writeLine(overflowType);
  f.writeLine(interfaceType);
  f.close();
else
  local f = fs.open(generalFile, "r");
  inputAddr = f.readLine();
  recipeAddr = f.readLine();
  bufferAddr = f.readLine();
  overflowType = f.readLine();
  interfaceType = f.readLine();
  f.close();
end

local input = InvUtils.wrap(peripheral.wrap(inputAddr));
local patternRegister = InvUtils.wrap(peripheral.wrap(recipeAddr));
local overflowList = PerUtils.get(overflowType, true);
local interfaceList = InvUtils.wrapList(PerUtils.blacklistSides(PerUtils.get(interfaceType, true)));
local vault = InvUtils.wrap(peripheral.find("create:item_vault"));
local buffer = InvUtils.wrap(bufferAddr);
local vaultAddr = peripheral.getName(vault);

local modem = peripheral.find("modem", rednet.open);

local crafter = peripheral.find("turtle");
local monitor = peripheral.find("monitor");
monitor.setTextScale(0.5)

local crafterAddr = peripheral.getName(crafter);

-- A string indexed lookup table of peripheral addresses and their respective inventories
local invLookup = {};

local size = vault.size();
local mw, mh = monitor.getSize()

-- A list of list of filter items
-- filtersLookup["minecraft:chest_1"][1]
local filtersLookup = {};
-- A string indexed lookup table of item types and if they exist
-- filterLookup["minecraft:dirt"] ~= nil means it's a filter item
local filterLookup = {};
-- A string indexed lookup table of item types and their total amount in the storage
-- totalLookup["minecraft:dirt"] returns a total of dirt in the system
local totalLookup = {};

local function isFilterItem(type)
  return filterLookup[type] ~= nil
end

local function getTotal(type)
  return totalLookup[type];
end

local function getFilledSlots()
  local x = 0
  for _, _ in pairs(vault.list()) do x = x + 1 end
  return x
end

local function saveFilter()
  for _, inv in ipairs(interfaceList) do
    local name = peripheral.getName(inv);
    local format = string.gsub(name, ":", "_");
    local file = fs.open(filterDirectory .. format, "w");
    for slot, item in pairs(inv.list()) do
      file.writeLine(slot)
      file.writeLine(item.name)
    end
    file.close();
  end
end

local function loadFilter()
  local fileNames = fs.list(filterDirectory);
  for _, fileName in ipairs(fileNames) do

    -- minecraft_chest_1
    -- minecraft-chest_1
    local ui = fileName:find("_");
    local addr = fileName:sub(1, ui-1) .. ":" .. fileName:sub(ui+1);
    if (peripheral.wrap(addr) ~= nil) then
      filtersLookup[addr] = {};
      local filterFile = fs.open(filterDirectory .. fileName, "r");
      while true do
        local line = filterFile.readLine();
        if (line == nil) then break end
        local slot = tonumber(line);
        local type = filterFile.readLine();
        filterLookup[type] = true;
        filtersLookup[addr][slot] = type;
      end
      filterFile.close();
    else
      fs.delete(filterDirectory .. "/" .. fileName);
    end
  end
end

local function toOverflow(addr, slot, amount)
  local pulled = 0;
  for _, overflow in ipairs(overflowList) do
    local pull = overflow.pullItems(addr, slot, amount - pulled);
    pulled = pulled + pull;
    if (pulled == amount) then break end
  end
  return pulled;
end

local function addTotal(item, count)
  local name = item.name;
  for tag, _ in pairs(item.tags) do
    tag = "tag/"..tag;
    totalLookup[tag] = (totalLookup[tag] or 0) + count;
  end
  totalLookup[name] = (totalLookup[name] or 0) + count;
end

local function updateTotal()
  for _, item in pairs(vault.list()) do
    addTotal(item, item.count);
  end
end

local function pushItem(type, amount, addr, pushSlot)
  local pushed = 0;
  for slot, item in pairs(vault.list()) do
    if (item.name == type) then
      local push = vault.pushItems(addr, slot, amount - pushed, pushSlot);
      pushed = pushed + push;
      addTotal(item, -push);
      if (pushed == amount) then break end
    end
  end
  return pushed;
end

local function pullItems(type, addr, slot, amount)
  if (type == nil) then return end
  local pull = vault.pullItems(addr, slot, amount);
  if (pull == 0) then return end
  addTotal(type, pull);
end

local function doStore()
  for slot, item in pairs(input.list()) do
    if (isFilterItem(item.name)) then
      local pushed = input.pushItems(vaultAddr, slot, 64);
      addTotal(item.name, pushed);
    else toOverflow(inputAddr, slot, 64); end
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
        if (item == nil) then pushItem(type, common.maxCount, addr, slot); end
        if (item ~= nil and item.count < common.maxCount) then pushItem(type, common.maxCount - item.count, addr, slot) end
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

local function pullItem(type, addr, slot, amount)
  if (isFilterItem(type)) then
    pullItems(type, addr, slot, amount);
  else toOverflow(addr, slot, amount); end
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
      pushItem(type, times, crafterAddr, toCrafterSlot[slot]);
    end
    for slot, type in pairs(recipe.resources) do
      buffer.push(crafterAddr, type, times, toCrafterSlot[slot]);
    end
    rednet.broadcast(nil, "craft-start");
    rednet.receive("craft-end");
    for i = 1, 16 do
      if (sub) then
        buffer.pullItems(crafterAddr, i, 64);
      else
        pullItem(recipe.product, crafterAddr, i, 64);
        for slot, item in pairs(buffer.list()) do
          pullItem(item.name, bufferAddr, slot, 64);
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
      local items = patternRegister.list();
      local resources = getResources(items);
      local product = getProduct(items);
      local count = getCount(items);
      CraftingAPI.add(CraftingAPI.Recipe(resources, product, count));
      pullItem(resources[1], recipeAddr, 4, 64);
      pullItem(resources[2], recipeAddr, 5, 64);
      pullItem(resources[3], recipeAddr, 6, 64);
      pullItem(resources[4], recipeAddr, 13, 64);
      pullItem(resources[5], recipeAddr, 14, 64);
      pullItem(resources[6], recipeAddr, 15, 64);
      pullItem(resources[7], recipeAddr, 22, 64);
      pullItem(resources[8], recipeAddr, 23, 64);
      pullItem(resources[9], recipeAddr, 24, 64);
      pullItem(product, recipeAddr, 17, 64);
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

local function compute()
  updateTotal();
  while true do
    doStore();
    if (redstone.getInput("bottom")) then doRestock(); end
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
      for slot, item in pairs(vault.list()) do
        if (not isFilterItem(item.name)) then
          toOverflow(vaultAddr, slot, 64);
        end
      end
    elseif (cmd == "clear") then
      term.clear();
      term.setCursorPos(1, 1);
    end
    if (#history >= 25) then table.remove(history, 1); end
    table.insert(history, userInStr);
  end
end

local function main()
  for _, barrel in ipairs(interfaceList) do
    invLookup[peripheral.getName(barrel)] = barrel;
  end
  if (#args == 0) then
    loadFilter();
    parallel.waitForAll(compute, renderMonitor, renderPC)
  else
    local a1 = args[1];
    if (a1 == "filter") then
      saveFilter();
    end
  end
end

main();


