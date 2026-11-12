local Config = require("lazy.core.config")
local Git = require("lazy.manage.task.git")
local Fs = require("lazy.manage.task.fs")

describe("git.clone", function()
  local orig_depth
  local orig_clean
  local captured

  before_each(function()
    orig_depth = Config.options.git.depth
    orig_clean = Fs.clean.run
    Fs.clean.run = function() end
    captured = {}
  end)

  after_each(function()
    Config.options.git.depth = orig_depth
    Fs.clean.run = orig_clean
  end)

  local function run_clone(plugin)
    vim.fn.mkdir(plugin.dir, "p")
    local task = {
      plugin = plugin,
      spawn = function(self, cmd, opts)
        captured = vim.deepcopy(opts.args or {})
        if opts.on_exit then
          opts.on_exit(true)
        end
      end,
    }
    Git.clone.run(task)
    return captured
  end

  local base = {
    name = "test",
    url = "https://github.com/test/test.git",
    dir = Config.options.root .. "/lazy-git-clone-test",
    _ = {},
  }

  it("uses shallow clone --depth=1 --no-tags by default", function()
    Config.options.git.depth = 1
    local args = run_clone(vim.deepcopy(base))
    assert(vim.tbl_contains(args, "--depth=1"))
    assert(vim.tbl_contains(args, "--no-tags"))
  end)

  it("uses configured depth", function()
    Config.options.git.depth = 3
    local args = run_clone(vim.deepcopy(base))
    assert(vim.tbl_contains(args, "--depth=3"))
  end)

  it("disables shallow clone when depth is false", function()
    Config.options.git.depth = false
    local args = run_clone(vim.deepcopy(base))
    assert(not vim.tbl_contains(args, function(a) return a:find("^--depth=") end))
    assert(not vim.tbl_contains(args, "--no-tags"))
  end)

  it("omits depth for pinned plugins (commit)", function()
    Config.options.git.depth = 1
    local args = run_clone(vim.deepcopy(vim.tbl_extend("force", base, { commit = "abc123" })))
    assert(not vim.tbl_contains(args, function(a) return a:find("^--depth=") end))
  end)

  it("omits depth for pinned plugins (tag)", function()
    Config.options.git.depth = 1
    local args = run_clone(vim.deepcopy(vim.tbl_extend("force", base, { tag = "v1.0" })))
    assert(not vim.tbl_contains(args, function(a) return a:find("^--depth=") end))
  end)

  it("omits depth for pinned plugins (version)", function()
    Config.options.git.depth = 1
    local args = run_clone(vim.deepcopy(vim.tbl_extend("force", base, { version = "*" })))
    assert(not vim.tbl_contains(args, function(a) return a:find("^--depth=") end))
  end)

  it("omits depth for pinned plugins (pin)", function()
    Config.options.git.depth = 1
    local args = run_clone(vim.deepcopy(vim.tbl_extend("force", base, { pin = true })))
    assert(not vim.tbl_contains(args, function(a) return a:find("^--depth=") end))
  end)
end)
