local M = {}

function M.setup()
  if vim.fn.has 'nvim-0.12' == 0 then
    return
  end

  -- Neovim 0.12 removed all=false. The master branch still expects one node per capture.
  local query = vim.treesitter.query
  local original_registration_functions = {
    add_predicate = query.add_predicate,
    add_directive = query.add_directive,
  }

  -- Adapt only the old plugin's handlers, then restore Neovim's registration functions.
  for name, register in pairs(original_registration_functions) do
    query[name] = function(handler_name, handler, opts)
      if type(opts) == 'table' and opts.all == false then
        local legacy_handler = handler
        handler = function(captures, ...)
          local last_captured_nodes = {}
          for capture_id, nodes in pairs(captures) do
            last_captured_nodes[capture_id] = nodes[#nodes]
          end
          return legacy_handler(last_captured_nodes, ...)
        end
      end
      return register(handler_name, handler, opts)
    end
  end

  package.loaded['nvim-treesitter.query_predicates'] = nil
  local loaded, load_error = pcall(require, 'nvim-treesitter.query_predicates')

  for name, register in pairs(original_registration_functions) do
    query[name] = register
  end

  if loaded then
    return
  end
  error(load_error)
end

return M
