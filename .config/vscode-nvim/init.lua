local utils = require("utils")
local mappings = require("mappings")
local option = require("options")

utils.load_mappings(mappings)

-- disable some default providers
for _, provider in ipairs({ "node", "perl", "python3", "ruby" }) do
	vim.g["loaded_" .. provider .. "_provider"] = 0
end
