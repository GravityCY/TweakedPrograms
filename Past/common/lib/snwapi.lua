------- APIS --------
local sn = require("StorageNetworkAPI");
local pu = require("PeripheralUtils");
local tu = require("TermUtils");
local iu = require("InvUtils");
local tabu = require("TableUtils");
local itemu = require("ItemUtils");

local strf = string.format;
------- Peripherals --------
local speaker = peripheral.find("speaker");
local importerList = {};
local importerAddrs = {};
local exporterList = {};
local exporterAddrs = {};
local crafter = pu.blacklistSides({peripheral.find("turtle")})[1];
local crafterID = crafter.getID();
local crafterAddr = peripheral.getName(crafter);
local localModemAddr = pu.whitelistSides(pu.getCustom(function(p) return p.isWireless ~= nil and not p.isWireless() end, false))[1];
-- local wifiModemAddr = pu.getCustom(function(p) return p.isWireless ~= nil and p.isWireless() end, false)[1];
-- local wifiModem = peripheral.wrap(wifiModemAddr);
-----------------------------------------------
-- wifiModem.open(6969);

local dataPath = "/data/storage_network/";
local recipePath = dataPath .. "recipes/"

local buffer = nil;

local tmx, tmy = term.getSize();
local isDebug = true;

local history = {};

rednet.open(localModemAddr);
pu.doSort = false;

function crafter.list()
  rednet.send(crafterID, nil, "list");
  write("Waiting for listing");
  local _, list = rednet.receive("list");
  write("Got Listing.");
  return list;
end

local Recipe = {};

function Recipe.new(productName, out, materials)
  local t = {};
  t.productName = productName;
  t.out = out or 1;
  t.materials = materials or {};
  -- function t.print()
  --   print("Makes: " .. t.out .. " " .. productName);
  --   print("\nMaterials: ");
  --   for _, mdata in pairs(t.materials) do mdata.print(); end
  -- end
  return t;
end

local Material = {};

function Material.new(materialName, slots, count)
  local t = {};
  t.materialName = materialName;
  t.slots = slots or {};
  t.count = count or 0;
  -- function t.print()
  --   print("Material: " .. materialName);
  --   print("At: " );
  --   for _, slot in ipairs(t.slots) do write(slot .. ", "); end
  --   print();
  -- end
  return t;
end

local craftToGlobal = { [1]=1, [2]=2, [3]=3, 
                        [4]=5, [5]=6, [6]=7, 
                        [7]=9, [8]=10, [9]=11 };

local function toTable(input)
  local args = {};

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

local function getSimilar(input, items)
  local filter = input or "";
  filter = filter:lower();
  local idMap = {};
  local idList = {};
  local glSlot = 1;
  for slot, item in pairs(items) do
    local name = itemu.format(item.name);
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
  local counted = {};
  for slot, item in pairs(sn.list()) do
    local displayName = itemu.format(item.name);
    if (displayName:lower():find(filter)) then counted[displayName] = (counted[displayName] or 0) + item.count end
  end
  for item, count in pairs(counted) do
    write(string.format("%s %s, %.2f stacks.", count, item, count / 64));
  end
end

local function idToPath(id)
  return id:gsub(":", "_");
end

local function pathToID(path)
  local i = path:find("_");
  return path:sub(1, i - 1) .. ":" .. path:sub(i + 1);
end

local function saveRecipe(recipe)
  local file = fs.open(recipePath..idToPath(recipe.product), "w");
  file.write(recipe.out .. "\n");
  for i = 1, 9 do
    local material = recipe.materials[i];
    if (material) then
      file.write(i .. " " .. material .. "\n");
    end
  end
  file.close();
end

