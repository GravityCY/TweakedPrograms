local mon = peripheral.find("monitor");
mon.setTextScale(3.5);
local mx, my = mon.getSize();
local midX = mx / 2
local midY = my / 2

local sleepTime = 0.83;

local function getTime(num)
  local hours = math.floor(num);
  local minutes = math.floor(num * 60 % 60);
  local seconds = math.floor(num * 60 * 60 % 60);
  return hours, minutes, seconds;
end

local function getFormatTime(hours, minutes)
  local formatHours = ("%.0f"):format(hours);
  local formatMin = ("%.0f"):format(minutes);
  if (formatHours:len() == 1) then formatHours = "0" .. formatHours; end
  if (formatMin:len() == 1) then formatMin = "0" .. formatMin; end
  return formatHours, formatMin;
end

while true do
  local hours, minutes = getTime(os.time());
  local strHours, strMinutes = getFormatTime(hours, minutes);
  local str = strHours .. ":" .. strMinutes;
  mon.clear();
  mon.setCursorPos(math.ceil(midX - #str / 2), math.ceil(midY));
  mon.write(str);
  sleep(sleepTime);
end