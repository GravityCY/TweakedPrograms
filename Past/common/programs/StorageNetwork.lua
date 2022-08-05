local iu = require("InvUtils");
local pu = require("PeripheralUtils");
local tu = require("TermUtils");
local tabu = require("TableUtils");

local strf = string.format;

pu.doSort = false;

local modem = peripheral.find("modem");
rednet.open(peripheral.getName(modem));

local speaker = peripheral.find("speaker");

local craftTurtle = pu.blacklistSides({peripheral.find("turtle")})[1];
local craftTurtleID = craftTurtle.getID();
local craftTurtleAddr = peripheral.getName(craftTurtle);

function craftTurtle.list()
  rednet.send(craftTurtleID, nil, "list");
  write("Waiting for listing");
  local _, list = rednet.receive("list");
  write("Got Listing.");
  return list;
end

local craftToGlobal = { [1]=1, [2]=2, [3]=3, 
                        [4]=5, [5]=6, [6]=7, 
                        [7]=9, [8]=10, [9]=11 };

local dataPath = "/storage_network/";
local recipePath = dataPath .. "recipes/"
local invPath = dataPath .. "inv.txt";

local inventories = {};
local inventoryAddrs = {};
local inventorySizes = {};

local importers = {};

local importerList = {};
local importerAddrs = {};

local exporters = {};

local exporterList = {};
local exporterAddrs = {};

local buffer = nil;
local bufferAddr = nil;

local tmx, tmy = term.getSize();

local netSize = 0;

local isDebug = true;

local function getInput()
  local args = {};
  local input = read();

  local i = 1;
  while true do
    local str = "";
    local quote = nil;
    while true do
      local char = input:sub(i, i);
      if (char == "") then break end
      if (char == "\"" or char == "\'") then
        if (not quote) then 
          quote = char;
          i = i + 1;
          char = input:sub(i, i);
        elseif (char == quote) then break end
      end
      if (not quote) then
        if (char == " ") then 
          if (str ~= "") then break end
        else str = str .. char; end
      else str = str .. char; end
      i = i + 1;
    end
    i = i + 1;
    if (str == "") then break end
    tableutils.insert(args, str);
  end
  return args;
end

local function doRepeat(fn, times, ...)
  for i = 1, times do fn(...) end
end

local function requestInput(request)
  write(request);
  return read();
end

local function getInventory(slot)
  local total = 0;
  for i = 1, #inventorySizes do
    local size = inventorySizes[i];
    total = total + size;
    if (slot <= total) then 
      if (i == 1) then return slot, i
      else return slot - (total - size), i; end
    end
  end
end

local function getItem(slot, detail)
  local localSlot, inventoryIndex = getInventory(slot);
  local inventory = inventories[inventoryIndex];
  if (not inventory) then return end
  if (detail) then return inventory.getItemDetail(localSlot);
  else return inventory.list()[localSlot]; end
end

local function pushSlot(toInv, fromSlot, amount, toSlot)
  local localSlot, inventoryIndex = getInventory(fromSlot);
  local inventory = inventories[inventoryIndex];
  local toInvAddr = peripheral.getName(toInv);
  inventory.pushItems(toInvAddr, localSlot, amount, toSlot);
end

local function pullSlot(fromInv, fromSlot, amount, toSlot)
  local fromInvAddr = peripheral.getName(fromInv);
  if (toSlot) then
    local localSlot, inventoryIndex = getInventory(toSlot);
    local inventory = inventories[inventoryIndex];
    inventory.pullItems(fromInvAddr, fromSlot, amount, localSlot);
  else
    local pulled = 0;
    for i = 1, #inventories do
      local inventory = inventories[i];
      local pull = inventory.pullItems(fromInvAddr, fromSlot, amount - pulled);
      pulled = pulled + pull;
      if (pulled == amount) then return pulled end
    end
  end
end

