local monitor = peripheral.find("monitor");

monitor.setTextScale(0.5);

term.redirect(monitor);

local function getXY()
  local _, _, x, y = os.pullEvent("monitor_touch");
  return {x=x, y=y};
end

local function lerp(x, y, t)
   return x + (y - x) * t;
end

local function drawPoint(x, y)
  term.setCursorPos(x, y);
  term.write(" ");
end


term.setBackgroundColor(colors.black);
term.clear();
term.setBackgroundColor(colors.white);


while true do
  local startPoint = getXY();
  drawPoint(startPoint.x, startPoint.y);
  local controlPoint = getXY();
  drawPoint(controlPoint.x, controlPoint.y);
  local endPoint = getXY();
  drawPoint(endPoint.x, endPoint.y);


  for t = 0, 1, 0.01 do 
    local x1 = lerp(startPoint.x, controlPoint.x, t);
    local y1 = lerp(startPoint.y, controlPoint.y, t);
    local x2 = lerp(controlPoint.x, endPoint.x, t);
    local y2 = lerp(controlPoint.y, endPoint.y, t);
    drawPoint(lerp(x1, x2, t), lerp(y1, y2, t));
  end
end