local t = {};

local function pushAll(from, toAddr)
  local pushed = 0;
  for slot in pairs(from.list()) do
    pushed = pushed + from.pushItems(toAddr, slot, 64)
  end
  return pushed;
end

local function getAny(inv)
  for _, item in pairs(inv.list()) do
    return item.name;
  end
end

function t.new(addrFaceInput, addrFaceOutput, addrInput, addrOutput)
  local p = {};

  local faceInput = peripheral.wrap(addrFaceInput);
  local output = peripheral.wrap(addrOutput);

  local totalProcessed = 0;
  local recentItem = "Nothingness";

  function p.getTotal()
    return totalProcessed;
  end

  function p.getRecentItem()
    return recentItem;
  end

  function p.main()
    local found = getAny(faceInput);
    if (found ~= nil) then recentItem = found; end
    pushAll(faceInput, addrInput);
    local processed = pushAll(output, addrFaceOutput);
    totalProcessed = totalProcessed + processed;
  end

  return p;
end

return t;