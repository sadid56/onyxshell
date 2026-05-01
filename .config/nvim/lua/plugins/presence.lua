return {
  "andweeb/presence.nvim",
  lazy = false, -- load at startup
  config = function()
    require("presence").setup({
      auto_update = true,
      neovim_image_text = "The One True Text Editor",
      main_image = "neovim",
      client_id = "793271441293967371",
      debounce_timeout = 10,
      editing_text = "Editing %s",
      file_explorer_text = "Browsing %s",
      git_commit_text = "Committing changes",
      plugin_manager_text = "Managing plugins",
      reading_text = "Reading %s",
      workspace_text = "Working on %s",
    })
  end,
}
