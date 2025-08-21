

_G.shouldStop       = _G.shouldStop or false      
_G.hubForceCloseUI  = _G.hubForceCloseUI or false
_G.spamShow         = (_G.spamShow ~= nil) and _G.spamShow or true
_G.spamRunning      = _G.spamRunning or false


local HOOK_NAME   = "SpamGUI_Controller"
local spamThread  = nil
local spamText    = "Hello World!"
local spamDelay   = 2000
local statusText  = "Idle"


local function StopCheck()
  if _G.StopCheck then
    _G.StopCheck()
  else
    if _G.shouldStop then error("STOP_REQUESTED")
     end
  end
end


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
      while _G.spamRunning do
        StopCheck()
        SendPacket(2, "action|input\n|text|" .. spamText)
        Sleep(spamDelay)
      end
    end)

    _G.spamRunning = false
    statusText = "Idle"

    
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
  if _G.spamRunning then
    statusText = "Stopping..."
  _G.spamRunning = false
    return
  end
  addLog("Tidak ada spam yang berjalan.")
  
end

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
      if ImGui.Button("⏹ Stop Spam") then StopSpam()
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
