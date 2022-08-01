local function getInput()
  local args = {};
  local input = read();

  local i = 1;
  while true do
    local str = "";
    local quote = nil;
    while true do
      local char = input:sub(i, i);
      if (char == "") then break end
      if (char == "\"" or char == "\'") then
        if (not quote) then 
          quote = char;
          i = i + 1;
          char = input:sub(i, i);
        elseif (char == quote) then break end
      end
      if (not quote) then
        if (char == " ") then 
          if (str ~= "") then break end
        else str = str .. char; end
      else str = str .. char; end
      i = i + 1;
    end
    i = i + 1;
    if (str == "") then break end
    table.insert(args, str);
  end
  return args;
end

for k,v in pairs(getInput()) do write(k,v ) end