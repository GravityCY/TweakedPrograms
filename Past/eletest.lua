local modem = peripheral.find("modem");
rednet.open(peripheral.getName(modem));

local currentFloor = 0;

if (fs.exists("/floor.fl")) then
  local file = fs.open("/floor.fl", "rb");
  currentFloor = file.read();
  file.close();
else
  local file = fs.open("/floor.fl", "wb");
  file.write(0);
  file.close();
end

local function onRedstoneChanged(side)
  local prev = redstone.getInput(side);
  while true do
    os.pullEvent("redstone");
    if (redstone.getInput(side) ~= prev) then break end
  end
end

local function onRedstoneActivated(side)
  while true do
    os.pullEvent("redstone");
    if (redstone.getInput(side)) then break end
  end
end

local function setEnabled(value)
    redstone.setOutput("left", not value);
    return value;
end
 
local function setDown(value)
    redstone.setOutput("right", value)    
    return value;
end

local function goFloor(current, destination)
  local goingDown = false;
  local enabled = false;
  local diff = current - destination;
  if (diff == 0) then print("That's the Current Floor") return end
  goingDown = setDown(diff >= 1);
  enabled = setEnabled(true);

  print("Current Floor: #" .. current);
  print("Going to Floor #" .. destination);

  local count = 0;
  onRedstoneChanged("top");
  local startTime = os.clock();
  while true do
    local event = os.pullEvent();
    if (event == "redstone") then
      local levelChange = redstone.getInput("top");
      if (levelChange) then
        count = count + 1;
        if (count == math.abs(diff)) then break end
      end
    end
  end
  local endTime = os.clock();
  enabled = setEnabled(false);
  goingDown = setDown(false);
  print("Arrived");
  print("Took " .. string.format("%.2f", endTime - startTime) .. " seconds.");
end


local function getFloorModem()
  local id, msg = rednet.receive("setFloor");
  return tonumber(msg);
end

local function getFloorRedstone()
  local negative = nil;
  local floor = nil;

  -- Whenever redstone get's activated
  onRedstoneActivated("back");
  local negBit = redstone.getAnalogInput("back");
  if (negBit == 15) then negative = true; end
  if (negBit == 1) then negative = false; end

  onRedstoneActivated("back");
  floor = redstone.getAnalogInput("back") - 1;

  if (negative) then floor = -floor; end
  return floor;
end

local function getFloor()
  local floor = 0;
  parallel.waitForAny(function() floor = getFloorRedstone(); end, function() floor = getFloorModem(); end)
  return floor;
end

setEnabled(false);

while true do
  local destination = getFloor();
  goFloor(currentFloor, destination);
  local file = fs.open("/floor.fl", "wb");
  currentFloor = destination;
  file.write(currentFloor); 
  file.close();
end