while true do
  os.pullEvent("redstone");
  if (redstone.getInput("back")) then
    turtle.digUp();
    turtle.placeUp();
  end
end