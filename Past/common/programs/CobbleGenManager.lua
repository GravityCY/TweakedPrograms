local miners = {peripheral.find("turtle")};
local out = peripheral.find("minecraft:chest");

local modem = peripheral.find("modem");

local runMainThread = true;

local isPaused = false;

local function full()
  local slots = 0;
  for _ in pairs(out.list()) do slots = slots + 1; end
  return slots == out.size();
end

local function pauseMiner()
  modem.transmit(1, 1, "pause");
  isPaused = true;
end

local function pauseAll()
  pauseMiner();
  runMainThread = false;
end

local function resumeMiner()
  modem.transmit(1, 1, "resume");
  isPaused = false;
end

local function resumeAll()
  resumeMiner();
  runMainThread = true;
end

local function mainThread()
  while runMainThread do
    if (not full()) then
      if (isPaused) then resumeMiner(); end
      for _, miner in ipairs(miners) do
        for i = 1, 16 do
          out.pullItems(peripheral.getName(miner), i, 64);
        end
      end
    else pauseMiner(); end
    sleep(10);
  end
end

local function rsThread()
  os.pullEvent("redstone");
  if (redstone.getInput("top")) then resumeAll();
  else pauseAll(); end
end

while true do
  local runs = {rsThread};
  if (runMainThread) then runs[#runs+1] = mainThread; end
  parallel.waitForAny(tableutils.unpack(runs));
end