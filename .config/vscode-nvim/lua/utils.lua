local M = {}
local merge_tb = vim.tbl_deep_extend

-- source: https://github.com/NvChad/NvChad/blob/c80f3f0501800d02b0085ecc1f79bfc64327d01e/lua/core/utils.lua#L54
M.load_mappings = function(section, mapping_opt)
  local function set_section_map(section_values)
    if section_values.plugin then
      return
    end

    section_values.plugin = nil

    for mode, mode_values in pairs(section_values) do
      local default_opts = merge_tb("force", { mode = mode }, mapping_opt or {})
      for keybind, mapping_info in pairs(mode_values) do
        -- merge default + user opts
        local opts = merge_tb("force", default_opts, mapping_info.opts or {})

        mapping_info.opts, opts.mode = nil, nil
        opts.desc = mapping_info[2]

        vim.keymap.set(mode, keybind, mapping_info[1], opts)
      end
    end
  end

  for _, sect in pairs(section) do
    set_section_map(sect)
  end
end

return M
