--!strict

local Check = {}

export type Mode = 'positive' | 'negative'
export type Describe = (name: string) -> (WithIt) -> () -> ()
export type WithIt = (it: It) -> ()
export type It = (name: string, mode: Mode?) -> (WithCheck) -> ()
export type WithCheck = (check: Check) -> ()
export type Check = typeof(Check)

local BACKTRACE_EXCLUSIONS = setmetatable({
  '^./lib/describe:(%d+)$',
  '^__mlua_require:(%d+)$',
  '^lorry_core/src/(.+).rs:(%d+):(%d+)$',
}, array_mt);

export type Some = number | string | boolean | thread | vector | buffer | {}

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

function Check.eq<T>(a: T, b: T, message: string?)
  assert(a == b, message)
end

function Check.neq(a: any, b: any, message: string?): boolean
  return assert(a ~= b, message)
end

function Check.assert<T>(v: T, message: string?): T
  return assert(v, message)
end

function Check.required<T>(v: T?, message: string?): T
  assert(v ~= nil, message)
  return v::any
end

type ErrorDetails = {
  error: any,
  traceback: {string},
}

local function describe(name: string)
  local function it(name: string, mode: Mode?)
    mode = mode or 'positive'
    return function (test: WithCheck)
      local status, error_details: ErrorDetails? = xpcall(test, append_traceback, Check);
      local success = mode == 'positive' and status or mode == 'negative' and not status
      if success then
        print("  ✓ " .. name)
      elseif (error_details ~= nil) then
        print("  ⨯ " .. name)
        print("    ↳ " .. tostring(error_details.error))
        print("      Traceback:")
        for i, row in error_details.traceback do
          print("        " .. row)
        end
      else
        print("  ⨯ " .. name)
      end
    end
  end

  return function (strategy: WithIt)
    return function()
      print(name)
      strategy(it)
    end
  end
end

return describe