export type Mode = 'positive' | 'negative'
export type Describe = (name: string) -> (WithIt) -> ()
export type WithIt = (it: It) -> ()
export type It = (name: string, mode: Mode?) -> (WithCheck) -> ()
export type WithCheck = (check: Check) -> ()
export type Check = {
  eq: (a: any, b: any, message: string?) -> boolean,
  neq: (a: any, b: any, message: string?) -> boolean,
  defined: (a: any, message: string?) -> boolean,
  absent: (a: any, message: string?) -> boolean,
}

local BACKTRACE_EXCLUSIONS = setmetatable({
  '^./lib/describe:(%d+)$',
  '^__mlua_require:(%d+)$',
  '^lorry_core/src/(.+).rs:(%d+):(%d+)$',
}, array_mt);

local append_traceback = function(error: {})
  local traceback = debug.traceback();
  local rows_iter = traceback:gmatch("[^\r\n]+")
  local significant_rows = setmetatable({}, array_mt)
  for row in rows_iter do
    local exclude = false
    for _, exclusion in BACKTRACE_EXCLUSIONS do
      if row:match(exclusion) then
        exclude = true
        continue
      end
    end
    if not exclude then
      significant_rows[#significant_rows + 1] = row
    end
  end
  return {
    error = error,
    traceback = significant_rows,
  };
end

local check: Check = {
  eq = function(a: any, b: any, message: string?): boolean return assert(a == b, message) end,
  neq = function(a: any, b: any, message: string?): boolean return assert(a ~= b, message) end,
  defined = function(v: any, message: string?): boolean return assert(v ~= nil, message) end,
  absent = function(v: any, message: string?): boolean return assert(v == nil, message) end,
  assert = function(v: boolean, message: string?): boolean return assert(v, message) end,
}


local function describe(name: string)
  print(name)
  local function it(name: string, mode: Mode?)
    mode = mode or 'positive'
    return function (test: WithCheck)
      local status, error_details = xpcall(test, append_traceback, check);
      local success = mode == 'positive' and status or mode == 'negative' and not status
      if success then
        print("  ✓ " .. name)
      else
        print("  ⨯ " .. name)
        print("    ↳ " .. error_details.error)
        print("      Traceback:")
        for i, row in error_details.traceback do
          print("        " .. row)
        end
      end
    end
  end

  return function (strategy: WithIt)
    strategy(it)
  end
end

return describe