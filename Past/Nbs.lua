local nbsAPI = require("NBSAPI");

local fileName, forceTempo, forceVolume = ...;
if (forceTempo == "def") then forceTempo = nil; end
if (forceVolume == "def") then forceVolume = nil; end
forceTempo = tonumber(forceTempo);
forceVolume = tonumber(forceVolume);

if (not fileName:find("%.nbs")) then fileName = fileName .. ".nbs"; end
local speaker = peripheral.find("speaker");
if (not fs.exists(fileName)) then print("No Such File"); error() end
local song = nbsAPI.load(fileName);
if (not song) then print("Couldn't load Song..."); error() end
song.tempo = forceTempo or song.tempo;
if (song.name == "") then song.name = "No Name"; end
print(string.format("Playing %s (%sbps). %ss", song.name, song.tempo, song.length / 20));
song.play(speaker, forceVolume);
