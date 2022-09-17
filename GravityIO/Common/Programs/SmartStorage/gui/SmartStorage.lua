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
local Basalt = require("basalt");

local mainDirectory = "/data/smart_storage/";
local dataPath = mainDirectory .. "data";
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
local redEnableAddr = nil;
local overflowType = nil;
local interfaceType = nil;

local paused = false;

local function getPeripheral()
  local _, addr = os.pullEvent("peripheral");
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

if (not fs.exists(dataPath)) then
  pdui("Input Inventory");
  inputAddr = getPeripheral();
  pdui("Recipe Register Inventory: ");
  recipeAddr = getPeripheral();
  pdui("Buffer Inventory");
  bufferAddr = getPeripheral();
  pdui("Overflow Inventory\nJust Select 1 of the Inventories to Internally save the Type.");
  overflowType = peripheral.getType(getPeripheral());
  pdui("Interface Inventory\nJust Select 1 of the Inventories to Internally save the Type.");
  interfaceType = peripheral.getType(getPeripheral());
  pdui("Red Router Activation Block");
  redEnableAddr = getPeripheral();
  local f = fs.open(dataPath, "w");
  f.writeLine(inputAddr);
  f.writeLine(recipeAddr);
  f.writeLine(bufferAddr);
  f.writeLine(overflowType);
  f.writeLine(interfaceType);
  f.writeLine(redEnableAddr);
  f.close();
else
  local f = fs.open(dataPath, "r");
  inputAddr = f.readLine();
  recipeAddr = f.readLine();
  bufferAddr = f.readLine();
  overflowType = f.readLine();
  interfaceType = f.readLine();
  redEnableAddr = f.readLine();
  f.close();
end

local input = InvUtils.wrap(peripheral.wrap(inputAddr));
local recipeReg = InvUtils.wrap(peripheral.wrap(recipeAddr));
local buffer = InvUtils.wrap(bufferAddr);
local overflowList = PerUtils.getType(overflowType, true);
local interfaceList = InvUtils.wrapList(PerUtils.blacklistSides(PerUtils.getType(interfaceType, true)));
local vault = InvUtils.wrap(peripheral.find("create:item_vault"));
local vaultAddr = peripheral.getName(vault);
local redEnable = peripheral.wrap(redEnableAddr);

peripheral.find("modem", rednet.open);

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
local totalLookupItem = {};
-- A string indexed lookup table of item tag and their total amount in the storage
-- tagLookup["minecraft:dirt"] returns a total of dirt in the system
local totalLookupTag = {};

local function isFilterItem(type)
  return filterLookup[type] ~= nil
end

local function getTotal(type)
  local total = totalLookupItem[type];
  if (total == nil) then
    totalLookupItem[type] = 0;
    total = 0;
  end
  return total;
end

local function getTotalTag(tag)
  local total = totalLookupTag[tag];
  if (total == nil) then
    totalLookupTag[tag] = 0;
    total = 0;
  end
  return total;
end

local function getFilledSlots()
  local x = 0
  for _, _ in pairs(vault.list()) do x = x + 1 end
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

local function toOverflow(addr, slot, amount)
  local pulled = 0;
  for _, overflow in ipairs(overflowList) do
    local pull = overflow.pullItems(addr, slot, amount - pulled);
    pulled = pulled + pull;
    if (pulled == amount) then break end
  end
  return pulled;
end

local function addTotal(type, count)
  if (type == nil) then return end
  local common = ItemUtils.get(type);
  if (common == nil) then print("NO COMMON FOR" .. type); end
  if (common.tags ~= nil) then
    for tag, _ in pairs(common.tags) do
      totalLookupTag[tag] = getTotalTag(tag) + count;
    end
  end
  totalLookupItem[type] = getTotal(type) + count;
end

local function updateTotal()
  for _, item in pairs(vault.list()) do
    addTotal(item.name, item.count);
  end
end

local function pushItem(type, amount, addr, pushSlot)
  local pushed = 0;
  for slot, item in pairs(vault.list()) do
    if (item.name == type) then
      local push = vault.pushItems(addr, slot, amount - pushed, pushSlot);
      pushed = pushed + push;
      addTotal(item.name, -push);
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
  for item, count in pairs(totalLookupItem) do
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
      local items = recipeReg.list();
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
  for type, count in pairs(totalLookupItem) do
    if (a1 ~= nil) then
      if (type:find(a1)) then
        print(("%d %s"):format(count, type))
      end
    else
      print(("%d %s"):format(count, type));
    end
  end
end

local function tasks()
  while true do
    if (paused) then sleep(1);
    else
      doStore();
      if (redEnable.getInput("top")) then doRestock(); end
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

