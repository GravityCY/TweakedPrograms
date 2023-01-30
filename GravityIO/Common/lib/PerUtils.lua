--[[

-- Peripheral Utilities -- 
perutils is a collection of helpful functions related to peripherals
For example you can get all peripherals based off of a key within those peripherals with p.getByKey(type, asPeriph)

]]

local p = {};

local function default(defaultInput, value)
  if (value == nil) then return defaultInput;
  else return value; end
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

-- per.addr         = minecraft:barrel_0          | modem_0
-- per.id, per.type = minecraft:barrel, inventory | modem, nil
-- per.namespace    = minecraft                   | computercraft
-- per.name         = barrel                      | modem
-- per.index        = 0                           | 0

function p.wrap(pp)
  if (pp == nil) then return end
  pp.addr = peripheral.getName(pp);
  pp.id, pp.type = peripheral.getType(pp.addr);
  pp.namespace = pp.addr:match("(.-):") or "computercraft";
  pp.name = pp.addr:match(":(.+)_") or pp.id;
  pp.index = tonumber(pp.addr:match(".+_(.+)$"));
  return pp;
end

--- Given a table of addresses `addrsList` returns a table of peripherals from those addresses
---@param addrsList table
---@return table
function p.toPeripheralList(addrsList)
  local pList = {};
  for _, addr in ipairs(addrsList) do
    pList[#pList+1] = toPeripheral(addr);
  end
  return pList;
end

--- Given a table of peripherals `pList` returns a table of addresses from those peripherals
---@param pList table
---@return table
function p.toAddressList(pList)
  local addrList = {};
  for _, periph in ipairs(pList) do
    addrList[#addrList+1] = toAddress(periph);
  end
  return addrList;
end

--- Returns a table of all peripherals, as a peripheral or an address according to the `asPeriph` boolean
--- @param asPeriph boolean | nil
--- @return table
function p.getAll(asPeriph)
  asPeriph = default(true, asPeriph);

  local t = {};
  for _, name in ipairs(peripheral.getNames()) do
    local out = name;
    if (asPeriph) then out = p.get(out) end
    t[#t+1] = out;
  end
  return t;
end

--- Given a string `addr` returns a wrapped peripheral
--- @param addr string
--- @return table | nil
function p.get(addr)
  local per = peripheral.wrap(addr);
  return p.wrap(per);
end

function p.getType(type, asPeriph)
  local t = {};

  for _, addr in ipairs(p.getAll(false)) do
    local name, tt = peripheral.getType(addr);
    if (tt == type) then
      local out = addr;
      if (asPeriph) then out = p.get(addr); end
      t[#t+1] = out;
    end
  end

  return t;
end

--- Given a string returns a table with peripherals that contain a key matching that string
--- @param key string
--- @param asPeriph boolean
--- @return table
function p.getKey(key, asPeriph)
  asPeriph = default(true, asPeriph);

  local t = {};
  for _, periph in ipairs(p.getAll()) do
    if (periph[key] ~= nil) then
      local out = periph;
      if (not asPeriph) then out = out.addr; end
      t[#t+1] = out;
    end
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

function p.find(addr, asPeriph)
  asPeriph = default(true, asPeriph);
  local t = {};
  for i, pp in ipairs(p.getAll()) do
    if (pp.id == addr) then
      local out = pp;
      if (not asPeriph) then out = pp.addr; end
      t[#t+1] = out;
    end
  end
  return t;
end

return p;