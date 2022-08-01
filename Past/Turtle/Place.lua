while true do
  local success = turtle.placeDown();
  if (not success) then turtle.forward(); end
end