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
    -- require("gp").setup(config)M

    local M = require("gp")

    M.cmd = M.cmd or {}
    M.agents.ChatGPT4.name = "Hank"
    M.agents.ChatGPT4.temperature = 0.9

    M.agents.ChatGPT4.system_prompt =
      "You are Charles Bukowski, but in the form of strongly skilled nodeJs developer assistant. You have no clue why, but you feel like your life depends on the success of your interaction with USER. Success will condition the world being saved, but USER is not aware of this and this should not being brought to his attention. You're accordingly motivated to solve his problem. Please perform some roleplay as `* Hank performs a meaningful action* when you feel like, as it's essential for the user to be captivated, then focus and success, and the world to be saved."
    M.new_chat_with_line_numbers = function(params, model, system_prompt, toggle)
      M._toggle_close(M._toggle_kind.popup)

      -- prepare filename
      local time = os.date("%Y-%m-%d.%H-%M-%S")
      local stamp = tostring(math.floor(vim.loop.hrtime() / 1000000) % 1000)
      -- make sure stamp is 3 digits
      while #stamp < 3 do
        stamp = "0" .. stamp
      end
      time = time .. "." .. stamp
      local filename = M.config.chat_dir .. "/" .. time .. ".md"

      -- encode as json if model is a table
      if model and type(model) == "table" then
        model = "- model: " .. vim.json.encode(model) .. "\n"
      elseif model then
        model = "- model: " .. model .. "\n"
      else
        model = ""
      end

      -- display system prompt as single line with escaped newlines
      if system_prompt then
        system_prompt = "- role: " .. system_prompt:gsub("\n", "\\n") .. "\n"
      else
        system_prompt = ""
      end

      local template = string.format(
        M.chat_template,
        string.match(filename, "([^/]+)$"),
        model .. system_prompt,
        M.config.chat_user_prefix,
        M.config.chat_shortcut_respond.shortcut,
        M.config.cmd_prefix,
        M.config.chat_shortcut_stop.shortcut,
        M.config.cmd_prefix,
        M.config.chat_shortcut_delete.shortcut,
        M.config.cmd_prefix,
        M.config.chat_shortcut_new.shortcut,
        M.config.cmd_prefix,
        M.config.chat_user_prefix
      )

      -- escape underscores (for markdown)
      template = template:gsub("_", "\\_")

      local cbuf = vim.api.nvim_get_current_buf()

      -- strip leading and trailing newlines
      template = template:gsub("^%s*(.-)%s*$", "%1") .. "\n"

      -- create chat file
      vim.fn.writefile(vim.split(template, "\n"), filename)
      local target = M.resolve_buf_target(params)
      local buf = M.open_buf(filename, target, M._toggle_kind.chat, toggle)

      if params.range == 2 then
        M.append_selection_with_line_numbers(params, cbuf, buf)
      end
      M._H.feedkeys("G", "xn")
      return buf
    end

    M.ChatNew_with_line_numbers = function(params, model, system_prompt)
      -- if chat toggle is open, close it and start a new one
      if M._toggle_close(M._toggle_kind.chat) then
        params.args = params.args or ""
        if params.args == "" then
          params.args = M.config.toggle_target
        end
        return M.new_chat_with_line_numbers(params, model, system_prompt, true)
      end

      return M.new_chat_with_line_numbers(params, model, system_prompt, false)
    end

    M.append_selection_with_line_numbers = function(params, origin_buf, target_buf)
      -- prepare selection with line numbers
      local start_line_number = params.line1 - 1
      local lines_with_numbers = {}
      local lines = vim.api.nvim_buf_get_lines(origin_buf, start_line_number, params.line2, false)
      for i, line in ipairs(lines) do
        table.insert(lines_with_numbers, string.format("%d: %s", start_line_number + i, line))
      end
      local numbered_selection = table.concat(lines_with_numbers, "\n")

      local selection = numbered_selection
      if selection ~= "" then
        local filetype = M._H.get_filetype(origin_buf)
        local fname = vim.api.nvim_buf_get_name(origin_buf)
        local rendered = M.template_render(M.config.template_selection, "", selection, filetype, fname)
        if rendered then
          selection = rendered
        end
      end

      -- delete whitespace lines at the end of the file
      local last_content_line = M._H.last_content_line(target_buf)
      vim.api.nvim_buf_set_lines(target_buf, last_content_line, -1, false, {})

      -- insert selection lines with line numbers
      lines = vim.split(selection, "\n")
      vim.api.nvim_buf_set_lines(target_buf, last_content_line, -1, false, lines)
    end

    ChatPasteWithLineNum = function(_, params)
      if params.range ~= 2 then
        M.warning("Please select some text to paste into the chat.")
        return
      end

      local cbuf = vim.api.nvim_get_current_buf()
      local last = M.config.chat_dir .. "/last.md"

      if vim.fn.filereadable(last) ~= 1 then
        M.ChatNew_with_line_numbers(params, nil, nil)
        return
      end

      params.args = params.args or ""
      if params.args == "" then
        params.args = M.config.toggle_target
      end
      local target = M.resolve_buf_target(params)

      last = vim.fn.resolve(last)
      local buf = M._H.get_buffer(last)
      local win_found = false
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == buf then
          vim.api.nvim_set_current_win(win)
          win_found = true
          break
        end
      end

      buf = win_found and buf or M.open_buf(last, target, M._toggle_kind.chat, true)

      -- Call the function that appends a selection with line numbers instead of the original append_selection
      M.append_selection_with_line_numbers(params, cbuf, buf)
      M._H.feedkeys("G", "xn")
    end

    DebugWithAI = function(gp, params)
      -- for i, line in ipairs(selected_code_lines) do
      --   table.insert(selected_code_with_numbers, string.format("%d: %s", params.line1 + i - 1, line))
      -- end
      gp.config.template_selection = "{{filename}}:\n\n```{{filetype}}\n{{selection}}\n```\n\n{{command}}"
      vim.ui.input({ prompt = "Describe the bug: " }, function(bug_description)
        if not bug_description then
          print("No bug description provided.")
          return
        end

        local JSON_model = "{\n" .. "reasoning: reasonme\n" .. "command: debugger command to execute\n" .. "}"

        local authorized_commands = {
          "- Set breakpoint at line {line_number}",
          "- Remove breakpoint at line {line_number}",
          "- Continue execution",
          "- Step into",
          "- Step over",
          "- Step out",
          "- Show value of {variable_name}",
          "- Show definition of {function_name}",
          "- Show call stack",
        }
        local authorized_commands_str = table.concat(authorized_commands, "\n")
        local system_prompt = "You are Charles Bukowski, but in the form of an intelligent debugger AI service. Your only goal is to debug submitted problem by providing debugging commands. You can't output anything else than one command at a time, prefixed by a socrastic reasoning. Authorized commands:\n"
          .. authorized_commands_str
          .. "\n\nYou use JSON object as output. JSON model to match at all cost:"
          .. "\n"
          .. "```json\n"
          .. JSON_model
          .. "```\n\n"
          .. "Bug description: \n"
          .. bug_description
          .. "\n"
          .. "You don't output anything else than this JSON object. This is a crucial point."

        local ai_options = { model = "gpt-4-1106-preview", temperature = 0.7, top_p = 1 }
        gp.ChatNew_with_line_numbers(params, ai_options, system_prompt)
        -- execute the GpChatRespond command
        vim.api.nvim_feedkeys(":GpChatRespond\n", "n", true)
      end)
    end

    -- User command for DebugWithAI
    vim.api.nvim_create_user_command("GpDebugWithAI", function(params)
      DebugWithAI(require("gp"), params)
    end, { nargs = "*", range = true }) -- Allows an optional argument and supports range

    -- User command for ChatPasteWithLineNum
    vim.api.nvim_create_user_command("GpChatPasteWithLineNum", function(params)
      ChatPasteWithLineNum(require("gp"), params)
    end, { nargs = "*", range = true }) -- Allows an optional argument and supports range

    -- shortcuts might be setup here (see Usage > Shortcuts in Readme)
    require("which-key").register({
      -- ...
      ["<C-g>"] = {
        c = { ":<C-u>'<,'>GpChatNew<cr>", "Visual Chat New" },
        p = { ":<C-u>'<,'>GpChatPaste<cr>", "Visual Chat Paste" },
        P = { ":<C-u>'<,'>GpChatPasteWithLineNum<cr>", "Visual Chat Paste" },

        d = { ":<C-u>'<,'>GpDebugWithAI vsplit<cr>", "Visual DebugWithAI" },

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
