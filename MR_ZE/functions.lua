local function loadFilterList()
  local fileNames = fs.list("/barrel_data");
  for _, fileName in ipairs(fileNames) do
    local filter = fs.open("/barrel_data/" .. fileName);
    while true do
      local line = filter.readLine();
      if (line == nil) then break end
      local slot = tonumber(line);
      local type = filter.readLine();
    end
    filter.close();
  end
end

local list = loadFilterList()