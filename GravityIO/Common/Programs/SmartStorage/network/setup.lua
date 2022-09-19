local NetUtils = {};

function NetUtils.saveDownload(url, savePath)
  local resfile = http.get(url);
  if (resfile == nil) then return false end
  local data = resfile.readAll();
  local saveFile = fs.open(savePath, "w");
  saveFile.write(data);
  saveFile.close();
  resfile.close();
  return true;
end

NetUtils.saveDownload("https://raw.githubusercontent.com/GravityCY/cc-t/master/GravityIO/Common/Programs/SmartStorage/network/SmartStorage.lua", "SmartStorage.lua")
NetUtils.saveDownload("https://raw.githubusercontent.com/GravityCY/cc-t/master/GravityIO/Common/Programs/SmartStorage/network/StorageNetworkAPI.lua", "StorageNetworkAPI.lua")
NetUtils.saveDownload("https://raw.githubusercontent.com/GravityCY/cc-t/master/GravityIO/Common/Programs/SmartStorage/network/CraftingAPI.lua", "CraftingAPI.lua")
NetUtils.saveDownload("https://raw.githubusercontent.com/GravityCY/cc-t/master/GravityIO/Common/lib/PerUtils.lua", "PerUtils.lua");
NetUtils.saveDownload("https://raw.githubusercontent.com/GravityCY/cc-t/master/GravityIO/Common/lib/ItemUtils.lua", "ItemUtils.lua");
NetUtils.saveDownload("https://raw.githubusercontent.com/GravityCY/cc-t/master/GravityIO/Common/lib/InvUtils.lua", "InvUtils.lua");
NetUtils.saveDownload("https://raw.githubusercontent.com/GravityCY/cc-t/master/GravityIO/Common/lib/TableUtils.lua", "TableUtils.lua");
NetUtils.saveDownload("https://raw.githubusercontent.com/GravityCY/cc-t/master/GravityIO/Common/lib/Localization.lua", "Localization.lua");