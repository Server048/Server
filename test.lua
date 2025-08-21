------------------------------------------------------------
-- Spam Script - Compatible with HUB Start/Stop + GUI rules
-- - Start/Stop di GUI Spam: stop loop saja, GUI tetap terbuka
-- - Stop dari HUB (set _G.shouldStop = true): loop stop + GUI tertutup
-- - Patuh ke StopCheck() milik HUB (fallback kalau tidak ada)
------------------------------------------------------------

-----------------------------
-- 1) GLOBAL FLAGS (shared) --
-----------------------------
_G.shouldStop       = _G.shouldStop or false  -- Hub akan set true saat terminate semua
_G.hubForceCloseUI  = _G.hubForceCloseUI or false  -- optional: Hub bisa set true utk paksa tutup semua UI

-----------------------------
-- 2) STATE KHUSUS SCRIPT  --
-----------------------------
local HOOK_NAME        = "SpamGUI_Controller_v2"  -- unik agar tidak tabrakan
_G.spamShow            = (_G.spamShow ~= nil) and _G.spamShow or true  -- tampilkan GUI spam?
_G.spamRunning         = _G.spamRunning or false  -- status loop
local spamThread       = nil
local spamText         = "Hello World!"
local spamDelay        = 2000  -- ms
local statusText       = "Idle"

-- log helper
local function log(m)
  if LogToConsole then LogToConsole("SPAM> "..m) else print("SPAM> "..m) end
end

------------------------------------------------------------
-- 3) StopCheck fallback (pakai milik HUB jika ada)
------------------------------------------------------------
local function StopCheck()
  if _G.StopCheck then
    -- gunakan StopCheck dari Hub (bisa lempar error STOP_REQUESTED)
    _G.StopCheck()
  else
    -- fallback: cek shouldStop dan lempar error agar pcall cleanup bisa jalan
    if _G.shouldStop then error("STOP_REQUESTED") end
  end
end

----------------------------------------------------------------
-- 4) OPTIONAL: registrasi ke ScriptBus kalau Hub menyediakannya
----------------------------------------------------------------
-- Kontrak minimal ScriptBus (opsional):
-- _G.ScriptBus:register("spam", {
--   stop = function(forceClose) ... end,     -- dipanggil Hub saat stop_all()
--   close_ui = function() ... end            -- dipanggil Hub utk hanya menutup UI
-- })
if not _G.ScriptBus then
  -- buat dummy ringan biar script lain bisa ikut standar ini tanpa wajib Hub
  _G.ScriptBus = {
    _map = {},
    register = function(self, name, handlers) self._map[name] = handlers end,
    stop_all = function(self)
      for _, h in pairs(self._map) do
        if h and h.stop then pcall(h.stop, true) end
      end
    end,
    close_all_ui = function(self)
      for _, h in pairs(self._map) do
        if h and h.close_ui then pcall(h.close_ui) end
      end
    end
  }
end

------------------------------------------------------------
-- 5) FUNGSI START / STOP (bisa dipanggil Hub atau GUI)
------------------------------------------------------------
function StartSpam()
  if _G.spamRunning then
    log("⚠ Spam sudah berjalan.")
    return
  end

  -- reset sinyal stop global kalau ada sisa
  -- (biarkan Hub yang set true saat terminate global)
  -- _G.shouldStop = false -- JANGAN direset paksa, biar patuh Hub
  if _G.shouldStop then
    log("Tidak bisa start karena HUB sedang mode STOP. Buka dari Hub dulu.")
    return
  end

  _G.spamRunning = true
  _G.spamShow    = true
  statusText     = "Running..."

  spamThread = RunThread(function()
    local ok, err = pcall(function()
      while true do
        StopCheck()  -- patuh Hub STOP
        SendPacket(2, "action|input\n|text|" .. spamText)
        Sleep(spamDelay)
      end
    end)

    -- CLEANUP selalu jalan
    _G.spamRunning = false
    statusText = "Idle"

    -- Jika stop datang dari Hub, auto close UI
    if _G.shouldStop or _G.hubForceCloseUI then
      _G.spamShow = false
    end

    if not ok then
      if tostring(err):find("STOP_REQUESTED") then
        log("✅ Loop spam dihentikan.")
      else
        log("❌ Error: " .. tostring(err))
      end
    end

    spamThread = nil
  end)
