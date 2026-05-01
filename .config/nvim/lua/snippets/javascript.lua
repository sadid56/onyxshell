local M = {}

-- 🔹 Create React Component
function M.create_component()
  local filename = vim.fn.expand("%:t:r")
  local component_name = filename:gsub("^%l", string.upper)

  local lines = {
    "import React from 'react';",
    "",
    "const " .. component_name .. " = () => {",
    "  return (",
    "    <div>",
    "      <h1>Hello " .. component_name .. "</h1>",
    "    </div>",
    "  );",
    "};",
    "",
    "export default " .. component_name .. ";",
  }

  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

-- 🔹 Insert useState
function M.insert_usestate()
  vim.api.nvim_put({ "const [state, setState] = useState('');" }, "l", true, true)
end

-- 🔹 Insert useEffect
function M.insert_useeffect()
  local lines = {
    "useEffect(() => {",
    "  // effect",
    "  return () => {",
    "    // cleanup",
    "  };",
    "}, []);",
  }
  vim.api.nvim_put(lines, "l", true, true)
end

-- 🔹 Arrow function
function M.insert_function()
  local lines = {
    "const funcName = () => {",
    "  console.log('funcName called');",
    "};",
  }
  vim.api.nvim_put(lines, "l", true, true)
end

-- 🔹 Imports
function M.import_react()
  vim.api.nvim_put({ "import React from 'react';" }, "l", true, true)
end

function M.import_hooks()
  vim.api.nvim_put({ "import React, { useState, useEffect } from 'react';" }, "l", true, true)
end

return M