local function loadRecipe(id)
  local filePath = recipePath..idToPath(id);
  if (not fs.exists(filePath)) then return end
  local file = fs.open(filePath, "r");
  local recipe = Recipe.new(id, nil, nil);
  recipe.out = tonumber(file.readLine());

  local materials = {};
  while true do
    local line = file.readLine();
    if (line == nil) then break end
    local slot, material = line:match("(.+) (.+)");
    local mdata = materials[material];
    if (mdata == nil) then mdata = Material.new(material, nil, nil); end
    mdata.slots[#mdata.slots + 1] = tonumber(slot);
    mdata.count = mdata.count + 1;
    materials[material] = mdata;
  end
  file.close();
  recipe.materials = materials;
  return recipe;
end

local function getRecipeCost(recipe, mult)
  mult = mult or 1;

  local matMap = {}
  for mat, mdata in pairs(recipe.materials) do
    matMap[mat] = (matMap[mat] or 0) + mdata.count * mult;
  end
  return matMap;
end

local function saveList(list, path)
  local f = fs.open(path, "w");
  for index, value in ipairs(list) do f.write(value .. "\n"); end
  f.close();
end

local function loadList(path)
  local f = fs.open(path, "r");
  if (f == nil) then return {} end
  local list = {};
  while true do
    local line = f.readLine();
    if (line == nil) then break end
    tableutils.insert(list, line);
  end
  f.close();
  return list;
end

local function save()
  sn.save(dataPath);
  saveList(importerAddrs, dataPath .. "importers");
  saveList(exporterAddrs, dataPath .. "exporters");
end

local function load()
  write("Loading Inventories.");
  sn.load(dataPath);
  fs.makeDir(recipePath);
  buffer = iu.wrap(sn.getBuffer());
  importerAddrs = loadList(dataPath .. "importers");
  exporterAddrs = loadList(dataPath .. "exporters");
  importerList = pu.toPeripheral(importerAddrs);
  exporterList = pu.toPeripheral(exporterAddrs);
end

local function detectOne()
  while true do
    local event, arg1 = os.pullEvent();
    if (event == "key_up" and arg1 == keys.backspace) then break
    elseif (event == "peripheral") then return arg1, true;
    elseif (event == "peripheral_detach") then return arg1, false; end
  end
end

local function isEnough(cost, needs)
  for mat in pairs(cost) do
    if (needs[mat] ~= 0) then return false; end
  end
  return true;
end

local function getNeedForRecipe(cost, where)
  local needs = {};
  for mat, amount in pairs(cost) do
    if (where[mat] == nil) then needs[mat] = amount;
    else needs[mat] = amount - where[mat].found end
  end
  return needs;
end


local function getPathAsMap(path)
  local folder = fs.list(path);
  local map = {};
  for _, path in ipairs(folder) do
    map[path] = true;
  end
  return map;
end

local function getInput()
  local input = nil;
  local function getLocalInput()
    term.setCursorBlink(true); 
    input = read(nil, history);
    if (input ~= "" and input ~= history[#history]) then
      if (#history == 10) then tableutils.remove(history, 1); end
      tableutils.insert(history, input);
    end
  end
  local function getGlobalInput()
    input = ({os.pullEvent("modem_message")})[5];
    term.setCursorBlink(false);
  end
  parallel.waitForAny(getLocalInput, getGlobalInput);
  return toTable(input);
end

local function sendRecipe(recipe, where, mult)
  write("Sending Recipe: " .. recipe.productName);
  for mat, mdata in pairs(recipe.materials) do
    for _, slot in ipairs(mdata.slots) do
      local sent = 0;
      for _, wslot in pairs(where[mat].slots) do
        sent = sent + sn.pushSlot(crafterAddr, wslot.slot, mult - sent, craftToGlobal[slot]);
        if (sent == mult) then break end
      end
    end
  end
end


local function craftRecipe(recipe, amount)
  if (recipe == nil) then return end
  local mult = math.ceil(amount / recipe.out);
  if (mult == 0) then mult = 1 end
  local cost = getRecipeCost(recipe, mult);
  local where = sn.getWhere(cost);
  local needs = getNeedForRecipe(cost, where);
  local haveEnough = isEnough(cost, needs);
  if (not haveEnough) then 
    local isAllSubrecipes = true;
    local recipeListings = getPathAsMap(recipePath);
    for mat, need in pairs(needs) do
      if (need ~= 0 and recipeListings[idToPath(mat)] == nil) then isAllSubrecipes = false; break end
    end
    if (isAllSubrecipes) then
      for mat, need in pairs(needs) do
        if (need ~= 0) then
          write("Crafting Subrecipe " .. mat .. " " .. need);
          local subrecipe = loadRecipe(mat);
          local success, subneeds = craftRecipe(subrecipe, need)
          if (not success) then return false, needs; end
          sn.pull(buffer, subrecipe.productName, math.ceil(need / subrecipe.out) * subrecipe.out);
        end
      end
      where = sn.getWhere(cost);
    else return false, needs; end
  end
  sendRecipe(recipe, where, mult);
  rednet.send(crafterID, nil, "craft");
  sleep(0.5);
  buffer.pullAll(crafter);
  return true;
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
      for _, v in ipairs(sn.getInventories()) do write(v); end
    elseif (args[2] == "import") then
      for _, v in ipairs(importerAddrs) do write(v); end
    elseif (args[2] == "buffer") then
      write(sn.getBuffer());
    end
  end)
end

newOP("craft", "Crafts Items using the Crafty Turtle Connected to the Network", function(args)
  local op = args[2];
  if (op == nil) then return write("Enter an ID, or register a new Recipe with 'new', or list all existing recipes with 'list'"); end
  if (op == "new") then
    term.clear();
    term.setCursorPos(1, 1);
    requestInput("Registering new Recipe, insert the Recipe Materials AND Product in the Crafter in these slots: \nMMM#\nMMM#\nMMM#\n###P\n M = Material P = Product # = Slot\nPress Enter When Inserted Materials.");
    rednet.send(crafterID, nil, "new");
    local _, recipe = rednet.receive("recipe");
    saveRecipe(recipe);
    write("Success!");
  elseif (op == "list") then
    term.clear();
    term.setCursorPos(1, 1);
    for _, path in pairs(fs.list(recipePath)) do write(({itemu.format(pathToID(path))})[1]); end
  else
    local id = op:lower();
    local count = args[3];
    count = tonumber(count) or 1;

    term.clear();
    term.setCursorPos(1, 1);

    local similar = {};
    for _, path in ipairs(fs.list(recipePath)) do
      if (path:find(id) ~= nil) then similar[#similar+1] = pathToID(path); end
    end
    if (#similar == 0) then return write("Couldn't find anything similar to " .. id .. "..."); end
    local index = tu.select({ selections=similar });
    if (index == nil) then return write("Canceled..."); end
    local selection = similar[index];
    local recipe = loadRecipe(selection);
    if (recipe == nil) then return write("No such Recipe..."); end
    local success, needList = craftRecipe(recipe, count);
    write("Crafting " .. count .. " " .. id .. "...");
    if (success) then write("Succesfully crafted " .. count .. " " .. selection .. ".");
    else 
      write("Not enough Materials..."); 
      write("Missing: ")
      for mat, need in pairs(needList) do 
        if (need ~= 0) then write(need .. " " .. mat); end
      end
    end
  end
end, "craft 'minecraft:cobblestone' to Craft a Registered Recipe by that id.\ncraft new - Registers a new Recipe.\ncraft list - Lists all Registered Recipes.")

newOP("buffer", "Sets detection mode to Buffer, any inventory you add, will be marked as a buffer", function()
  local addr, wasAdded = detectOne();
  speaker.playNote("harp", 1, 1);
  if (addr == nil) then return end
  if (wasAdded) then
    -- requestInput("Enter an ID for the importer: ");
    sn.setBuffer(addr);
    write("Succesfully added " .. addr);
  else
    sn.setBuffer(nil);
    write("Succesfully removed " .. addr);
  end
  buffer = iu.wrap(addr);
  save();
end)

newOP("storage", "Sets detection mode to Storage, any inventory you add, will be marked as storage.", function(args)
  while true do
    local addr, wasAdded = detectOne();
    if (addr ~= nil) then
      if (wasAdded) then
        sn.add(addr);
        write("Succesfully added " .. addr);
      else
        sn.remove(addr);
        write("Succesfully removed " .. addr);
      end
      if (speaker) then speaker.playNote("harp", 1, 1); end
    else break end
  end
  save();
end);

newOP("import", "Imports Items into the network from a specific address", function()
  local addr, wasAdded = detectOne();
  speaker.playNote("harp", 1, 1);
  if (addr == nil) then return end
  if (wasAdded) then
    local periph = peripheral.wrap(addr);
    tableutils.insert(importerAddrs, addr);
    tableutils.insert(importerList, periph);
    write("Succesfully added " .. addr);
  else
    importerAddrs = tabu.remove(importerAddrs, function(value) return value == addr end);
    importerList = pu.toPeripheral(importerAddrs);
    write("Succesfully removed " .. addr);
  end
  save();
end)

newOP("export", "Exports an Item into an Inventory", function()
  local addr, wasAdded = detectOne();
  speaker.playNote("harp", 1, 1);
  if (addr == nil) then return end
  if (wasAdded) then
    local periph = peripheral.wrap(addr);
    local item = {};
    item.name = requestInput("Enter an Item Name to export: ");
    item.count = tonumber(requestInput("Enter how much to export: "));
    periph.exportItem = item;
    tableutils.insert(exporterAddrs, addr);
    tableutils.insert(exporterList, periph);
    write("Succesfully added " .. addr);
  else
    exporterAddrs = tabu.remove(exporterAddrs, function(value) return value == addr end);
    exporterList = pu.toPeripheral(exporterAddrs);
    write("Succesfully removed " .. addr);
  end
  save();
end)

newOP("list", "Lists Items by a Filter", function(args)
  printFilter(args[2]);
end);

newOP("compact", "Compacts Items (Inefficiently)", function(args)
  sn.compact(function(slot)
    local str = strf("Slot: %s / %s", slot, sn.capacity);
    term.clear();
    term.setCursorPos(tmx/2-#str/2, tmy/2);
    write(str);
  end);
  term.clear();
  term.setCursorPos(1, 1);
  if (speaker) then doRepeat(function() speaker.playNote("harp", 1, 1); sleep(0.2); end, 3); end
end)

newOP("sort", "Sorts all Items alphabetically (Using Their IDS)", function()
  write("Sorting...");
  sn.sort(function (slot)
    local str = strf("Slot: %s / %s", slot, sn.capacity);
    term.clear();
    term.setCursorPos(tmx/2-#str/2, tmy/2);
    write(str);
  end);
  term.clear();
  term.setCursorPos(1, 1);
  write("Sorted.");
  if (speaker) then doRepeat(function() speaker.playNote("harp", 1, 1); sleep(0.2); end, 3); end
  sn.toFile(dataPath);
end);

newOP("full", "Displays how full the Storage Network is", function()
    term.clear();
    local str = strf("%d%% full.", sn.occupied() / sn.size() * 100);
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
  local ids = getSimilar(filter, sn.list());
  local names = {};
  for i = 1, #ids do names[i] = itemu.format(ids[i]); end
  if (#ids == 0) then write("No Item Found");
  else
    local pushed = 0;
    local selection = tu.select({selections=names, prefix="-> "});
    if (selection == nil) then write("Canceled..."); return end
    local itemName = ids[selection];
    if (amount == "all") then
      pushed = sn.pushAll(sn.getBuffer(), itemName);
    else
      amount = tonumber(amount);
      pushed = sn.push(sn.getBuffer(), itemName, amount);
    end
    write(strf("Pushed %s %s.", pushed, itemName))
  end
end);

newOP("put", "Puts an Item from the buffer chest in the system", function(args)
  local filter = args[2];
  local amount = args[3];
  if (not filter) then filter = requestInput("Enter Item Name: "); end
  if (filter == "all") then
    local pulled = sn.pullAll(sn.getBuffer());
    write("Pulled " .. pulled .. ".");
    return
  else
    if (amount == nil) then amount = requestInput("Enter Amount: "); end
    local similar = getSimilar(filter, buffer.list());
    if (#similar == 0) then
      write("No Item Found")
    else
      local selection = similar[tu.select({selections=similar, prefix="-> "})];
      if (selection) then
        local pulled = 0;
        if (amount == "all") then
          pulled = sn.pullAll(sn.getBuffer(), selection);
        else
          amount = tonumber(amount);
          pulled = sn.pull(sn.getBuffer(), selection, amount);
        end
        write("Pulled " .. pulled .. " " .. selection .. ".");
      else write("Canceled..."); end
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
    for index, inventory in ipairs(importerList) do
      if (peripheral.getName(inventory) ~= nil) then sn.pullAll(inventory); end
    end
    if (count * sleepTime >= sleepTime * 5) then
      count = 0;
      for index, exporter in ipairs(exporterList) do
        local item = exporter.exportItem;
        local count = exporter.count(item.name);
        if (count < item.count) then sn.push(exporter, item.name, item.count - count);  end
      end
    end
    count = count + 1;
    sleep(sleepTime);
  end
end

load();
parallel.waitForAll(CommandThread, IOThread)