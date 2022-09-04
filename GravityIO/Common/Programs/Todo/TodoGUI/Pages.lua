local t = {};

local Renderer = require("Renderer");
local TodoList = require("TodoList");
local Objects = require("Objects");
local Utils = require("Utils");
local Frame = Objects.Frame;
local Button = Objects.Button;

TodoList.savePath = "/data/todo/data";
TodoList.loadPath = "/data/todo/data";

function t.init()

  TodoList.load();
  local tmx, tmy = term.getSize();

  -- #region Main Page
  local function mainOnRender(self)
    term.setBackgroundColor(colors.black);
    term.setTextColor(colors.white);
    Utils.printCenterX(1, tmx, 1, "Main Page");
  end
  
  local function listOnRender(self)
    Utils.printCenterX(1, tmx, 1, "List Page");
    paintutils.drawFilledBox(1, tmy, tmx, tmy, colors.red);
    term.setBackgroundColor(colors.black);
  end

  local mainPage = Frame().setOnRender(mainOnRender);
  local listPage = Frame().setOnRender(listOnRender);

  local gotoListButton = Button(1, 3, tmx, 3)
                        .setBackgroundColor(colors.red)
                        .setText("List")
                        .setTextColor(colors.white)
                        .setOnClick(function() Renderer.setCurrent(listPage); end);

  mainPage.register(gotoListButton);
  -- #endregion

  -- #region List Page


  local todoW, todoH = tmx, 4;
  local todoSpacing = 1;

  local function todoRender(self)
    local delX, delY = self.mx - 1, self.y;
    paintutils.drawFilledBox(self.x, self.y, self.mx - 1, self.my - 1, colors.orange);
    paintutils.drawFilledBox(self.x, self.y, self.mx - 1, self.y, colors.white);
    term.setTextColor(colors.black);
    Utils.printCenterX(self.x, self.mx, self.y, self.data.todo.title);
    term.setTextColor(colors.red);
    term.setBackgroundColor(colors.gray)
    term.setCursorPos(delX, delY);
    term.write("X");
    term.setBackgroundColor(colors.orange);
    term.setTextColor(colors.white);
    print(self.data.todo.description);
    term.setBackgroundColor(colors.black);
  end

  local function todoClick(self, x, y)
    if (x == self.mx - 1 and y == self.y) then TodoList.remove(self.data.todo.title) end
  end

  local function itemListOnRender(self)
    self.clear();
    local todos = TodoList.list();
    if (#todos == 0) then
      local btn = Button(1, 3, todoW, 3)
                  .setText("No Todos :(")
                  .setTextColor(colors.white)
                  .setBackgroundColor(colors.orange);
      self.register(btn);
    end
    local ii = 1;
    for i = self.data.index, #todos do
      local todo = todos[i];
      local x, y = 1, (ii - 1) * todoH + (ii - 1) * todoSpacing + 3;
      local btn = Button(x, y, todoW, todoH)
                  .setData({todo=todo, index=i})
                  .setOnRender(todoRender)
                  .setOnClick(todoClick);
      if (btn.my < tmy - 1) then 
        self.register(btn);
      else break end
      ii = ii + 1;
    end
  end

  local function itemListOnKey(self, key)
    if (key == keys.up) then
      if (self.data.index > 1) then
        self.data.index = self.data.index - 1;
      end
    end
    if (key == keys.down) then
      if (self.data.index < #TodoList.list()) then
        self.data.index = self.data.index + 1;
      end
    end
  end


  local todoItemList = Frame()
                      .setOnRender(itemListOnRender)
                      .setOnKey(itemListOnKey)
                      .setData({index=1});

  local goBackButton = Button(1, tmy - 1, 6, 1)
                        .setText("Back")
                        .setTextColor(colors.white)
                        .setBackgroundColor(colors.orange)
                        .setOnClick(function() Renderer.setCurrent(mainPage); end);
  
  local function newOnClick(self, x, y)
    term.clear();
    term.write("Todo Title:");
    local title = read();
    term.write("Todo Description:");
    local description = read();
    TodoList.add(title, description);
  end
                    

  local newButton = Button(7, tmy - 1, 5, 1)
                    .setText("New")
                    .setTextColor(colors.black)
                    .setBackgroundColor(colors.white)
                    .setOnClick(newOnClick);

  listPage.register(todoItemList);
  listPage.register(goBackButton);
  listPage.register(newButton);
  -- #endregion

  Renderer.register(mainPage);
  Renderer.register(listPage);
end

return t;