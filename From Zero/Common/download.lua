local args = {...};

if (fs.exists(args[1])) then fs.delete(args[1]) end

shell.run("wget", table.unpack(args));