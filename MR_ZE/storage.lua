--[[
  Synopsis of the program:
    1) input into VAULT or overflow barrel depending on the filter
    2) move items into interface BARRELSSS depending on filter
    3) replenish missing stacks in interface depending on filter
    4) redstone dependant checking for missing items
    5) monitoir
    6) reading data
--]]

--[[
  Flow:
  Main Thread:
    Load Filter List
      LOOP:
        Push Items into Vault from Input Inventory
          If Item is in filter list push to VAULT
          else push to overflow barrel.
        If Enabled then
          Push Items from vault into interface using filter slot and item type
            If Interface Slot is Empty or less than 64
  Render Thread:
    Print Percent of Item in Vault
    Print Uptime
    Print Is Online
--]]

local input = peripheral.find("minecraft:trapped_chest");
local overflow = peripheral.find("minecraft:dropper");
local vault = peripheral.find("create:item_vault");
local barrelsList = {peripheral.find("minecraft:chest")};
local barrelsLookup = {};

local vaultAddr = peripheral.getName(vault);
local overflowAddr = peripheral.getName(overflow);

local filterItems = {};
local filtersList = {};

-- Check if peripheral exists 

local function isFilterItem(type)
  return filterItems[type] ~= nil
end

local function loadFilterList()
  local fileNames = fs.list("/chest_data");
  for _, fileName in ipairs(fileNames) do
    local ui = fileName:find("_");
    local addr = fileName:sub(1, ui-1) .. ":" .. fileName:sub(ui+1);
    if (peripheral.wrap(addr) ~= nil) then
      filtersList[addr] = {};
      local filterFile = fs.open("/chest_data/" .. fileName, "r");
      while true do
        local line = filterFile.readLine();
        if (line == nil) then break end
        local slot = tonumber(line);
        local type = filterFile.readLine();
        filterItems[type] = true;
        filtersList[addr][slot] = type;
      end
      filterFile.close();
    end
  end
end

local function store()
  for slot, item in pairs(input.list()) do
    if (isFilterItem(item.name)) then
      input.pushItems(vaultAddr, slot, 64);
    else
      input.pushItems(overflowAddr, slot, 64);
    end
  end
end

local function pushItem(type, amount, addr, pushSlot)
  local pushed = 0;
  for slot, item in pairs(vault.list()) do
    if (item.name == type) then
      pushed = pushed + vault.pushItems(addr, slot, amount - pushed, pushSlot);
      if (pushed == amount) then return pushed; end
    end
  end
end

local function restock()
  for addr, filterList in pairs(filtersList) do
    local interface = barrelsLookup[addr];
    local interfaceItems = interface.list();
    for slot, type in pairs(filterList) do
      local item = interfaceItems[slot];
      if (item == nil) then pushItem(type, 64, addr, slot); end
      if (item ~= nil and item.count < 64) then pushItem(type, 64 - item.count, addr, slot) end
    end
  end
end

local function main()
  while true do
    store();
    if (redstone.getInput("bottom")) then restock(); end
  end
end

for _, barrel in ipairs(barrelsList) do
  barrelsLookup[peripheral.getName(barrel)] = barrel;
end
loadFilterList();
main();