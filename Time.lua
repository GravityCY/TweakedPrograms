local mon = peripheral.find("monitor");
mon.setTextScale(4.5);
local mx, my = mon.getSize();
local midX = mx / 2
local midY = my / 2

local function getTime(num)
  local hours = math.floor(num);
  local minutes = math.floor(num * 60 % 60);
  return hours, minutes;
end

local function getFormatTime(hours, minutes)
  local formatHours = string.format("%.0f", tostring(hours));
  local formatMin = string.format("%.0f", tostring(minutes));
  if (formatHours:len() == 1) then formatHours = "0" .. formatHours; end
  if (formatMin:len() == 1) then formatMin = "0" .. formatMin; end
  return formatHours, formatMin;
end

while true do
  local hours, minutes = getTime(os.time());
  local strHours, strMinutes = getFormatTime(hours, minutes);
  local strHoursLen, strMinutesLen = strHours:len() / 2, strMinutes:len() / 2;
  mon.clear();
  mon.setCursorPos(math.ceil(midX - strHoursLen - strMinutesLen), math.ceil(midY));
  mon.write(strHours .. ":" .. strMinutes);
  sleep(0.4);
end