local t = {};

local parentRenderList = {};
local renderItemIndex = 1;

local function get(index)
  return parentRenderList[index];
end

local function getCurrent()
  return get(renderItemIndex);
end

function t.inBounds(x, y, bx, by, mx, my)
  return x >= bx and x < mx and y >= by and y < my;
end

function t.register(parentRenderItem)
  table.insert(parentRenderList, parentRenderItem);
  parentRenderItem.index = #parentRenderList;
end

function t.onRender()
  local current = getCurrent();
  current.onRender(current);  
end

function t.onClick(x, y)
  local current = getCurrent();
  current.onClick(current, x, y)
end

function t.onKey(key)
  local current = getCurrent();
  current.onKey(current, key);
end

function t.getCurrent()
  return renderItemIndex;
end

function t.setCurrent(renderItem)
  renderItemIndex = renderItem.index;
end

return t;