-----------------------------
-- SPAM CONTROLLER (1 file)
-----------------------------

_G.shouldStop   = false
_G.spamRunning  = false
_G.spamShow     = true
local spamThread = nil
local spamText   = "Hello World!"
local spamDelay  = 2000
local statusText = "Idle"
local HOOK_NAME  = "SpamGUI_Controller"

local function log(m) if LogToConsole then LogToConsole(m) else print(m) end end

function StopCheck()
  if _G.shouldStop then error("STOP_REQUESTED") end
end

function StartSpam()
  if _G.spamRunning then
    log("⚠ Spam sudah berjalan")
    return
  end

  _G.shouldStop  = false
  _G.spamRunning = true
  _G.spamShow    = true
  statusText     = "Running..."

  spamThread = RunThread(function()
    local ok, err = pcall(function()
      while true do
        StopCheck()
        SendPacket(2, "action|input\n|text|" .. spamText)
        Sleep(spamDelay)
      end
    end)

    -- cleanup
    _G.spamRunning = false
    _G.shouldStop  = false
    statusText     = "Idle"

    if not ok and not tostring(err):find("STOP_REQUESTED") then
      log("❌ Error di spam: " .. tostring(err))
    end

    spamThread = nil
  end)
end

-- StopSpam punya opsi: fromUI
function StopSpam(fromUI)
  if not _G.spamRunning then
    log("Tidak ada spam yang berjalan")
    return
  end
  statusText    = "Stopping..."
  _G.shouldStop = true

  -- Kalau stop dari UI, biarkan GUI tetap terbuka
  if not fromUI then
    _G.spamShow = false
  end
end

-- ==== IMGUI ====
AddHook("OnDraw", HOOK_NAME, function()
  if not _G.spamShow then return end

  if ImGui.Begin("Spam Controller", true, ImGuiWindowFlags_AlwaysAutoResize) then
    ImGui.Text("Pengaturan Spam")

    ImGui.PushItemWidth(260)
    _, spamText  = ImGui.InputText("Teks Spam", spamText, 120)
    _, spamDelay = ImGui.InputInt("Delay (ms)", spamDelay)
    ImGui.PopItemWidth()

    if not _G.spamRunning then
      if ImGui.Button("▶ Start Spam") then StartSpam() end
      ImGui.SameLine()
      if ImGui.Button("❌ Tutup GUI") then _G.spamShow = false end
    else
      if ImGui.Button("⏹ Stop Spam") then StopSpam(true) end -- << stop dari UI
      ImGui.SameLine()
      ImGui.BeginDisabled(true)
      ImGui.Button("❌ Tutup GUI")
      ImGui.EndDisabled()
    end

    ImGui.Text("Status: " .. statusText)
    ImGui.End()
  end
end)
