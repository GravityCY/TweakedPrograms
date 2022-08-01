local t = {};

local cached = {};

local function addToMap(item)
  cached[item.name] = { maxCount = item.maxCount, maxDamage = item.maxDamage };
end

local function loadAll()
  local rh = fs.open("/data/items/item.data", "r");
  if (rh == nil) then return end
  while true do
    local line = rh.readLine();
    if (line == nil) then break end
    local itemName, maxCount, maxDamage = line:match("(%S+) (%S+) (%S+)")
    addToMap({name=itemName, maxCount=tonumber(maxCount), maxDamage=tonumber(maxDamage)});
  end
  rh.close();
end

function t.load(itemName)
  return cached[itemName];
end

function t.save(item)
  if (item == nil or item.name == nil or item.maxCount == nil or cached[item.name] ~= nil) then return end
  local wh = fs.open("/data/items/item.data", "a");
  local name = item.name;
  local maxCount = item.maxCount or 0;
  local maxDamage = item.maxDamage or 0;
  wh.write(name .. " ");
  wh.write(maxCount .. " ");
  wh.write(maxDamage .. "\n");
  addToMap(item);
  wh.close();
  return true;
end

function t.format(name)
  return name:match(":(.+)"):gsub("_", " "):gsub("%s.", string.upper):gsub("^.", string.upper);
end

loadAll();
return t;
