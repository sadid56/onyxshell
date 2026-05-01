return {
  -- ESLint config
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        eslint = {
          settings = {
            format = { enable = false }, -- let null-ls handle formatting
          },
          handlers = {
            ["textDocument/diagnostic"] = function(...)
              return {}
            end,
          },
        },
      },
    },
  },
}