local function main()
  for _, barrel in ipairs(interfaceList) do
    invLookup[peripheral.getName(barrel)] = barrel;
  end
  loadFilter();
  updateTotal();

  local mainFrame = nil;
  local craftFrame = nil;
  local listFrame = nil;
  local craftListFrame = nil;
  local itemListFrame = nil;
  local history = {};

  local craftButtons = {};
  local craftingRecipes = {};
  local shownButtons = {};

  local wspacing, hspacing = 5, 1;
  local width, height = 0, 3;
  local columns = 2;
  local biggest = 0;

  local itemFrames = {};
  local itemNames = {};
  local shownItems = {};

  local function onCraft(self)
    craft(craftingRecipes[self.getValue()]);
  end

  local function updateShown()
    local index = 1;
    for _, button in pairs(shownButtons) do
      local column, row = index % columns, math.ceil(index / columns);
      if (column == 0) then column = columns; end
      local x, y = (column - 1) * width + (column - 1) * wspacing + 1, (row - 1) * height + (row - 1) * hspacing + 1;
      button:setPosition(x, y);
      index = index + 1;
    end
  end
  local function updateShownItems()
    local index = 1;
    for _, itemFrame in pairs(shownItems) do
      local column, row = index % columns, math.ceil(index / columns);
      if (column == 0) then column = columns; end
      local x, y = (column - 1) * width + (column - 1) * wspacing + 1, (row - 1) * height + (row - 1) * hspacing + 1;
      itemFrame:setPosition(x, y);
      index = index + 1;
    end
  end
  
  Basalt.setVariable("onFilterClick", 
    function()
      saveFilter();
      loadFilter();
    end
  )
  Basalt.setVariable("onPauseClick", 
    function(self)
      paused = not paused;
      if (paused) then
        self:setValue("Start")
        self:setBackground(colors.green);
      else
        self:setBackground(colors.red);
        self:setValue("Pause")
      end
    end
  )
  Basalt.setVariable("onBackClick", 
    function()
      table.remove(history, #history);
      if (#history == 0) then mainFrame:show();
      else history[#history]:show(); end
    end
  )
  Basalt.setVariable("onCraftClick",
  function()
    table.insert(history, craftFrame);
    craftFrame:show();
  end
  )
  Basalt.setVariable("onListClick",
  function()
    table.insert(history, listFrame);
    listFrame:show();
  end
  )
  Basalt.setVariable("onCleanClick",
  function()
    Basalt.debug("CLEAN");
  end
  )
  Basalt.setVariable("onSearch",
    function(inputObj)
      local search = inputObj:getValue()
      for index, craftBtn in ipairs(craftButtons) do
        if (not craftBtn:getValue():lower():find(search:lower())) then
          craftBtn:hide();
          shownButtons[index] = nil;
        else
          if (shownButtons[index] == nil) then
            shownButtons[index] = craftBtn;
            craftBtn:show();
          end
        end
      end
      updateShown()
    end
  )
  Basalt.setVariable("onSearchList",
    function(inputObj)
      local search = inputObj:getValue()
      for index, itemFrame in ipairs(itemFrames) do
        if (not itemFrame:getObject("item"):getValue():lower():find(search:lower())) then
          itemFrame:hide();
          shownItems[index] = nil;
        else
          if (shownItems[index] == nil) then
            shownItems[index] = itemFrame;
            itemFrame:show();
          end
        end
      end
      updateShownItems()
    end
  )
  Basalt.setVariable("onNewClick",
    function()
      local items = recipeReg.list();
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
    end
  )
  mainFrame = Basalt.createFrame():addLayout("mainframe.xml");
  craftFrame = Basalt.createFrame():addLayout("craftframe.xml");
  listFrame = Basalt.createFrame():addLayout("listframe.xml");
  craftListFrame = craftFrame:getDeepObject("craftListFrame");
  itemListFrame = listFrame:getDeepObject("itemListFrame");
  for index, recipe in ipairs(CraftingAPI.list()) do
    local name = ItemUtils.format(recipe.product);
    if (#name > biggest) then biggest = #name; end
  end
  width = biggest + 4;
  for index, recipe in ipairs(CraftingAPI.list()) do
    local button = craftListFrame:addButton()
    local column, row = index % columns, math.ceil(index / columns);
    if (column == 0) then column = columns; end
    local x, y = (column - 1) * width + (column - 1) * wspacing + 1, (row - 1) * height + (row - 1) * hspacing + 1;
    button:setBackground(colors.red);
    button:setSize(width, height);
    button:setPosition(x, y);
    button:setForeground(colors.white);
    button:setText(ItemUtils.format(recipe.product));
    table.insert(craftButtons, button);
    table.insert(shownButtons, button);
    craftingRecipes[ItemUtils.format(recipe.product)] = recipe.product;
  end
  local index = 1;
  for name, total in pairs(totalLookupItem) do
    local itemFrame = itemListFrame:addFrame()
    local column, row = index % columns, math.ceil(index / columns);
    if (column == 0) then column = columns; end
    local x, y = (column - 1) * width + (column - 1) * wspacing + 1, (row - 1) * height + (row - 1) * hspacing + 1;
    itemFrame:setBackground(colors.red);
    itemFrame:setSize(width, height);
    itemFrame:setPosition(x, y);
    itemFrame:setForeground(colors.white);
    itemFrame:addLabel("item")
              :setText(ItemUtils.format(name))
              :setForeground(colors.white)
              :setPosition("parent.w / 2 - self.w / 2", 2);
    itemFrame:addLabel("count")
              :setText("x"..total)
              :setForeground(colors.white)
              :setPosition("parent.w - self.w", "parent.h")
    table.insert(itemFrames, itemFrame);
    table.insert(shownItems, itemFrame);
    index = index + 1;
  end
  parallel.waitForAll(Basalt.autoUpdate, tasks, renderMonitor)
end

main();


