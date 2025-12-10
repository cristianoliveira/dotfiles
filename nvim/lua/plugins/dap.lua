return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "leoluz/nvim-dap-go",
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      -- "theHamsta/nvim-dap-virtual-text",
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
      local dap   = require("dap")
      local dapui = require("dapui")
      -- 1) dap-ui
      dapui.setup()

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
          -- Must be "go" or it will be ignored by the plugin
          type = "go",
          name = "Attach local pid",
          mode = "local",
          request = "attach",
          processId = pickProcessId,
        }
      }

      vim.keymap.set("n", "<F1>", dap.continue)
      vim.keymap.set("n", "<F2>", dap.step_into)
      vim.keymap.set("n", "<F3>", dap.step_over)
      vim.keymap.set("n", "<F4>", dap.step_out)
      vim.keymap.set("n", "<F5>", dap.step_back)
      vim.keymap.set("n", "<F13>", dap.restart)

      vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint)
      -- Eval to cursor
      vim.keymap.set("n", "<leader>eb", dap.run_to_cursor)

      -- Eval var under cursor
      vim.keymap.set("n", "<leader>ev", function()
        require("dapui").eval(nil, { enter = true })
      end)
    end,
  },
}
