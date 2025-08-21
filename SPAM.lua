------------------------------------------------------------
-- Spam Controller (Gabungan)
-- - Start/Stop via GUI Spam
-- - Stop via HUB (terminate semua script)
-- - Patuh StopCheck() milik HUB
-- - ScriptBus support (stop_all / close_all_ui)
------------------------------------------------------------

-----------------------------
-- 1) GLOBAL FLAGS (shared) --
-----------------------------
_G.shouldStop       = _G.shouldStop or false      -- Hub set true utk terminate semua
_G.hubForceCloseUI  = _G.hubForceCloseUI or false -- Hub bisa paksa tutup UI
_G.spamShow         = (_G.spamShow ~= nil) and _G.spamShow or true
_G.spamRunning      = _G.spamRunning or false

-----------------------------
-- 2) STATE SPAM SCRIPT -----
-----------------------------
local HOOK_NAME   = "SpamGUI_Controller"
local spamThread  = nil
local spamText    = "Hello World!"
local spamDelay   = 2000
local statusText  = "Idle"



------------------------------------------------------------
-- 3) StopCheck fallback (pakai HUB jika ada)
------------------------------------------------------------
local function StopCheck()
  if _G.StopCheck then
    _G.StopCheck() -- gunakan versi HUB
  else
    if _G.shouldStop then error("STOP_REQUESTED")
    end
  end
end

------------------------------------------------------------
-- 4) ScriptBus Registrasi (biar HUB bisa control)
------------------------------------------------------------
if not _G.ScriptBus then
  _G.ScriptBus = {
    _map = {},
    register = function(self, name, handlers) self._map[name] = handlers end,
    stop_all = function(self)
      for _, h in pairs(self._map) do if h.stop then pcall(h.stop, true) end end
    end,
    close_all_ui = function(self)
      for _, h in pairs(self._map) do if h.close_ui then pcall(h.close_ui) end end
    end
  }
end

------------------------------------------------------------
-- 5) START / STOP
------------------------------------------------------------
function StartSpam()
  if _G.spamRunning then
    addLog("⚠ Spam sudah berjalan.")
    return
  end
  if _G.shouldStop then
    addLog("Tidak bisa start, HUB sedang STOP mode.")
    return
  end

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

    _G.spamRunning = false
    statusText = "Idle"

    -- jika HUB terminate → GUI auto close
    if _G.shouldStop or _G.hubForceCloseUI then
      _G.spamShow = false
    end

    if not ok then
      if tostring(err):find("STOP_REQUESTED") then
        addLog("✅ Spam dihentikan.")
      else
        addLog("❌ Error: " .. tostring(err))
      end
    end

    spamThread = nil
  end)
end

function StopSpam()
  if not _G.spamRunning then
    addLog("Tidak ada spam yang berjalan.")
    return
  end
  statusText = "Stopping..."
  -- lempar STOP agar pcall cleanup eksekusi
  error("STOP_REQUESTED")
end

-- handler untuk HUB
local function HubStopHandler(forceClose)
  if _G.spamRunning then statusText = "Stopping..." end
  _G.shouldStop = true
  if forceClose then
    _G.hubForceCloseUI = true
    _G.spamShow = false
  end
end
local function HubCloseUIHandler()
  _G.spamShow = false
end

_G.ScriptBus:register("spam", {
  stop     = HubStopHandler,
  close_ui = HubCloseUIHandler
})

------------------------------------------------------------
-- 6) GUI IMGUI
------------------------------------------------------------
AddHook("OnDraw", HOOK_NAME, function()
  if _G.hubForceCloseUI then return end
  if not _G.spamShow then return end

  if ImGui.Begin("Spam Controller", true, ImGuiWindowFlags_AlwaysAutoResize) then
    ImGui.Text("Pengaturan Spam")

    ImGui.PushItemWidth(260)
    _, spamText  = ImGui.InputText("Teks Spam",  spamText, 140)
    _, spamDelay = ImGui.InputInt("Delay (ms)", spamDelay)
    ImGui.PopItemWidth()

    if not _G.spamRunning then
      if ImGui.Button("▶ Start Spam") then
        _G.hubForceCloseUI = false
        StartSpam()
      end
      ImGui.SameLine()
      if ImGui.Button("Tutup GUI") then _G.spamShow = false end
    else
      if ImGui.Button("⏹ Stop Spam (loop saja)") then
        pcall(function() error("STOP_REQUESTED") end)
      end
      ImGui.SameLine()
      ImGui.BeginDisabled(true)
      ImGui.Button("Tutup GUI")
      ImGui.EndDisabled()
    end

    ImGui.Text("Status: " .. statusText)
    ImGui.End()
  end
end)

------------------------------------------------------------
-- 7) Listener HUB STOP
------------------------------------------------------------
RunThread(function()
  local lastStop = _G.shouldStop
  while true do
    if _G.shouldStop and not lastStop then
      _G.spamShow = false
    end
    lastStop = _G.shouldStop
    Sleep(100)
  end
end)
