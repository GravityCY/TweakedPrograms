local paths = {"mine.lua", "setup.lua", "download.lua"}
for _, v in ipairs(paths) do
  if (fs.exists("/disk/" .. v)) then fs.delete("/disk/"..v); end
  fs.copy("/"..v, "/disk/" .. v);
end