local t = {};

function t.open(modem)
  rednet.open(modem);
end

return t;