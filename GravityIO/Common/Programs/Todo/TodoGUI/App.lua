local Renderer = require("Renderer");
local Pages = require("Pages");
Pages.init();

term.setCursorBlink(false);
term.clear();
Renderer.onRender();
while true do
  local event, a1, a2, a3 = os.pullEvent();
  if (event == "mouse_click") then
    local x, y = a2, a3;
    term.clear();
    Renderer.onClick(x, y);
    Renderer.onRender();
  elseif (event == "key_up") then
    local key = a1;
    term.clear();
    Renderer.onKey(key);
    Renderer.onRender();
  end
end