local function push(toInv, id, amount, toSlot)
  local addr = peripheral.getName(toInv);
  local pushed = 0;
  for i = 1, #inventories do 
    local inventory = inventories[i];
    for slot, item in pairs(inventory.list()) do
      if (item.name == id) then 
        local push = inventory.pushItems(addr, slot, amount - pushed, toSlot);
        pushed = pushed + push;
        if (pushed == amount) then return pushed end
      end
    end
  end
  return pushed;
end

local function pull(fromInv, id, amount)
  amount = amount or 1;
  local addr = peripheral.getName(fromInv);
  local pulled = 0;
  for slot, item in pairs(fromInv.list()) do
    local itemPulled = 0;
    if (item.name == id) then
      for i = #inventories, 1, -1 do
        local inventory = inventories[i];
        local pull = inventory.pullItems(addr, slot, amount - pulled);
        pulled = pulled + pull;
        itemPulled = itemPulled + pull;
        if (itemPulled == item.count) then break end
        if (pulled == amount) then return pulled end
      end
    end
  end
  return pulled;
end

local function pullAll(fromInv)
  local addr = peripheral.getName(fromInv);
  local pulled = 0;
  for slot, item in pairs(fromInv.list()) do
    local pulledItem = 0;
    for i = #inventories, 1, -1 do
      local inventory = inventories[i];
      local pull = inventory.pullItems(addr, slot, 64);
      pulled = pulled + pull;
      pulledItem = pulledItem + pull;
      if (pulledItem == item.count) then break end
    end
  end
  return pulled;
end

local function list()
  local items = {};
  local i = 1;
  for index, inventory in ipairs(inventories) do
    local iItems = inventory.list();
    for slot = 1, inventory.size() do
      items[i] = iItems[slot];
      if (items[i]) then items[i].slot = i; end
      i = i + 1;
    end
  end
  return items;
end

local function size()
  local total = 0;
  for _, s in ipairs(inventorySizes) do total = total + s; end
  return total;
end

local function swap(a, b)
  local aLocalSlot, aInventoryIndex = getInventory(a);
  local bLocalSlot, bInventoryIndex = getInventory(b);
  local aInventoryAddr, bInventoryAddr = inventoryAddrs[aInventoryIndex], inventoryAddrs[bInventoryIndex];
  local aInventory, bInventory = inventories[aInventoryIndex], inventories[bInventoryIndex];
  local aItems, bItems = aInventory.list(), bInventory.list();

  if (aItems[aLocalSlot] and bItems[bLocalSlot]) then
    buffer.pullItems(aInventoryAddr, aLocalSlot, 64, 1);
    bInventory.pushItems(aInventoryAddr, bLocalSlot, 64, aLocalSlot);
    buffer.pushItems(bInventoryAddr, 1, 64, bLocalSlot);
  else
    if (aItems[aLocalSlot]) then aInventory.pushItems(bInventoryAddr, aLocalSlot, 64, bLocalSlot); end
    if (bItems[bLocalSlot]) then bInventory.pushItems(aInventoryAddr, bLocalSlot, 64, aLocalSlot); end
  end
end

local function sort(onIncrement)
  local items = list();
  local cap = size();
  for i = 1, cap do
    onIncrement(i);
    local lowestName = nil;
    local lowestAmount = nil;
    local lowestSlot = nil;
    for x = i, cap do
      local item = items[x];
      if (item) then
        local name = item.name;
        if (not lowestName) then lowestName = name; lowestSlot = x; lowestAmount = item.count; end
        if (name == lowestName and item.count > lowestAmount) then
          lowestName = name;
          lowestSlot = x;
          lowestAmount = item.count;
        end
        if (name < lowestName) then
          lowestName = name; 
          lowestSlot = x;
        end
      end
    end
    if (lowestName and lowestSlot ~= i) then 
      swap(lowestSlot, i);
      local prev = items[i];
      items[i] = items[lowestSlot];
      items[lowestSlot] = prev;
    end
  end
end

