local function toBinary(num)
  local binStr = "";
  while num > 0 do
    local rest = num % 2;
    binStr = binStr .. rest;
    num = (num - rest) / 2
  end
  return binStr
end

write(toBinary(7));