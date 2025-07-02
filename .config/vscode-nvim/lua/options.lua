local o = vim.opt
local g = vim.g

o.number = true
o.clipboard = "unnamed"

-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
o.whichwrap:append("<>[]hl")
o.timeoutlen = 400
o.undofile = true

-- interval for writing swap file to disk, also used by gitsigns
o.updatetime = 250

g.mapleader = " "
