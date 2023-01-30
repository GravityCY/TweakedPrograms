local Command = require("Command");

while true do
  local input = read();
  Command.parse(input)
end