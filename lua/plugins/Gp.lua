return {
  "robitx/gp.nvim",
  config = function()
    require("gp").setup()
    -- This function will disable the diagnostic messages for the given buffer
    local function disable_diagnostics_for_buffer(bufnr)
      vim.diagnostic.disable(bufnr)
    end

    -- This function checks if the buffer is created by gp.nvim.
    local function is_gp_buffer(bufnr)
      local name = vim.fn.bufname(bufnr)
      local gp_pattern = "gp"
      return name:match(gp_pattern) ~= nil
    end

    -- Autocmd that disables diagnostics when a new buffer is loaded by gp.nvim.
    vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
      pattern = "*", -- For all buffers; Can restrict further if 'gp.nvim' gives a specific pattern.
      callback = function(args)
        if is_gp_buffer(args.buf) then
          disable_diagnostics_for_buffer(args.buf)
        end
      end,
    })

    -- or setup with your own config (see Install > Configuration in Readme)
    -- require("gp").setup(config)

    -- shortcuts might be setup here (see Usage > Shortcuts in Readme)
    require("which-key").register({
      -- ...
      ["<C-g>"] = {
        c = { ":<C-u>'<,'>GpChatNew<cr>", "Visual Chat New" },
        p = { ":<C-u>'<,'>GpChatPaste<cr>", "Visual Chat Paste" },
        t = { ":<C-u>'<,'>GpChatToggle<cr>", "Visual Toggle Chat" },

        ["<C-x>"] = { ":<C-u>'<,'>GpChatNew split<cr>", "Visual Chat New split" },
        ["<C-v>"] = { ":<C-u>'<,'>GpChatNew vsplit<cr>", "Visual Chat New vsplit" },
        ["<C-t>"] = { ":<C-u>'<,'>GpChatNew tabnew<cr>", "Visual Chat New tabnew" },

        r = { ":<C-u>'<,'>GpRewrite<cr>", "Visual Rewrite" },
        a = { ":<C-u>'<,'>GpAppend<cr>", "Visual Append (after)" },
        b = { ":<C-u>'<,'>GpPrepend<cr>", "Visual Prepend (before)" },
        i = { ":<C-u>'<,'>GpImplement<cr>", "Implement selection" },

        g = {
          name = "generate into new ..",
          p = { ":<C-u>'<,'>GpPopup<cr>", "Visual Popup" },
          e = { ":<C-u>'<,'>GpEnew<cr>", "Visual GpEnew" },
          n = { ":<C-u>'<,'>GpNew<cr>", "Visual GpNew" },
          v = { ":<C-u>'<,'>GpVnew<cr>", "Visual GpVnew" },
          t = { ":<C-u>'<,'>GpTabnew<cr>", "Visual GpTabnew" },
        },

        n = { "<cmd>GpNextAgent<cr>", "Next Agent" },
        s = { "<cmd>GpStop<cr>", "GpStop" },
        x = { ":<C-u>'<,'>GpContext<cr>", "Visual GpContext" },

        w = {
          name = "Whisper",
          w = { ":<C-u>'<,'>GpWhisper<cr>", "Whisper" },
          r = { ":<C-u>'<,'>GpWhisperRewrite<cr>", "Whisper Rewrite" },
          a = { ":<C-u>'<,'>GpWhisperAppend<cr>", "Whisper Append (after)" },
          b = { ":<C-u>'<,'>GpWhisperPrepend<cr>", "Whisper Prepend (before)" },
          p = { ":<C-u>'<,'>GpWhisperPopup<cr>", "Whisper Popup" },
          e = { ":<C-u>'<,'>GpWhisperEnew<cr>", "Whisper Enew" },
          n = { ":<C-u>'<,'>GpWhisperNew<cr>", "Whisper New" },
          v = { ":<C-u>'<,'>GpWhisperVnew<cr>", "Whisper Vnew" },
          t = { ":<C-u>'<,'>GpWhisperTabnew<cr>", "Whisper Tabnew" },
        },
      },
      -- ...
    }, {
      mode = "v", -- VISUAL mode
      prefix = "",
      buffer = nil,
      silent = true,
      noremap = true,
      nowait = true,
    })

    -- NORMAL mode mappings
    require("which-key").register({
      -- ...
      ["<C-g>"] = {
        c = { "<cmd>GpChatNew<cr>", "New Chat" },
        t = { "<cmd>GpChatToggle<cr>", "Toggle Chat" },
        f = { "<cmd>GpChatFinder<cr>", "Chat Finder" },

        ["<C-x>"] = { "<cmd>GpChatNew split<cr>", "New Chat split" },
        ["<C-v>"] = { "<cmd>GpChatNew vsplit<cr>", "New Chat vsplit" },
        ["<C-t>"] = { "<cmd>GpChatNew tabnew<cr>", "New Chat tabnew" },

        r = { "<cmd>GpRewrite<cr>", "Inline Rewrite" },
        a = { "<cmd>GpAppend<cr>", "Append (after)" },
        b = { "<cmd>GpPrepend<cr>", "Prepend (before)" },

        g = {
          name = "generate into new ..",
          p = { "<cmd>GpPopup<cr>", "Popup" },
          e = { "<cmd>GpEnew<cr>", "GpEnew" },
          n = { "<cmd>GpNew<cr>", "GpNew" },
          v = { "<cmd>GpVnew<cr>", "GpVnew" },
          t = { "<cmd>GpTabnew<cr>", "GpTabnew" },
        },

        n = { "<cmd>GpNextAgent<cr>", "Next Agent" },
        s = { "<cmd>GpStop<cr>", "GpStop" },
        x = { "<cmd>GpContext<cr>", "Toggle GpContext" },

        w = {
          name = "Whisper",
          w = { "<cmd>GpWhisper<cr>", "Whisper" },
          r = { "<cmd>GpWhisperRewrite<cr>", "Whisper Inline Rewrite" },
          a = { "<cmd>GpWhisperAppend<cr>", "Whisper Append (after)" },
          b = { "<cmd>GpWhisperPrepend<cr>", "Whisper Prepend (before)" },
          p = { "<cmd>GpWhisperPopup<cr>", "Whisper Popup" },
          e = { "<cmd>GpWhisperEnew<cr>", "Whisper Enew" },
          n = { "<cmd>GpWhisperNew<cr>", "Whisper New" },
          v = { "<cmd>GpWhisperVnew<cr>", "Whisper Vnew" },
          t = { "<cmd>GpWhisperTabnew<cr>", "Whisper Tabnew" },
        },
      },
      -- ...
    }, {
      mode = "n", -- NORMAL mode
      prefix = "",
      buffer = nil,
      silent = true,
      noremap = true,
      nowait = true,
    })

    -- INSERT mode mappings
    require("which-key").register({
      -- ...
      ["<C-g>"] = {
        c = { "<cmd>GpChatNew<cr>", "New Chat" },
        t = { "<cmd>GpChatToggle<cr>", "Toggle Chat" },
        f = { "<cmd>GpChatFinder<cr>", "Chat Finder" },

        ["<C-x>"] = { "<cmd>GpChatNew split<cr>", "New Chat split" },
        ["<C-v>"] = { "<cmd>GpChatNew vsplit<cr>", "New Chat vsplit" },
        ["<C-t>"] = { "<cmd>GpChatNew tabnew<cr>", "New Chat tabnew" },

        r = { "<cmd>GpRewrite<cr>", "Inline Rewrite" },
        a = { "<cmd>GpAppend<cr>", "Append (after)" },
        b = { "<cmd>GpPrepend<cr>", "Prepend (before)" },

        g = {
          name = "generate into new ..",
          p = { "<cmd>GpPopup<cr>", "Popup" },
          e = { "<cmd>GpEnew<cr>", "GpEnew" },
          n = { "<cmd>GpNew<cr>", "GpNew" },
          v = { "<cmd>GpVnew<cr>", "GpVnew" },
          t = { "<cmd>GpTabnew<cr>", "GpTabnew" },
        },

        x = { "<cmd>GpContext<cr>", "Toggle GpContext" },
        s = { "<cmd>GpStop<cr>", "GpStop" },
        n = { "<cmd>GpNextAgent<cr>", "Next Agent" },

        w = {
          name = "Whisper",
          w = { "<cmd>GpWhisper<cr>", "Whisper" },
          r = { "<cmd>GpWhisperRewrite<cr>", "Whisper Inline Rewrite" },
          a = { "<cmd>GpWhisperAppend<cr>", "Whisper Append (after)" },
          b = { "<cmd>GpWhisperPrepend<cr>", "Whisper Prepend (before)" },
          p = { "<cmd>GpWhisperPopup<cr>", "Whisper Popup" },
          e = { "<cmd>GpWhisperEnew<cr>", "Whisper Enew" },
          n = { "<cmd>GpWhisperNew<cr>", "Whisper New" },
          v = { "<cmd>GpWhisperVnew<cr>", "Whisper Vnew" },
          t = { "<cmd>GpWhisperTabnew<cr>", "Whisper Tabnew" },
        },
      },
      -- ...
    }, {
      mode = "i", -- INSERT mode
      prefix = "",
      buffer = nil,
      silent = true,
      noremap = true,
      nowait = true,
    })
  end,
}
