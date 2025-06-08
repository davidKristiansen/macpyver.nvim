# 🛠️ macpyver.nvim

A Neovim plugin for YAML case running and workflow execution—Macpyver-style, right inside your editor.

Created by David Kristiansen.

---

## Features

- Run the entire YAML workflow from your current buffer, in a split terminal
- Instantly run the specific YAML case (list item) under your cursor
- Reuses or opens a split terminal as needed, respecting your split/focus preferences
- Choose vertical or horizontal splits (follows your \:set splitright / \:set splitbelow)
- Control focus behavior when running jobs
- Keymaps for closing or interrupting jobs in the Macpyver terminal

---

## Installation

Use your favorite plugin manager:

lazy.nvim

```
{
  "davidKristiansen/macpyver.nvim",
  config = function()
    require("macpyver").setup({
      -- your options here (see below)
    })
  end,
}
```

packer.nvim

```
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

Run the whole workflow in a split terminal:

```
:MacpyverRun
```

Run the test case under the cursor (YAML `-` list item):

```
:MacpyverCase
```

Default keymaps in the Macpyver split:

- q: Close the split (or quit Neovim if last window)
- c: Send Ctrl-C to the running job

---

## Configuration

Call `setup()` in your config with any of these options:

```
require("macpyver").setup({
  config_path    = "/path/to/config.yaml",
  resources_path = "/path/to/resources.yaml",
  output_root    = "/tmp/output/",
  split_type     = "vertical",   -- or "horizontal" (follows your splitright/splitbelow)
  min_width      = 50,           -- minimum width for vertical splits
  min_height     = 12,           -- minimum height for horizontal splits
  focus_on_run   = true,         -- whether to move focus to the Macpyver split (default: true)
  auto_close     = false,
  autoscroll     = true,
  keymaps        = {
    close = "q",
    ctrlc = "c",
  },
})
```

- split_type: "vertical" or "horizontal". Lets your own splitright and splitbelow decide which side.
- min_width: Minimum width of split for "vertical".
- min_height: Minimum height of split for "horizontal".
- focus_on_run: If false, your cursor stays in your working buffer when running Macpyver.

All fields are optional, but you'll want to set the paths.

---

## Why Macpyver?

Because sometimes YAML needs a paperclip and a split terminal.

---

## Contributing

PRs, issues, and workflow hacks welcome.

See `lua/macpyver/` for the full code.

---

## License

MIT — © 2024 David Kristiansen

---

Made for Neovim, because your terminal deserves more.
