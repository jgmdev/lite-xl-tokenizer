local core = require "core"
local config = require "core.config"
local common = require "core.common"
local syntax = require "core.syntax"
local tokenizer = require "core.tokenizer"
local Highlighter = require "core.doc.highlighter"
local Tokenizer = require "libraries.tokenizer"

---@class config.plugins.ctokenizer
---@field enabled boolean
---@field log_time boolean
config.plugins.ctokenizer = common.merge({
  enabled = true,
  log_time = false,
  -- The config specification used by gui generators
  config_spec = {
    name = "C-Tokenizer",
    {
      label = "Enabled",
      description = "Enable or disable the c-tokenizer.",
      path = "enabled",
      type = "toggle",
      default = true
    },
    {
      label = "Log Tokenization Time",
      description = "Enable or disable measuring the time it takes to tokenize a group of lines.",
      path = "log_time",
      type = "toggle",
      default = false
    }
  }
}, config.plugins.ctokenizer)

local tokenizer = {
  syntaxes = {}
}

local total_time_tokenizing = 0.0

function tokenizer.get(syntax_input)
  local syntax_object = type(syntax_input) == "table" and syntax_input or syntax.get(syntax_input)
  if not syntax_object then return end
  local native = tokenizer.syntaxes[syntax_object]
  if not native then
    native = Tokenizer.new(syntax_object, tokenizer.get)
    tokenizer.syntaxes[syntax_object] = native
    syntax_object.tokenizer = native
  end
  return native
end

local total_lines = 0
local tokenizer_tokenize = tokenizer.tokenize
function tokenizer.tokenize(syntax, text, state, quick)
  if not config.plugins.ctokenizer.enabled then
    return tokenizer_tokenize(syntax, text, state)
  end
  local start_time = system.get_time()
  total_lines = total_lines + 1
  local native = syntax.tokenizer or tokenizer.get(syntax)
  local res, state = native:tokenize(text, state or 0, quick)
  if res then
    local start = 1
    for i = 2, #res, 2 do
      local len = res[i]
      res[i] = text:sub(start, len + start - 1)
      start = len + start
    end
  end
  total_time_tokenizing = total_time_tokenizing + (system.get_time() - start_time)
  return res, state
end

--------------------------------------------------------------------------------
-- Override some highlighter methods to add the `quick` param
--------------------------------------------------------------------------------
local highlighter_start = Highlighter.start
function Highlighter:start()
  if self.running then return end
  self.running = true
  core.add_thread(function()
    local start_time = system.get_time()
    local first_invalid = self.first_invalid_line
    while self.first_invalid_line < self.max_wanted_line do
      local max = math.min(self.first_invalid_line + 40, self.max_wanted_line)
      local retokenized_from
      for i = self.first_invalid_line, max do
        local state = (i > 1) and self.lines[i - 1].state
        local line = self.lines[i]
        if not (line and line.init_state == state and line.text == self.doc.lines[i]) then
          retokenized_from = retokenized_from or i
          self.lines[i] = self:tokenize_line(i, state, true)
        elseif retokenized_from then
          self:update_notify(retokenized_from, i - retokenized_from - 1)
          retokenized_from = nil
        end
      end
      if retokenized_from then
        self:update_notify(retokenized_from, max - retokenized_from)
      end

      self.first_invalid_line = max + 1
      core.redraw = true
      coroutine.yield()
    end
    if config.plugins.ctokenizer.log_time then
      core.log(
        "Tokenization of %s lines took %ss from %s to %s",
        self.max_wanted_line - first_invalid,
        system.get_time() - start_time,
        first_invalid, self.max_wanted_line
      )
    end
    self.max_wanted_line = 0
    self.running = false
  end, self)
end

local highlighter_tokenize_line = Highlighter.tokenize_line
function Highlighter:tokenize_line(idx, state, quick)
  if not config.plugins.ctokenizer.enabled then
    return highlighter_tokenize_line(self, idx, state)
  end
  local res = {}
  res.init_state = state
  res.text = self.doc.lines[idx]
  res.tokens, res.state = tokenizer.tokenize(self.doc.syntax, res.text, state, quick)
  return res
end

local function set_max_wanted_lines(self, amount)
  self.max_wanted_line = amount
  if self.first_invalid_line < self.max_wanted_line then
    self:start()
  end
end

-- overriden to add the `or not line.tokens` check
function Highlighter:get_line(idx)
  local line = self.lines[idx]
  if not line or line.text ~= self.doc.lines[idx] or not line.tokens then
    local prev = self.lines[idx - 1]
    line = self:tokenize_line(idx, prev and prev.state)
    self.lines[idx] = line
    self:update_notify(idx, 0)
  end
  set_max_wanted_lines(self, math.max(self.max_wanted_line, idx))
  return line
end
