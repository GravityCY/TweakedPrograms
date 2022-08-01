local yt = require("ytapi");
local apiKey = "AIzaSyCfyNQO7S9r0zWSdXfWc-CaEJ7NsK9rchc";
yt.register(apiKey);

local mx, my = term.getSize();

term.clear();
term.setCursorPos(1, 1);

-- local channelId = "UC7vPe3g5KauQTw8XsZmZOrg";
local channelId = "UCIjeBveQ1nXJF1ZNM4CIR1A";
local video = yt.getLatestVideo(channelId);
local comments = yt.getComments(video.id);
local str = "Comments";
local cop = ("-"):rep(mx / 2 - #str / 2);
print(cop .. str .. cop);
for i, comment in ipairs(comments) do
  print(comment.userName ..": " .. comment.textContent);
end