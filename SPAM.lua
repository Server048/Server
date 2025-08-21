-- =======================================
-- SPAM BOT + GUI
-- =======================================

-- STATE

local runningSpam = false
local spamThread = nil


-- CONFIG
local spamText = "Hello World!"
local spamDelay = 5000 

----------------------------------------------------
-- ============ SPAM LOOP =========================
----------------------------------------------------
local function spamLoop()
    while not shouldStop do
        StopCheck()
        
        if runningSpam then
            SendPacket(2, "action|input\n|text|" .. spamText)
      addLog("[SPAM] >> " .. spamText)
            Sleep(spamDelay)
        else
            Sleep(100)
        end
    end
    showWindow = false
    addLog(" Script dihentikan total.")
end

local function StartSpam()
    if runningSpam then
        addLog("Spam sudah berjalan.")
        return
    end
    runningSpam = true
    addLog("▶ Spam dimulai.")
end

local function StopSpam()
    if not runningSpam then
        addLog("Spam tidak berjalan.")
        return
    end
    runningSpam = false
    addLog("⏹ Spam dihentikan Stoping.")
end

----------------------------------------------------
-- ============ MAIN THREAD ========================
----------------------------------------------------
RunThread(spamLoop)

----------------------------------------------------
-- ============ GUI (IMGUI PANEL) =================
----------------------------------------------------
AddHook("OnDraw", "SPAM_GUI", function()
    if not showWindow then return end

    if ImGui.Begin("Spam Controller") then
        ImGui.Text("Pengaturan Spam")

        _, spamText = ImGui.InputText("Teks Spam", spamText, 128)
        _, spamDelay = ImGui.InputInt("Delay (ms)", spamDelay)

        ImGui.Separator()
        if not runningSpam then
            if ImGui.Button("▶ Start Spam") then StartSpam() end
        else
            if ImGui.Button("⏹ Stop Spam") then StopSpam() end
        end

        ImGui.Text("Status: " .. (runningSpam and "Running" or "Idle"))

        ImGui.Separator()
        ImGui.End()
    end
end)
