local yt = {};
local JSON = {};
local Video = {};
local Comment = {};

local apiKey = nil;

function JSON.toObj(str)
  return textutils.unserializeJSON(str);
end

function Video.new(title, id)
  local t = {};
  t.title = title;
  t.id = id;
  return t;
end

function Video.newAPI(apiObj)
  return Video.new(apiObj.snippet.title, apiObj.id.videoId);
end

function Comment.new(userName, content)
  local t = {};
  t.userName = userName;
  t.textContent = content;
  return t;
end

function Comment.newAPI(apiObj)
  local un = apiObj.snippet.topLevelComment.snippet.authorDisplayName;
  local tc = apiObj.snippet.topLevelComment.snippet.textDisplay;
  return Comment.new(un, tc);
end

function yt.register(api)
  apiKey = api;
end

function yt.getChannelID(userName)
  local res = http.get("https://youtube.googleapis.com/youtube/v3/channels?part=id&forUsername="..userName.."&key="..apiKey)
  local data = res.readAll();
  local obj = JSON.toObj(data);
  return obj.items[1].id;
end

function yt.getComments(videoID)
  local res = http.get("https://youtube.googleapis.com/youtube/v3/commentThreads?part=snippet&videoId="..videoID.."&textFormat=plainText&key="..apiKey);
  local data = res.readAll();
  local obj = JSON.toObj(data);
  local comments = {};
  for i, v in ipairs(obj.items) do comments[i] = Comment.newAPI(v); end
  return comments;
end

function yt.getLatestVideo(channelId)
  local res = http.get("https://youtube.googleapis.com/youtube/v3/search?part=snippet&channelId="..channelId.."&order=date&maxResults=1&key="..apiKey);
  local data = res.readAll(0);
  local obj = JSON.toObj(data);
  return Video.newAPI(obj.items[1]);
end

return yt;