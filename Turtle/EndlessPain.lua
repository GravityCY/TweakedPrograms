local lore = "The fabled prize awaits at the bottom...";

local function drop()
  for i = 1, 16 do
    local item = turtle.getItemDetail(i);
    if (item) then
      if (item.name ~= "minecraft:barrel") then
        turtle.select(i);
        turtle.dropDown();
      else
        item = turtle.getItemDetail(i, true);
        if (not item.lore or item.lore[1] ~= lore) then
          turtle.select(i);
          turtle.dropDown();
        end
      end
    end
  end
end

local function getSlot()
  for i = 1, 16 do
    local item = turtle.getItemDetail(i);
    if (item and item.name == "minecraft:barrel") then
      item = turtle.getItemDetail(i, true);
      if (item.lore and item.lore[1] == lore) then
        return i;
      end
    end
  end
end

while true do
  drop();
  turtle.select(getSlot());
  turtle.place()
  turtle.select(1);
  turtle.dig();
end