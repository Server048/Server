

Markdown
# 🛡️ Secure Lua Sandbox for User Scripts

> A lightweight, robust, and secure Lua sandbox environment designed to execute untrusted user scripts safely with hooks, logging, and controlled execution flow.

![Lua](https://img.shields.io/badge/Lua-5.1%2B-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 📖 Overview

This repository provides a wrapper function, `createSandbox(scriptName, task)`, which generates a restricted environment (`_ENV`) for Lua scripts. It is designed for applications (like games, bots, or automation tools) that need to allow users to write custom logic without compromising the stability or security of the host application.

**Key capabilities:**
* **Isolation:** Prevents access to sensitive global variables (via `BLOCKED_KEYS`).
* **Anti-Freeze:** Implements a safe `sleep()` mechanism that allows the host to interrupt infinite loops.
* **Hook System:** Automatically namespaces hooks to prevent collisions between different user scripts.
* **Controlled I/O:**Restricted file writing and prefixed logging.

---

## ✨ Features

| Feature | Description |
| :--- | :--- |
| **Sandboxed Globals** | Restricts access to unsafe functions (e.g., `os.execute`, `io.open`) while whitelisting safe ones (`math`, `table`, `string`). |
| **Safe Sleep** | `sleep(ms)` breaks delays into small 50ms chunks, constantly checking if the script should stop. |
| **Graceful Shutdown** | Scripts can be stopped instantly via `stop()` or by flagging the `task` object, without freezing the host thread. |
| **Namespace Hooks** | Hooks registered via `AddHook` are internally prefixed with `ScriptName::ID` to ensure uniqueness. |
| **Logging Proxy** | `log()` outputs are automatically tagged with `[ScriptName]` for easy debugging. |

---

## 🛠️ Integration (Host Side)

To use the sandbox in your application, include the `createSandbox` function.

### Host Implementation Example

```lua
-- 1. Define the task control object
local task = { 
    shouldStop = false 
}

-- 2. Create the sandbox environment
local scriptName = "UserScript_01"
local sandboxEnv = createSandbox(scriptName, task)

-- 3. Load user code into the sandbox
local userCode = [[
    function main()
        log("Hello from sandbox!")
        sleep(1000)
    end
]]

-- 4. Compile and Run
local chunk, err = load(userCode, scriptName, "t", sandboxEnv)

if chunk then
    -- Run protected call
    local status, errorMsg = pcall(chunk)
    if not status then
        print("Script Error: " .. tostring(errorMsg))
    end
else
    print("Compilation Error: " .. tostring(err))
end

-- 5. Stopping the script safely from Host
-- task.shouldStop = true

📚 Scripting API Reference
These are the functions available to users writing scripts inside the sandbox.

1. Logging
log(message)
Prints a message to the host logger.

message: string | number | table

Output format: [ScriptName] <message>

Lua
log("Starting farming routine...")
log(12345)
2. Task Control & Flow
sleep(milliseconds)
Pauses execution for the specified duration.

Safety: This function yields internally and checks for stop requests every 50ms. It will throw a STOP_REQUESTED error if the host cancels the task.

Alias: Sleep(ms)

Lua
log("Waiting for cooldown...")
sleep(2500) -- Waits 2.5 seconds
yield()
Pauses execution momentarily (single frame/tick) to check for stop requests. Use this in heavy calculation loops where sleep isn't needed.

stop()
Immediately terminates the script execution.

Mechanism: Throws a STOP_REQUESTED error.

isRunning()
Returns a boolean indicating if the script is allowed to continue.

Returns: true if running, false if the host requested a stop.

Best Practice: Check this condition inside while loops.

Lua
while isRunning() do
    doWork()
    sleep(100)
end
3. Hook System
AddHook(type, id, callback)
Registers a listener for a specific event type.

type: string (e.g., "OnTick", "OnPacket")

id: string (Unique ID for this hook within the script)

callback: function

Note: The actual ID registered in the host system will be ScriptName::id.

Lua
AddHook("OnChat", "MyChatHandler", function(msg)
    if not isRunning() then return end
    log("Chat received: " .. msg)
end)
__removeAllHooks()
Cleans up all hooks registered by the current script context.

4. File I/O
write(path, content)
Writes text content to a file.

path: string (Relative path allowed by host)

content: string

🔒 Security & Architecture
Blocked Keys
The sandbox uses a metatable on the _ENV to intercept global access. If a user tries to access restricted keys (defined in BLOCKED_KEYS in the host code), an error is thrown:

"Access denied: [KeyName]"

Error Handling
The sleep and yield functions operate by throwing a specific Lua error: "STOP_REQUESTED". Warning for Scripters: Do not use a bare pcall around sleep() calls, as this will catch the stop signal and prevent the script from terminating.

❌ Bad Practice:

Lua
pcall(function() 
    sleep(1000) -- If stopped here, pcall catches the error
end)
-- Script continues running unintentionally!
✅ Good Practice:

Lua
local status, err = pcall(function()
    sleep(1000)
end)

if not status then
    if err == "STOP_REQUESTED" then error(err) end -- Re-throw stop signal
    log("Other error: " .. tostring(err))
end
📝 Default Script Template
When initializing a new script, you can use this template:

Lua
-- === Lua Sandbox Script ===

function main()
    log("Script initialized!")

    -- Example: Hooking into a game tick
    AddHook("Tick", "MainLoop", function()
        if not isRunning() then return end
        -- Your logic here
    end)

    -- Example: Main execution loop
    for i = 1, 10 do
        log("Counting: " .. i)
        sleep(500) -- Safe sleep
    end
    
    log("Script finished.")
end
🤝 Contributing
Contributions are welcome! Please ensure any changes to createSandbox maintain the strict isolation of the environment.

Fork the repository

Create your feature branch (git checkout -b feature/NewSafetyCheck)

Commit your changes

Push to the branch

Open a Pull Request

📄 License
This project is licensed under the MIT License - see the LICENSE file for details.


### Apa yang ditambahkan di README ini?
1.  **Banner/Badges:** Memberikan tampilan visual yang lebih menarik.
2.  **Struktur Host vs User:** Membedakan cara penggunaan untuk developer aplikasi (Host) dan penulis script (User/Scripter).
3.  **Tabel Fitur:** Memudahkan pembaca melihat kemampuan sandbox sekilas.
4.  **Security Section:** Penjelasan teknis tentang bagaimana keamanan dijaga (metatable & error throwing), ini penting untuk meyakinkan pengguna bahwa sandboxing-nya aman.
5.  **Best Practices:** Peringatan penting mengenai penggunaan `pcall` agar script bisa di-stop dengan benar.
