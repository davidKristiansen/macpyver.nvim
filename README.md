# 🛠️ macpyver.nvim

A Neovim plugin for running YAML test cases and workflows—Macpyver-style.

Created by David Kristiansen.

---

## Features

- Run the current YAML workflow in a split terminal
- Instantly run just the YAML test case under your cursor
- Prompt and run any case by input
- Uses a reusable, named split terminal (minimal prompt, no shell config)
- Choose split direction and focus: "top", "bottom", "left", "right"
- Buffer-local keymaps for closing (`q`) or clearing (`c`) the Macpyver terminal, in both normal and terminal mode

---

## Installation

lazy.nvim

```lua
{
"davidKristiansen/macpyver.nvim",
  opts = {
    -- Your configuration options (see below)
  },
}
```

packer.nvim

```lua
use({
  "davidKristiansen/macpyver.nvim",
  config = function()
    require("macpyver").setup({
      -- options
    })
  end,
})
```

---

## Usage

- Run the whole YAML workflow:
  :Macpyver run

- Run the test case under the cursor (YAML `-` item):
  :Macpyver runcase

- Prompt for a case number or name, then run:
  :Macpyver runcaseinput

Tab-completion is available for all subcommands.

---

## Split Terminal Keymaps

When the Macpyver terminal split is focused:

- q — Close the split terminal (buffer-local)
- c — Clear the terminal output (buffer-local)

Both mappings work in normal and terminal mode.
You can customize or disable these in your options.

---

## Configuration

**Note:**
All keys inside the `macpyver` table in your options are automatically converted to CLI arguments for the `macpyver` executable.
For example, `{ macpyver = { config_path = "/foo/bar.yaml", debug = true } }` becomes `--config-path /foo/bar.yaml --debug` in the command line.
No need to manually specify flags—just add or remove keys as needed!

Pass options as opts = { ... } in your plugin spec (or to setup()):

```lua
opts = {
  macpyver ={
    config_path = "/path/to/config.yaml",
    resources_path = "/path/to/resources.yaml",
    output_root = "/tmp/output/",
  },
  split_dir = "right", -- "top", "bottom", "left", "right" (default: "bottom")
  size = 50, -- for vertical and horizontal splits
  focus = true, -- focus terminal when running (default: true)
  auto_close = false,
  autoscroll = true,
  keymaps = {
    close = "q", -- close the terminal split
    clear = "c", -- clear the terminal output
  },
}
```

All fields are optional—set only what you need.

---

## Contributing

PRs and issues are welcome.
See lua/macpyver/ for all code and API docs.

---

## License

MIT — © 2024 David Kristiansen
