-- Async IO module
--
local co = coroutine
local unpack = table.unpack or unpack

--- Executes an async function with callback handling
-- @function pong
-- @param func The async function to execute
-- @param callback Optional callback function to call when complete
-- @local
local pong = function (func, callback)
  assert(type(func) == "function", "type error :: expected func")
  local thread = co.create(func)
  local step = nil
  step = function (...)
    local pack = {co.resume(thread, ...)}
    local status = pack[1]
    local ret = pack[2]
    assert(status, ret)
    if co.status(thread) == "dead" then
        if (callback) then
            (function (_, ...) callback(...) end)(unpack(pack))
        end
    else
      assert(type(ret) == "function", "type error :: expected func - coroutine yielded some value")
      ret(step)
    end
  end
  step()
end

--- Creates a thunk factory from an async function
-- @function wrap
-- @param func The async function to wrap
-- @return A factory function that creates thunks
local wrap = function (func)
  assert(type(func) == "function", "type error :: expected func")
  local factory = function (...)
    local params = {...}
    local thunk = function (step)
      table.insert(params, step)
      return func(unpack(params))
    end
    return thunk
  end
  return factory
end

--- Combines multiple thunks into a single thunk
-- @function join
-- @param thunks Table of thunk functions
-- @return A single thunk that executes all input thunks
local join = function (thunks)
  local len = table.getn(thunks)
  local done = 0
  local acc = {}

  local thunk = function (step)
    if len == 0 then
      return step()
    end
    for i, tk in ipairs(thunks) do
      assert(type(tk) == "function", "thunk must be function")
      local callback = function (...)
        acc[i] = {...}
        done = done + 1
        if done == len then
          step(unpack(acc))
        end
      end
      tk(callback)
    end
  end
  return thunk
end

--- Awaits execution of a single async operation
-- @function await
-- @param defer Thunk function to await
-- @return The result of the async operation
local await = function (defer)
  assert(type(defer) == "function", "type error :: expected func")
  return co.yield(defer)
end

--- Awaits execution of multiple async operations
-- @function await_all
local await_all = function (defer)
  assert(type(defer) == "table", "type error :: expected table")
  return co.yield(join(defer))
end

--- Creates a promise-like async operation
-- @function promise
-- @param executor Function that takes resolve and reject callbacks
-- @return A thunk that can be awaited
local promise = function (executor)
  return function (step)
    local function resolve(...)
      step(...)
    end

    local function reject(...)
      step(...)
    end

    executor(resolve, reject)
  end
end

-- Example usage:
--[[
-- Example 1: Basic async function with await
local function async_fetch_data(url)
  return function(callback)
    -- Simulate async operation (e.g., HTTP request)
    vim.defer_fn(function()
      callback("Data from " .. url)
    end, 100)
  end
end

local function example1()
  local aio = require("customization.utils.aio")

  local fetch = aio.wrap(async_fetch_data)
  local fetch_thunk = fetch("https://api.example.com/data")

  aio.sync(function()
    local result = aio.wait(fetch_thunk)
    print("Received:", result)
  end)
end

-- Example 2: Multiple async operations with wait_all
local function async_process_item(item, delay)
  return function(callback)
    vim.defer_fn(function()
      callback("Processed: " .. item)
    end, delay)
  end
end

local function example2()
  local aio = require("customization.utils.aio")

  local process = aio.wrap(async_process_item)

  aio.sync(function()
    local thunks = {
      process("item1", 100),
      process("item2", 200),
      process("item3", 150)
    }

    local results = aio.wait_all(thunks)
    print("All items processed:")
    for i, result in ipairs(results) do
      print(i, unpack(result))
    end
  end)
end

-- Example 3: Chaining async operations
local function example3()
  local aio = require("customization.utils.aio")

  local fetch_user = aio.wrap(function(user_id, callback)
    vim.defer_fn(function()
      callback({id = user_id, name = "User" .. user_id})
    end, 100)
  end)

  local fetch_posts = aio.wrap(function(user, callback)
    vim.defer_fn(function()
      callback({"Post1", "Post2", "Post3"})
    end, 150)
  end)

  aio.sync(function()
    local user = aio.wait(fetch_user(123))
    print("User fetched:", user.name)

    local posts = aio.wait(fetch_posts(user))
    print("User posts:", table.concat(posts, ", "))
  end)
end

-- Example 4: Error handling
local function example4()
  local aio = require("customization.utils.aio")

  local risky_operation = aio.wrap(function(callback)
    vim.defer_fn(function()
      -- Simulate an error
      callback(nil, "Something went wrong")
    end, 100)
  end)

  aio.sync(function()
    local success, error_msg = aio.wait(risky_operation())
    if error_msg then
      print("Error:", error_msg)
    else
      print("Success:", success)
    end
  end)
end

-- Example 5: Using promise method
local function example5()
  local aio = require("customization.utils.aio")

  aio.sync(function()
    local result = aio.wait(aio.promise(function(resolve, reject)
      vim.defer_fn(function()
        resolve("Promise resolved successfully")
      end, 100)
    end))
    print("Promise result:", result)
  end)
end

-- Example 6: Promise with error handling
local function example6()
  local aio = require("customization.utils.aio")

  aio.sync(function()
    local success, error = aio.wait(aio.promise(function(resolve, reject)
      vim.defer_fn(function()
        reject("Something went wrong")
      end, 100)
    end))
    if error then
      print("Promise rejected:", error)
    else
      print("Promise resolved:", success)
    end
  end)
end

-- To run examples:
-- example1()
-- example2()
-- example3()
-- example4()
-- example5()
-- example6()
]]

return {
  sync = wrap(pong),
  wait = await,
  wait_all = await_all,
  wrap = wrap,
  promise = promise,
}
