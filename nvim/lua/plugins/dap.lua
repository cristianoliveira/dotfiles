return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "leoluz/nvim-dap-go",
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
      -- "williamboman/mason.nvim",
    },
    config = function()
      -- IMPORTANT: FOR MAC USERS
      -- If you are having issues with debugging Go code (or others I don't know)
      -- and you are in a arm64 M1/2/x mac, make sure you run dlv with:
      -- `arch -arm64 dlv` instead! It took me way too long to figure it out
      -- I hope it works for you, good luck :)
      --
      -- Make sure to follow these instructions for the certification stuff:
      -- https://github.com/go-delve/delve/tree/cfb04c4f816dee57b38d3b3959319fd7c36ed560/Documentation/installation#compiling-macos-native-backend
      -- https://archive.is/bYqhx
      --
      -- For nix users, I wrap dlv for darwin see: nix/shared/dev-tools/go.nix
      local dlv_bin = vim.fn.exepath("dlv")
      local dap = require("dap")
      local dapui = require("dapui")
      local dap_vt_text = require("nvim-dap-virtual-text")

      -- 1) dap-ui
      dapui.setup()

      dap_vt_text.setup({
        enabled = false, -- Enable with <leader>dt
      })

      -- auto open/close UI
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      -- 2) nvim-dap-go: sets up Delve adapter & basic configs
      require("dap-go").setup()

      -- 3) Extra Go configs for attach

      -- make sure we don't nuke configs defined by dap-go
      dap.configurations.go = dap.configurations.go or {}
      dap.set_log_level('DEBUG')

      local pickProcessId = function()
        -- Print dlv path for debugging
        local filter = vim.fn.input("filter: ")
        return require("dap.utils").pick_process({
          prompt = "Select process to attach to",
          filter = filter
        })
      end

      dap.adapters.go = {
        type = "server",
        host = "127.0.0.1",
        port = "${port}",
        executable = {
          command = dlv_bin,
          args = { "dap", "-l", "127.0.0.1:".."${port}" },
        },
        options = {
          detached = false,
          initialize_timeout_sec = 20,
          disconnect_timeout_sec = 20,
        },
      }

      dap.configurations.go = {
        {
          type = "go",
          name = "Launch (with go run <file>)",
          request = "launch",
          program = function()
              return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          args = require("dap-go").get_arguments,
        },
        {
          type = "go",
          name = "Debug current file + args (with go run <file>)",
          request = "launch",
          program = "${file}",
          args = require("dap-go").get_arguments,
          buildFlags = require("dap-go").get_build_flags,
        },
        {
          type = "go",
          name = "Debug test (with go test -v <file>)",
          request = "launch",
          mode = "test",
          program = "${file}",
        },
        {
          -- Must be "go" or it will be ignored by the plugin
          type = "go",
          name = "Attach local pid",
          mode = "local",
          request = "attach",
          processId = pickProcessId,
        }
      }

      vim.keymap.set('n', '<F5>', dap.continue)
      vim.keymap.set('n', '<F8>', dap.continue)
      vim.keymap.set('n', '<F9>', dap.step_into)
      vim.keymap.set('n', '<F10>', dap.step_over)
      vim.keymap.set('n', '<F11>', dap.step_out)
      vim.keymap.set("n", "<F12>", dap.step_back)
      vim.keymap.set("n", "<F1>", dap.restart)

      vim.keymap.set('n', '<leader>dc', dap.continue, {
        desc = "Continue"
      })
      vim.keymap.set('n', '<leader>di', dap.step_into, {
        desc = "Step into"
      })
      vim.keymap.set('n', '<leader>do', dap.step_over, {
        desc = "Step over"
      })
      vim.keymap.set('n', '<leader>du', dap.step_out, {
        desc = "Step out"
      })
      vim.keymap.set('n', '<leader>db', dap.step_back, {
        desc = "Step back"
      })
      vim.keymap.set('n', '<leader>dr', dap.restart, {
        desc = "Restart"
      })

      vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint)
      -- Toggle virtual text
      vim.keymap.set("n", "<leader>dt", dap_vt_text.toggle, {
        desc = "Toggle virtual text"
      })
      -- Dap ui
      -- Eval to cursor
      vim.keymap.set("n", "<leader>dv", dapui.eval, {
        desc = "Describe variable under cursor"
      })
      vim.keymap.set("n", "<leader>df", dapui.float_element, {
        desc = "Float variable under cursor"
      })

      -- Eval var under cursor
      vim.keymap.set("n", "<leader>K", function()
        require("dapui").eval(nil, { enter = true })
      end)
    end,
  },
}

