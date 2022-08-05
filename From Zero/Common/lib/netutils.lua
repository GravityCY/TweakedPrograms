local t = {};

function t.saveDownload(url, savePath)
  local resfile = http.get(url);
  local data = resfile.readAll();
  local saveFile = fs.open(savePath, "w");
  saveFile.write(data);
end

return t;