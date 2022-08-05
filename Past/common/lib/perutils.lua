local p = {};
local sides = { top=true, left=true, right=true, bottom=true, back=true, front=true };
p.sides = sides;

p.doSort = true;
p.removeCopies = true;

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

local function getNames()
  local names = peripheral.getNames()
  if (p.doSort) then tableutils.sort(names, function(a, b) return a < b end); end
  return names;
end

function p.toPeripheral(addrsList)
  local pList = {};
  for _, addr in ipairs(addrsList) do
    pList[#pList+1] = peripheral.wrap(addr);
  end
  return pList;
end

function p.toAddress(pList)

  local addrList = {};
  for _, periph in ipairs(pList) do
    addrList[#addrList+1] = peripheral.getName(periph);
  end
  return addrList;
end

function p.getFilter(whitelist, blacklist, asPeriph)
  asPeriph = default(true, asPeriph);

  local filtered = {};
  if (whitelist ~= nil) then
    for i, name in ipairs(getNames()) do
      local type = peripheral.getType(name);
      if (whitelist[type] ~= nil) then 
        if (asPeriph) then filtered[#filtered+1] = peripheral.wrap(name);
        else filtered[#filtered+1] = name end
      end
    end
  elseif (blacklist ~= nil) then
    for i, name in ipairs(getNames()) do
      local type = peripheral.getType(name);
      if (blacklist[type] == nil) then 
        if (asPeriph) then filtered[#filtered+1] = peripheral.wrap(name);
        else filtered[#filtered+1] = name end
      end
    end
  end 
  return filtered;
end

function p.getAll(asPeriph)
  asPeriph = default(true, asPeriph);

  local t = {};
  for _, name in ipairs(getNames()) do
    t[#t+1] = getPeripheral(asPeriph, name);
  end
  return t;
end

function p.get(type, asPeriph)
  return p.getFilter({[type]=true}, nil, asPeriph);
end

function p.getByKey(key, asPeriph)
  asPeriph = default(true, asPeriph);

  local t = {};
  for _, periph in ipairs(p.getAll()) do
    if (periph[key] ~= nil) then t[#t+1] = getAddress(not asPeriph, periph) end
  end
  return t;
end

function p.getCustom(fn, asPeriph)
  local t = {};
  for _, ap in ipairs(p.getAll(asPeriph)) do
    local pp = toPeripheral(ap);
    if (fn(pp)) then tableutils.insert(t, ap); end
  end
  return t;
end

function p.getSimilar(filter, asPeriph)
  filter = filter:lower();
  
  local similar = {};
  for index, name in ipairs(getNames()) do
    if (name:lower():find(filter)) then
      similar[#similar+1] = getPeripheral(asPeriph, name);
    end 
  end
  return similar;
end

function p.blacklist(t, bl)
  local ot = {};
  for _, ap in ipairs(t) do
    local pp = toPeripheral(ap);
    local type = peripheral.getType(pp);
    if (not bl[type]) then ot[#ot+1] = pp end
  end
  return ot;
end

function p.blacklistSides(t)
  local ot = {};
  for _, ap in ipairs(t) do
    local pp = toPeripheral(ap);
    local addr = toAddress(ap);
    if (not p.sides[addr]) then ot[#ot+1] = ap end
  end
  return ot;
end

function p.whitelist(t, wl)
  local ot = {};
  for _, ap in ipairs(t) do
    local pp = toPeripheral(ap);
    local type = peripheral.getType(pp);
    if (wl[type]) then ot[#ot+1] = pp end
  end
  return ot;
end

function p.whitelistSides(t)
  local ot = {};
  for _, ap in ipairs(t) do
    local addr = toAddress(ap);
    if (p.sides[addr]) then ot[#ot+1] = ap end
  end
  return ot;
end



return p;