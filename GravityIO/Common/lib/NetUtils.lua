local t = {};

function t.saveDownload(url, savePath)
  local resfile = http.get(url);
  if (resfile == nil) then return false end
  local data = resfile.readAll();
  local saveFile = fs.open(savePath, "w");
  saveFile.write(data);
  saveFile.close();
  resfile.close();
  return true;
end

return t;