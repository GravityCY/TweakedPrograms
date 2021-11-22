local t = require("TermUtils");
local selections = {"Monitor", "Terminal", "Pocket Computer"};
local tab = {};
tab.header = "Choose Where to Print:";
tab.prefix = "Choose This: ";
tab.postfix = " <";
tab.selections = selections;
t.select(tab);