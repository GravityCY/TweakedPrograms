local Renderer = require("Renderer");
local Utils = require("Utils");

local t = {};

function t.Button(x, y, w, h)
  local self = {};
  self.x = x;
  self.y = y;
  self.mx = x + w;
  self.my = y + h;
  self.w = w;
  self.h = h;
  self.text = "Sample";
  self.textColor = colors.white;
  self.backgroundColor = colors.black;
  self.onClickFN = nil;
  self.onRenderFN = nil;
  self.data = nil;

  function self.setData(data)
    self.data = data;
    return self;
  end

  function self.setText(text)
    self.text = text;
    return self;
  end

  function self.setTextColor(textColor)
    self.textColor = textColor;
    return self;
  end

  function self.setBackgroundColor(backgroundColor)
    self.backgroundColor = backgroundColor;
    return self;
  end

  function self.setOnRender(onRenderFN)
    self.onRenderFN = onRenderFN;
    return self;
  end

  function self.setOnClick(onClickFN)
    self.onClickFN = onClickFN;
    return self;
  end

  function self.onRender(_)
    if (self.onRenderFN ~= nil) then self.onRenderFN(self);
    else
      local p, pp = term.getBackgroundColor(), term.getTextColor();
      paintutils.drawFilledBox(self.x, self.y, self.mx - 1, self.my - 1, self.backgroundColor);
      term.setTextColor(self.textColor);
      Utils.printCenterXY(self.x, self.mx, self.y, self.my, self.text);
      term.setTextColor(pp);
      term.setBackgroundColor(p);
    end
  end

  function self.onClick(_, cx, cy)
    if (Renderer.inBounds(cx, cy, self.x, self.y, self.mx, self.my)) then
      if (self.onClickFN ~= nil) then self.onClickFN(self, cx, cy); end
    end
  end

  return self;
end

function t.Frame()
  local self = {};
  self.onRenderFN = nil;
  self.onClickFN = nil;
  self.onKeyFN = nil;
  self.data = nil;

  function self.setOnClick(onClickFN)
    self.onClickFN = onClickFN;
    return self;
  end

  function self.setOnRender(onRenderFN)
    self.onRenderFN = onRenderFN;
    return self;
  end

  function self.setOnKey(onKeyFN)
    self.onKeyFN = onKeyFN;
    return self;
  end

  function self.setData(data)
    self.data = data;
    return self;
  end

  local renderList = {};
  function self.register(renderItem)
    if (renderItem == nil) then return end
    table.insert(renderList, renderItem);
    renderItem.index = #renderList;
  end

  function self.unregister(renderItem)
    if (renderItem.index == nil) then return end
    table.remove(renderList, renderItem.index);
    for index, renderItemValue in ipairs(renderList) do renderItemValue.index = index; end
  end
  
  function self.clear()
    renderList = {};
  end

  function self.onRender(_)
    if (self.onRenderFN ~= nil) then self.onRenderFN(self); end
    for _, renderItem in ipairs(renderList) do
      renderItem.onRender(renderItem);
    end
  end

  function self.onClick(self, x, y)
    if (self.onClickFN ~= nil) then self.onClickFN(self, x, y); end
    for _, renderItem in ipairs(renderList) do
      if (renderItem.onClick ~= nil) then
        renderItem.onClick(renderItem, x, y);
      end
    end
  end

  function self.onKey(self, key)
    if (self.onKeyFN ~= nil) then self.onKeyFN(self, key); end
    for _, renderItem in ipairs(renderList) do
      if (renderItem.onKey ~= nil) then
        renderItem.onKey(renderItem, key); 
      end
    end
  end

  return self;
end

return t;