end

function StopSpam()
  if not _G.spamRunning then
    log("Tidak ada loop spam yang berjalan.")
    return
  end
  statusText = "Stopping..."
  -- Hanya hentikan loop script ini, GUI tetap terbuka
  -- Caranya: biarkan StopCheck melempar error dengan sinyal lokal.
  -- Karena StopCheck membaca _G.shouldStop (global), kita kasih alternatif:
  -- → kirim sinyal via flag lokal & Sleep pendek + soft error.
  -- Solusi umum: trigger error manual agar pcall cleanup langsung jalan.
  error("STOP_REQUESTED")  -- ini akan ditangkap pcall di StartSpam()
end

-- Handler yang akan dipanggil ScriptBus/Hub
local function HubStopHandler(forceClose)
  -- forceClose == true → Hub minta hentikan loop + tutup GUI
  if _G.spamRunning then
    statusText = "Stopping..."
  end
  -- Pastikan StopCheck mendeteksi stop → pakai sinyal global
  _G.shouldStop = true
  if forceClose then
    _G.hubForceCloseUI = true
    _G.spamShow = false
  end
end

local function HubCloseUIHandler()
  _G.spamShow = false
end

-- Register ke ScriptBus (biar Hub bisa stop/close UI semua script)
_G.ScriptBus:register("spam", {
  stop     = HubStopHandler,
  close_ui = HubCloseUIHandler
})

------------------------------------------------------------
-- 6) IMGUI: GUI script (independen dari GUI Hub)
------------------------------------------------------------
AddHook("OnDraw", HOOK_NAME, function()
  -- Jika Hub minta paksa close UI, jangan gambar window
  if _G.hubForceCloseUI then return end
  if not _G.spamShow then return end

  if ImGui.Begin("Spam Controller", true, ImGuiWindowFlags_AlwaysAutoResize) then
    ImGui.Text("Pengaturan Spam")

    ImGui.PushItemWidth(260)
    _, spamText  = ImGui.InputText("Teks Spam",  spamText, 140)
    _, spamDelay = ImGui.InputInt("Delay (ms)",  spamDelay)
    ImGui.PopItemWidth()

    if not _G.spamRunning then
      if ImGui.Button("▶ Start Spam") then
        -- reset UI-only flags
        _G.hubForceCloseUI = false
        StartSpam()
      end
      ImGui.SameLine()
      if ImGui.Button("Tutup GUI") then
        _G.spamShow = false
      end
    else
      if ImGui.Button("⏹ Stop Spam (hanya loop)") then
        -- hentikan loop saja, GUI tetap
        -- lakukan via raising error agar pcall cleanup di StartSpam() eksekusi
        pcall(function() error("STOP_REQUESTED") end)
      end
      ImGui.SameLine()
      ImGui.BeginDisabled(true)
      ImGui.Button("Tutup GUI")  -- saat running, tombol close dinonaktifkan
      ImGui.EndDisabled()
    end

    ImGui.Text("Status: " .. statusText)
    ImGui.End()
  end
end)

------------------------------------------------------------
-- 7) Listener global: jika HUB toggle shouldStop saat ini,
--    force close GUI + hentikan loop di frame berikutnya
------------------------------------------------------------
RunThread(function()
  local lastStop = _G.shouldStop
  while true do
    if _G.shouldStop and not lastStop then
      -- Hub baru saja mengaktifkan STOP
      _G.spamShow = false
    end
    lastStop = _G.shouldStop
    Sleep(100)
  end
end)

-- Catatan integrasi dengan GUI Hub kamu:
-- - Saat Hub klik "Stop Script": set _G.shouldStop = true; (opsional) _G.hubForceCloseUI = true
--   atau panggil _G.ScriptBus:stop_all()
-- - Saat Hub ingin menutup semua UI saja: _G.ScriptBus:close_all_ui()
-- - Script ini otomatis patuh ke StopCheck() milik Hub jika ada.
