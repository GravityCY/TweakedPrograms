--[[

-- Peripheral Utilities -- 
perutils is a collection of helpful functions related to peripherals
For example you can get all peripherals based off of a key within those peripherals with p.getByKey(type, asPeriph)

]]

local p = {};
local sides = { top=true, left=true, right=true, bottom=true, back=true, front=true };
p.sides = sides;

local function default(defaultInput, value)
  if (value == nil) then return defaultInput;
  else return value; end
end

local function getPeripheral(doGet, addr)
  if (doGet) then return peripheral.wrap(addr); end
  return addr;
end

local function getAddress(doGet, periph)
  if (doGet) then return peripheral.getName(periph); end
  return periph;
end

local function toPeripheral(obj)
  local t = type(obj);
  if (t == "string") then return peripheral.wrap(obj);
  elseif(t == "table") then return obj; end
end

local function toAddress(obj)
  local t = type(obj);
  if (t == "table") then return peripheral.getName(obj);
  elseif(t == "string") then return obj; end
end

--- Given a table of addresses `addrsList` returns a table of peripherals from those addresses
---@param addrsList table
---@return table
function p.toPeripheral(addrsList)
  local pList = {};
  for _, addr in ipairs(addrsList) do
    pList[#pList+1] = toPeripheral(addr);
  end
  return pList;
end

--- Given a table of peripherals `pList` returns a table of addresses from those peripherals
---@param pList table
---@return table
function p.toAddress(pList)

  local addrList = {};
  for _, periph in ipairs(pList) do
    addrList[#addrList+1] = toAddress(periph);
  end
  return addrList;
end

--- Returns a table of all peripherals, as a peripheral or an address according to the `asPeriph` boolean
--- @param asPeriph boolean
--- @return table
function p.getAll(asPeriph)
  asPeriph = default(true, asPeriph);

  local t = {};
  for _, name in ipairs(peripheral.getNames()) do
    t[#t+1] = getPeripheral(asPeriph, name);
  end
  return t;
end

--- Given a string `type` returns a table with peripherals of the type matching the `type` string
--- @param type string
--- @param asPeriph boolean
--- @return table
function p.get(type, asPeriph)
  local all = p.getAll(asPeriph);
  return p.whitelist(all, {[type] = true})
end

--- Given a string returns a table with peripherals that contain a key matching that string
--- @param key string
--- @param asPeriph boolean
--- @return table
function p.getByKey(key, asPeriph)
  asPeriph = default(true, asPeriph);

  local t = {};
  for _, periph in ipairs(p.getAll(asPeriph)) do
    if (periph[key] ~= nil) then t[#t+1] = getAddress(not asPeriph, periph) end
  end
  return t;
end

--- Given a function that receives a peripheral as an argument and returns true, that peripheral will be added to a table that will be returned.
--- @param fn function
--- @param asPeriph boolean
--- @return table
function p.getCustom(fn, asPeriph)
  local t = {};
  for _, ap in ipairs(p.getAll(asPeriph)) do
    local pp = toPeripheral(ap);
    if (fn(pp)) then t[#t+1] = ap; end
  end
  return t;
end

--- Given a filter string will return any peripheral that contains the filter as a substring
--- @param filter table
--- @param asPeriph boolean
--- @return table
function p.getSimilar(filter, asPeriph)
  filter = filter:lower();
  
  local similar = {};
  for index, name in ipairs(peripheral.getNames()) do
    if (name:lower():find(filter)) then
      similar[#similar+1] = getPeripheral(asPeriph, name);
    end 
  end
  return similar;
end


-- Given a list of peripherals and a blacklist of peripheral types will return a filtered list of the first list without the second list of the blacklisted peripheral types.
-- 
-- Blacklist should be a lookup table
-- 
-- Example:
-- 
--     local blacklist = {["minecraft:chest"]=true, ["minecraft:barrel"]=true};
---@param t table
---@param bl table
---@return table
function p.blacklist(t, bl)
  local ot = {};
  for _, ap in ipairs(t) do
    local pp = toPeripheral(ap);
    local type = peripheral.getType(pp);
    if (not bl[type]) then ot[#ot+1] = pp end
  end
  return ot;
end


--- Given a list of peripherals will return a filtered list of all the peripherals except any side peripherals.
--- @param t table
--- @return table
function p.blacklistSides(t)
  local ot = {};
  for _, ap in ipairs(t) do
    local pp = toPeripheral(ap);
    local addr = toAddress(ap);
    if (not p.sides[addr]) then ot[#ot+1] = ap end
  end
  return ot;
end


--- Given a list of peripherals and a whitelist of peripheral types will return a filtered list of the first list without the second list of the whitelisted peripheral types.
--- 
--- Whitelist should be a lookup table
--- 
--- Example:
--- 
---     local whitelist = {["minecraft:chest"]=true, ["minecraft:barrel"]=true};
---@param t table
---@param wl table
---@return table
function p.whitelist(t, wl)
  local ot = {};
  for _, ap in ipairs(t) do
    local pp = toPeripheral(ap);
    local type = peripheral.getType(pp);
    if (wl[type]) then ot[#ot+1] = pp end
  end
  return ot;
end

--- Given a list of peripherals will return a filtered list of all the side peripherals.
--- @return table
function p.whitelistSides(t)
  local ot = {};
  for _, ap in ipairs(t) do
    local addr = toAddress(ap);
    if (p.sides[addr]) then ot[#ot+1] = ap end
  end
  return ot;
end

return p;