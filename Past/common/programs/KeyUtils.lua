local k = {};

function k.pullKey(inputKey)
  while true do
    local _, key, isHeld = os.pullEvent("key");
    if (key == inputKey) then break end
  end
end

return k;