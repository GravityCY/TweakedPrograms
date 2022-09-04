local t = {};
t.saveDirectory = "/data/localization/";

local locales = {};
local current = "en_us";

local function load()
  if (not fs.exists(t.saveDirectory)) then return false end
  for _, localeName in pairs(fs.list(t.saveDirectory)) do
    local locale = {};
    local f = fs.open(t.saveDirectory..localeName, "r");
    while true do
      local line = f.readLine();
      if (line == nil) then break end
      local key = line:match("%S+");
      local value = line:match("%s(.+)");
      locale[key] = value;
    end
    locales[localeName] = locale;
  end
end

function t.isLocale(localeName)
  return locales[localeName] ~= nil;
end

function t.isKey(key)
  return t.get(key) ~= nil;
end

function t.setLocale(localeName)
  if(not t.isLocale(localeName)) then return end
  current = localeName;
end

function t.get(key)
  return locales[current][key];
end

function t.setSaveDirectory(saveDir)
  t.saveDirectory = saveDir;
end

function t.init()
  load();
end



return t;