local t = {};
t.saveDir = "/data/itemutils/items/"

local cache = {};


local function getCache(name)
  return cache[name];
end

local function toCommon(detail)
  local i = {};
  i.maxCount = detail.maxCount;
  i.maxDamage = detail.maxDamage;
  i.format = t.format(detail.name);
  i.namespace = t.namespace(detail.name);
  i.type = t.type(detail.name);
  i.tags = detail.tags;
  return i;
end

local function save(detail)
  local common = toCommon(detail);
  local path = ("%s%s/%s"):format(t.saveDir, common.namespace, common.type);
  local f = fs.open(path, "w");
  f.writeLine(common.maxCount);
  f.writeLine(common.maxDamage);
  f.writeLine(common.namespace);
  f.writeLine(common.type);
  f.writeLine(common.format);
  for tag, _ in pairs(common.tags) do
    f.writeLine(tag);
  end
  f.close();
  cache[detail.name] = common;
end

local function load()
  if (not fs.exists(t.saveDir)) then return end
  for _, namespace in ipairs(fs.list(t.saveDir)) do
    local nspath = t.saveDir .. namespace;
    for _, type in ipairs(fs.list(nspath)) do
      local itempath = nspath .. "/" .. type;
      local f = fs.open(itempath, "r");
      local common = {};
      common.maxCount = tonumber(f.readLine());
      common.maxDamage = tonumber(f.readLine());
      common.namespace = f.readLine();
      common.type = f.readLine();
      common.format = f.readLine();
      common.tags = {};
      while true do
        local line = f.readLine()
        if (line == nil) then break end
        common.tags[line] = true;
      end
      local name = namespace .. ":" .. type;
      cache[name] = common;
      f.close();
    end
  end
end

function t.exists(type)
  return t.get(type) ~= nil;
end

function t.get(type)
  return cache[type];
end

function t.add(detail)
  save(detail);
end

function t.wrap(item)
  if (item == nil) then return end
  local cacheItem = getCache(item.name);
  if (cacheItem == nil) then return end
  for k, v in pairs(cacheItem) do item[k] = v; end
  return item;
end

function t.format(name)
  local cached = t.get(name);
  if (cached ~= nil) then return cached.format; end
  return t.type(name):gsub("_", " "):gsub("%L%l", string.upper):gsub("^%l", string.upper)
end

function t.namespace(name)
  return name:match("(.+):");
end

function t.type(name)
  return name:match(":(.+)");
end

load();

return t;