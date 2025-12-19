---

Lua Sandbox for User Scripts

A lightweight Lua sandbox environment for safely running user scripts with hooks, logging, and controlled execution.

This repository provides a secure way to run user-provided Lua scripts without risking the host environment.


---

Table of Contents

1. Overview


2. Features


3. API Reference

Logging

Task Control

Hook System

File Writing



4. Default Script Template


5. Example Usage


6. Notes & Best Practices




---

Overview

createSandbox(scriptName, task) creates a secure Lua environment for user scripts.
It restricts access to unsafe globals, provides safe sleep and yield operations, logging, hooks, and file writing in a controlled manner.

User scripts are executed in this sandbox environment, which ensures:

No access to sensitive host globals (BLOCKED_KEYS)

Hooks are automatically namespaced to prevent collisions

Scripts can be safely stopped without freezing the host



---

Features

Safe standard Lua functions: print, pairs, ipairs, tonumber, tostring, type

Safe standard libraries: math, string, table

Logging via log() with automatic script prefix

Task control: sleep(ms), yield(), stop(), isRunning()

Hook system: AddHook(hookType, hookID, callback)

Safe file writing: write(path, text)



---

API Reference

Logging

log("Hello from my script")

Adds a log entry with [ScriptName] prefix.


---

Task Control

sleep(ms) – Pauses script safely without freezing the host. Can be interrupted via stop().


sleep(100) -- wait 100ms

yield() – Checks whether the task should stop.


yield()

stop() – Stops script immediately.


stop() -- triggers "STOP_REQUESTED"

isRunning() – Returns true if the script is still running.


if not isRunning() then return end


---

Hook System

AddHook(hookType, hookID, callback) – Adds a hook. Hook IDs are automatically prefixed with the script name.


AddHook("OnDraw", "MyUI", function()
    if not isRunning() then return end
    DrawMenu()
end)

__removeAllHooks() – Removes all hooks added by this script.


__removeAllHooks()


---

File Writing

write("C:/temp/output.txt", "Hello world")

Writes to a file safely via safeWriteFile.


---

Default Script Template

This template is loaded for new users or when no custom script exists.

const defaultScript = `-- === Contoh Script Sandbox Lua ===

function main()
    -- Logging
    log("Script Loaded!")

    -- Example Hook
    AddHook("OnDraw", "PacketDebuggerUI", function()
        if not isRunning() then return end
        DrawMenu() -- example UI function
    end)

    -- Main loop with safe sleep
    while isRunning() do
        sleep(100) -- wait 100ms without freezing
    end
end

-- Klik tombol EDIT untuk mengubah kode ini.
`;


---

Example Usage

-- Define a task object
local task = { shouldStop = false }

-- Create a sandbox environment
local env = createSandbox("ExampleScript", task)

-- User-provided code
local userCode = [[
function main()
    log("Hello User!")
    
    AddHook("OnDraw", "PacketDebuggerUI", function()
        if not isRunning() then return end
        DrawMenu()
    end)
    
    while isRunning() do
        sleep(100)
    end
end
]]

-- Compile user code in sandbox
local func, err = load(userCode, "user_script", "t", env)
if func then
    local ok, runErr = pcall(func)
    if not ok then
        log("Error running script: " .. tostring(runErr))
    end
else
    log("Compile error: " .. tostring(err))
end


---

Notes & Best Practices

Hooks are prefixed with scriptName::hookID automatically to prevent collisions.

sleep() breaks waiting into 50ms steps to allow safe stopping.

Always use __removeAllHooks() when stopping scripts to clean up hooks.

Avoid accessing blocked globals defined in BLOCKED_KEYS.

Use log() instead of print() for consistent sandbox logging.



---
