local t = {};

function t.saveDownload(url, savePath)
  local resfile = http.get(url);
  if (resfile == nil) then return end
  local data = resfile.readAll();
  local saveFile = fs.open(savePath, "w");
  saveFile.write(data);
  saveFile.close();
end

return t;