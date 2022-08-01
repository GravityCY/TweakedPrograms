local modem = peripheral.find("modem");
rednet.open(peripheral.getName(modem));

local storageID = nil;

local dataPath = "/craft/";
local recipePath = dataPath .. "recipes/"

local craftToGlobal = { [1]=1, [2]=2, [3]=3, 
                        [4]=5, [5]=6, [6]=7, 
                        [7]=9, [8]=10, [9]=11 };

local Recipe = {};

function Recipe.new(productName, out, materials)
  local t = {};
  t.productName = productName;
  t.out = out or 1;
  t.materials = materials or {};
  return t;
end
                 
while true do
  print("Waiting for Message...");
  local id, msg, filter = rednet.receive();
  if (not storageID) then storageID = id; end
  if (filter == "new") then
    print("Registering new Recipe")
    local recipe = Recipe.new();
    for i = 1, 9 do
      local slot = craftToGlobal[i];
      local item = turtle.getItemDetail(slot);
      if (item ~= nil) then recipe.materials[i] = item.name; end
    end
    local item = turtle.getItemDetail(16);
    if (item ~= nil) then
      recipe.product = item.name;
      recipe.out = item.count;
    end
    rednet.send(storageID, recipe, "recipe");
  elseif (filter == "craft") then
    turtle.craft();
    print("Crafted...");
  elseif (filter == "list") then
    local list = {};
    for i = 1, 16 do 
      local item = turtle.getItemDetail(i);
      list[i] = item;
    end
    sleep(0.5);
    rednet.send(storageID, list, "list");
  end 
end

-- if (arg == "new") then
--   local recipe = { materials={}, product=nil };
--   
-- else
--   print(loadRecipe(arg));
-- end