local runMainThread = true;
 
local function mainThread()
    local i = 0;
    while true do
        if (not runMainThread) then coroutine.yield(); end
        term.clear();
        term.setCursorPos(1, 1);
        write(i);
        i = i + 1;
        sleep(1);
    end
end
 
local function rs()
    for i = 1, 2 do os.pullEvent("redstone") end
end
 
local crs = coroutine.create(rs);
local mrc = coroutine.create(mainThread);
coroutine.resume(crs);
coroutine.resume(mrc);