local function move(a, b, amount)
  local aLocalSlot, aInventoryIndex = getInventory(a);
  local bLocalSlot, bInventoryIndex = getInventory(b);
  local aInventoryAddr, bInventoryAddr = inventoryAddrs[aInventoryIndex], inventoryAddrs[bInventoryIndex];
  local aInventory, bInventory = inventories[aInventoryIndex], inventories[bInventoryIndex];
  return aInventory.pushItems(bInventoryAddr, aLocalSlot, amount, bLocalSlot);
end

local function getSimilar(input, items)
  local filter = input or "";
  filter = filter:lower();
  local idMap = {};
  local idList = {};
  local glSlot = 1;
  for slot, item in pairs(items) do
    local name = iu.format(item.name);
    if (not idMap[item.name] and name:lower():find(filter)) then 
      idMap[item.name] = true 
      idList[#idList + 1] = item.name;
    end
    glSlot = glSlot + 1;
  end
  return idList;
end

local function printFilter(input)
  local filter = input or "";
  filter = filter:lower();
  local items = list();
  local counted = {};
  for slot, item in pairs(items) do
    local displayName = iu.format(item.name);
    if (displayName:lower():find(filter)) then counted[displayName] = (counted[displayName] or 0) + item.count end
  end
  for item, count in pairs(counted) do
    write(string.format("%s %s, %.2f stacks.", count, item, count / 64)); 
  end
end

local function idToPath(id)
  return recipePath .. id:gsub(":", "_");
end

local function pathToID(path)
  local i = path:find("_");
  return path:sub(1, i - 1) .. ":" .. path:sub(i + 1);
end

local function newRecipe(materials, product)
  return {materials=materials, product=product};
end

local function saveRecipe(recipe)
  local file = fs.open(idToPath(recipe.product), "w");
  for i = 1, 9 do
    local material = recipe.materials[i];
    if (material) then
      file.write(i .. " " .. material .. "\n");
    end
  end
  file.close();
end

local function loadRecipe(id)
  local filePath = idToPath(id);
  if (fs.exists(filePath)) then
    local file = fs.open(filePath, "r");
    local materials = {};
    while true do
      local line = file.readLine();
      if (not line) then break end
      local slot, material = line:match("(.+) (.+)");
      local matData = materials[material];
      if (not matData) then matData = { slots={}, count=0 }; end
      matData.slots[#matData.slots + 1] = tonumber(slot);
      matData.count = matData.count + 1;
      materials[material] = matData;
    end
    file.close();
    return newRecipe(materials, id);
  end
end

local function recipeCost(recipe)
  local matMap = {}
  for slot, material in pairs(recipe.materials) do
    matMap[material] = (matMap[material] or 0) + 1;
  end
  return matMap;
end

local function mapInventories()
  inventories = pu.toPeripheral(inventoryAddrs);
  importerList = pu.toPeripheral(importerAddrs);
  for i = 1, #inventories do inventorySizes[i] = inventories[i].size(); end
end

local function saveInventories()
  local file = fs.open(invPath, "w");
  file.write(bufferAddr .. "\n");
  for i, address in ipairs(inventoryAddrs) do file.write(address .. "\n"); end
  file.write("\n");
  for i, address in ipairs(importerAddrs) do file.write(address .. "\n"); end
  file.close();
end

local function loadInventories()
  write("Loading Inventories.");
  local file = fs.open(invPath, "r");
  if (not file) then return end
  bufferAddr = file.readLine();
  file.readLine();
  buffer = iu.wrap(peripheral.wrap(bufferAddr));
  local foundNil = buffer == nil;
  while true do
    local line = file.readLine();
    if (line == "" or line == nil) then break end
    local inventory = peripheral.wrap(line);
    if (inventory == nil) then foundNil = true;
    else 
      inventories[#inventories + 1] = inventory;
      inventorySizes[#inventorySizes + 1] = inventory.size();
      inventoryAddrs[#inventoryAddrs + 1] = line;
    end
  end
  
  while true do
    local line = file.readLine();
    if (line == nil) then break end
    local importer = peripheral.wrap(line);
    if (importer == nil) then foundNil = true;
    else
      importerList[#importerList + 1] = importer;
      importerAddrs[#importerAddrs + 1] = line;
    end
  end
  if (foundNil) then saveInventories(); end
end

local function toMap(inv)
  local map = {};  
  for i, v in ipairs(inv) do map[v] = true; end
  return map;
end

local function toList(map)
  local temp = {};
  for k in pairs(map) do temp[#temp+1] = k end
  return temp;
end

local function diff(map1, map2)
  for k in pairs(map2) do
    if (map1[k] == nil) then return k, true; end
  end
  for k in pairs(map1) do
    if (map2[k] == nil) then return k, false; end
  end
end

local function detect(list)
  local pmap = toMap(pu.getByKey("list", false));
  while true do
    local event = os.pullEvent();
    if (event == "char") then break end
    local addr, wasAdded = diff(pmap, toMap(pu.getByKey("list", false)));
    if (addr ~= nil) then 
      if (wasAdded) then 
        pmap[addr] = true;
        tableutils.insert(list, addr);
      else 
        pmap[addr] = nil;
        list = tabu.remove(list, function(value) return value == addr end)
      end
      if (speaker) then speaker.playNote("harp", 1, 1); end
    end
  end
end

local function detectOne()
  local pmap = toMap(pu.getByKey("list", false));
  while true do
    local event, key = os.pullEvent();
    if (event == "key_up" and key == keys.backspace) then break end
    local val, wasAdded = diff(pmap, toMap(pu.getByKey("list", false)));
    if (val ~= nil) then 
      return val, wasAdded 
    end
  end
end 

local ops = {};
local opsList = {};

local function printHelp(command, doPrintExample, doPrintDescription)
  if (doPrintExample == nil) then doPrintExample = true; end
  if (doPrintDescription == nil) then doPrintDescription = false; end
  local str = command.name;
  if (doPrintDescription) then str = str .. " - " .. command.description; end
  write(str);
  if (doPrintExample and command.example) then write(command.example); end
end

local function newOP(name, desc, fn, example)
  local op = {};
  op.name = name;
  op.description = desc;
  op.fn = fn;
  op.example = example;
  ops[name] = op;
  opsList[#opsList+1] = op;
end

if (isDebug) then
  newOP("debug", "Debug", function(args)
    term.clear();
    term.setCursorPos(1, 1);
    if (args[2] == "inv") then
      for i, v in ipairs(inventoryAddrs) do write(v); end
    elseif (args[2] == "import") then
      for i, v in ipairs(importerAddrs) do write(v); end 
    elseif (args[2] == "buffer") then
      write(bufferAddr);
    end
  end)
end

newOP("craft", "Crafts Items using the Crafty Turtle Connected to the Network", function(args)
  local op = args[2];
  if (not op) then return write("Enter an ID, or register a new Recipe with 'new', or list all existing recipes with 'list'"); end
  if (op == "new") then
    term.clear();
    term.setCursorPos(1, 1);
    requestInput("Registering new Recipe, insert the Recipe Materials AND Product in the Crafter in these slots: \nMMM#\nMMM#\nMMM#\n###P\n M = Material P = Product # = Slot\nPress Enter When Inserted Materials.");
    rednet.send(craftTurtleID, nil, "new");
    local id, recipe = rednet.receive("recipe");
    saveRecipe(recipe);
    write("Success!");
  elseif (op == "list") then
    term.clear();
    term.setCursorPos(1, 1);
    if (fs.exists(recipePath)) then
      for _, path in pairs(fs.list(recipePath)) do write(pathToID(path)); end
    end
  else
    local count = args[3];
    count = count or 1;
    term.clear();
    term.setCursorPos(1, 1);
    local recipe = loadRecipe(op);
    if (recipe) then
      write("Crafting " .. count .. " " .. recipe.product .. "...");
      pullAll(buffer);
      for matName, matData in pairs(recipe.materials) do
          push(buffer, matName, matData.count * count);
          for index, slot in ipairs(matData.slots) do
            local gslot = craftToGlobal[slot];
            buffer.push(craftTurtle, matName, count, gslot);
          end
      end
      rednet.send(craftTurtleID, nil, "craft");
      sleep(0.5);
      pullAll(craftTurtle);
      write("Succesfully crafted " .. count .. " " .. recipe.product .. ".");
    else return write("Enter an ID, or register a new Recipe with 'new', or list all existing recipes with 'list'"); end
  end
end, "craft 'minecraft:cobblestone' to Craft a Registered Recipe by that id.\ncraft new - Registers a new Recipe.\ncraft list - Lists all Registered Recipes.")

newOP("buffer", "Sets detection mode to Buffer, any inventory you add, will be marked as a buffer", function()
  local addr, wasAdded = detectOne();
  speaker.playNote("harp", 1, 1);
  if (addr == nil) then return end
  if (wasAdded) then
    -- requestInput("Enter an ID for the importer: ");
    bufferAddr = addr;
    buffer = iu.wrap(peripheral.wrap(addr));
    write("Succesfully added " .. addr);
  else
    bufferAddr = nil;
    buffer = nil;
    write("Succesfully removed " .. addr);
  end
  saveInventories();
end)

newOP("storage", "Sets detection mode to Storage, any inventory you add, will be marked as storage.", function(args)
  while true do
    local addr, wasAdded = detectOne();
    if (addr ~= nil) then 
      if (wasAdded) then 
        local inventory = peripheral.wrap(addr);
        tableutils.insert(inventoryAddrs, addr);
        tableutils.insert(inventories, inventory);
        tableutils.insert(inventorySizes, inventory.size());
        write("Succesfully added " .. addr);
      else 
        inventoryAddrs = tabu.remove(inventoryAddrs, function(value) return value == addr end);
        mapInventories();
        write("Succesfully removed " .. addr);
      end
      if (speaker) then speaker.playNote("harp", 1, 1); end
    else break end
  end
  saveInventories();
end);

newOP("import", "Imports Items into the network from a specific address", function()
  local addr, wasAdded = detectOne();
  speaker.playNote("harp", 1, 1);
  if (addr == nil) then return end
  if (wasAdded) then
    tableutils.insert(importerAddrs, addr);
    tableutils.insert(importerList, peripheral.wrap(addr));
    write("Succesfully added " .. addr);
  else
    importerAddrs = tabu.remove(importerAddrs, function(value) return value == addr end);
    mapInventories();
    write("Succesfully removed " .. addr);
  end
  saveInventories();
end)

newOP("export", "Exports an Item into an Inventory", function()
  local addr, wasAdded = detectOne();
  speaker.playNote("harp", 1, 1);
  if (addr == nil) then return end
  if (wasAdded) then
    local periph = iu.wrap(peripheral.wrap(addr));
    local item = {};
    item.name = requestInput("Enter an Item Name to export: ");
    item.count = tonumber(requestInput("Enter how much to export: "));
    periph.exportItem = item;
    tableutils.insert(exporterAddrs, addr);
    tableutils.insert(exporterList, periph);
  else
    exporterAddrs = tabu.remove(exporterAddrs, function(value) return value == addr end);
  end
end)

newOP("list", "Lists Items by a Filter", function(args) 
  printFilter(args[2]);
end);

newOP("compact", "Compacts Items (Inefficiently)", function(args)
  for i, inventory in pairs(inventories) do
    local addr = inventoryAddrs[i];
    for slot, item in pairs(inventory.list()) do
      inventory.pushItems(addr, slot, 64);
      local str = strf("Inventory: %s / %s", i, #inventories);
      local str1 = strf("Slot: %s / %s", slot, inventory.size());
      term.clear();
      term.setCursorPos(tmx/2-#str/2, tmy/2);
      write(str);
      term.setCursorPos(tmx/2-#str1/2, tmy/2+1);
      write(str1);
    end
  end
  term.clear();
  term.setCursorPos(1, 1);
  if (speaker) then doRepeat(function() speaker.playNote("harp", 1, 1); sleep(1); end, 3); end
end)

newOP("sort", "Sorts all Items alphabetically (Using Their IDS)", function() 
  pullAll(buffer);
  write("Sorting...");
  sort(function (slot)
    local str = strf("Slot: %s / %s", slot, netSize);
    term.clear();
    term.setCursorPos(tmx/2-#str/2, tmy/2);
    write(str);
  end);
  term.clear();
  term.setCursorPos(1, 1);
  write("Sorted."); 
  if (speaker) then doRepeat(function() speaker.playNote("harp", 1, 1); sleep(1); end, 3); end
end);

newOP("full", "Displays how full the Storage Network is", function()
    local tsize = size();
    local occupied = 0;
    for index, inv in ipairs(inventories) do
      for slot, item in pairs(inv.list()) do
        occupied = occupied + 1;
      end
    end
    term.clear();
    local str = strf("%d%% full.", occupied / tsize * 100);
    term.setCursorPos(tmx / 2 - #str / 2, tmy / 2);
    write(str);
    os.pullEvent("char");
    term.clear();
    term.setCursorPos(1, 1);
end)

newOP("get", "Gets an Item using it's ID and puts it into the buffer chest", function(args)
  local filter = args[2];
  local amount = args[3];
  if (not filter) then filter = requestInput("Enter Item Name: "); end
  if (not amount) then amount = requestInput("Enter Amount: "); end
  local ids = getSimilar(filter, list());
  local names = {};
  for i = 1, #ids do names[i] = iu.format(ids[i]); end
  if (#ids == 0) then write("No Item Found");
  else
    local selection = tu.select({selections=names, prefix="-> "});
    if (selection == nil) then write("Canceled..."); return end
    local itemName = ids[selection];
    if (amount == "all") then
      amount = push(buffer, itemName, buffer.size()*64);
    else
      amount = tonumber(amount);
      push(buffer, itemName, amount);
    end
    write(strf("Pushed %s %s.", amount, itemName))
  end  
end);

newOP("put", "Puts an Item from the buffer chest in the system", function(args)
  local filter = args[2];
  local amount = args[3];
  if (not filter) then filter = requestInput("Enter Item Name: "); end
  if (filter == "all") then return pullAll(buffer); end
  if (not amount) then amount = requestInput("Enter Amount: "); end
  local similar = getSimilar(filter, buffer.list());
  if (#similar == 0) then
    write("No Item Found")
  else
    local selection = tu.select({selections=similar, prefix="-> "});
    if (selection) then
      pull(buffer, similar[selection], amount);
      write("Success.");
    else
      write("Canceled...");
    end
  end
end);

newOP("help", "Lists all Commands", function(args) 
  term.clear();
  term.setCursorPos(1, 1);
  write("Commands: ");
  if (args and args[2]) then
    local op = ops[args[2]];
    if (op) then printHelp(op, true, true);
    else write("No such Command."); end
  else
    for _, op in pairs(opsList) do
      printHelp(op, false, false);
    end
  end
end)

newOP("exit", "Exits the program", function()
  write("Goodbye :)");
  sleep(1);
  term.clear();
  term.setCursorPos(1, 1);
  error()
end)

local function CommandThread()
  term.clear();
  term.setCursorPos(1, 1);
  ops.help.fn();
  while true do
    write("Enter Command: ");
    local args = getInput();
    local op = args[1];
    local command = ops[op];
    if (command) then command.fn(args);
    else ops.help.fn(); end
  end
end

local function IOThread()
  local sleepTime = 2;
  local count = 0;
  while true do
    for index, inventory in ipairs(importerList) do pullAll(inventory); end
    if (count * sleepTime >= sleepTime * 5) then
      count = 0;
      for index, exporter in ipairs(exporterList) do 
        local item = exporter.exportItem;
        local count = exporter.count(item.name);
        if (count < item.count) then push(exporter, item.name, item.count - count);  end
      end
    end
    count = count + 1;
    sleep(sleepTime);
  end
end

loadInventories();
netSize = size();
parallel.waitForAll(CommandThread, IOThread)
