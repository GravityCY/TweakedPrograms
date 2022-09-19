local ItemUtils = require("ItemUtils");

local t = {};
t.saveDirectory = "/data/craftingapi/recipes/";

local recipeLookup = {};

local function load()
  if (not fs.exists(t.saveDirectory)) then return end
  for _, namespace in ipairs(fs.list(t.saveDirectory)) do
    local namespaceDir = t.saveDirectory .. namespace .. "/";
    for _, item in ipairs(fs.list(namespaceDir)) do
      local f = fs.open(namespaceDir..item, "r");
      local resources = {};
      local product = namespace .. ":" .. item;
      local count = 0;
      while true do
        local line = f.readLine();
        if (line == "end") then break end
        local slot = tonumber(line);
        local resource = f.readLine();
        resources[slot] = resource;
      end
      count = tonumber(f.readLine());
      f.close();
      t.add(t.Recipe(resources, product, count));
    end
  end
end

function t.Recipe(resources, product, count)
  local r = {};
  r.resources = resources;
  r.product = product;
  r.count = count;
  return r;
end

function t.setSaveDirectory(saveDirectory)
  t.saveDirectory = saveDirectory;
end

function t.save()
  for product, recipe in pairs(recipeLookup) do
    t.saveRecipe(recipe);
  end
end

function t.saveRecipe(recipe)
  local f = fs.open(t.saveDirectory .. ItemUtils.namespace(recipe.product) .. "/" .. ItemUtils.type(recipe.product), "w");
    for slot, resource in pairs(recipe.resources) do
      f.write(slot .. "\n");
      f.write(resource .. "\n");
    end
    f.write("end\n");
    f.write(recipe.count .. "\n");
    f.close();
end

function t.total(recipe, times)
  times = times or 1;
  local t1 = {};
  for _, item in pairs(recipe.resources) do
    t1[item] = (t1[item] or 0) + times;
  end
  return t1;
end

function t.get(product)
  return recipeLookup[product];
end

function t.exists(product)
  return t.get(product) ~= nil;
end

function t.remove(product)
  recipeLookup[product] = nil;
  local path = t.saveDirectory..toPath(product);
  if (fs.exists(path)) then fs.delete(path); end
end

function t.add(recipe)
  local k = recipe.product;
  if (t.exists(k)) then t.remove(k) end
  recipeLookup[k] = recipe;
  t.saveRecipe(recipe);
end

function t.list()
  local l = {};
  for product, recipe in pairs(recipeLookup) do
    table.insert(l, recipe);
  end
  return l;
end

function t.init()
  load();
end


return t;