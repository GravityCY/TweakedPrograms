local function isQuote(char)
  return char == "\"" or char == "'";
end

local function parse(input)
  local args = {};

  local i = 1;
  while true do
    local str = "";
    local quote = nil;
    while true do
      if (i > #input) then break end
      local char = input:sub(i, i);
      if (quote == nil and str ~= "" and char == " ") then break end

      if (isQuote(char)) then
        if (quote == nil) then quote = char;
        elseif (quote ~= char) then str = str .. char;
        else break end
      elseif ((quote ~= nil and char == " ") or (char ~= " ")) then str = str .. char; end
      i = i + 1;
    end
    i = i + 1;
    if (str == "") then break end
    table.insert(args, str);
  end
  return args;
end

for k,v in pairs(parse(read())) do print(k,v) end