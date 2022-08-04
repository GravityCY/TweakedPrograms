local url = "https://raw.githubusercontent.com/dominictarr/random-name/master/first-names.txt";

local args = {...};

local res = http.get(url);
local lines = {};

while true do
  local line = res.readLine();
  if (line == nil) then break end
  lines[#lines + 1] = line;
end

local label = lines[math.random(#lines)];
if (args[1] ~= nil) then label = args[1] .. " ".. label; end
os.setComputerLabel(label);
