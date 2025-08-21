-- =========================
-- PNB Controller - Full
-- (gabungan PNB logic + Hub API + GUI)
-- =========================

-- ============ USER CONFIG ============
local Posisi_x = 186
local Posisi_y = 196

local Arah_player = "kanan"
local Gems_mode   = "cv"
local Bgems_take  = "no"

local Disable_player   = "on"
local Ignore_drop      = "on"
local Ignore_completely= "on"

-- ADVANCE
local autobuyvend = "off"
local worldvend = "off"
local aVposX, aVposY = Posisi_x, Posisi_y
local cVposX, cVposY = Posisi_x, Posisi_y

local cvpergems = 300000

-- ID
local BackgroundID = 12840
local mpID         = 5638
local teleID       = 3898

-- ============ STATE & HUB FLAGS ============
_G.shouldStop      = _G.shouldStop or false       -- Hub terminate all scripts
_G.hubForceCloseUI = _G.hubForceCloseUI or false  -- Hub force close UIs
_G.pnbRunning      = _G.pnbRunning or false       -- sedang menjalankan PNB loop
_G.pnbShow         = (_G.pnbShow ~= nil) and _G.pnbShow or true -- tampilkan GUI

local runningPNB = false
local shouldStopLocal = false
local pnbThread = nil
local statusText = "Idle"

-- ============ SCRIPT BASE (keaslian fungsional) ============
local Tgems, arrozz, cloverr, blackz, blueg, diaml = 0, 0, 0, 0, 0, 0
local cvdl, bgems, gems, lag1, lag2, lag3, cheats, arah, arroz, clover = false, false, nil, 0, 0, 0, false, 32, false, false
local aMP, aMPu = 0, 1
local teleposx, teleposy = nil, nil
local Scans, yok, stp, jtw, prog, findit, ceki, modes, joinworld = true, false, false, false, false, true, true, true, false
local totalElapsed, timeString, M_E_T, Days, cycel_time, stocks = 0, nil, 24 * 60 * 60 * 1000, 0, 0, 0
local world_name = (GetWorld() and GetWorld().name) or ""
local netid = (GetLocal() and GetLocal().netid) or 0

local MagplantManager = {
    magplants = {},
    takenMagplants = {},
    currentIndex = 1,
    lastTakenMagplant = nil,
    lastKnownMagplant = nil,
    magplantTaken = false,
    canReplace = false,
    mgh = false,
    rept = false,
    cmg = false
}

-- ============ UTIL / Safety / Hub integration ============
-- StopCheck: gunakan StopCheck global kalau ada, fallback ke _G.shouldStop
local function HubStopCheck()
    if _G.StopCheck then
        _G.StopCheck()
    else
        if _G.shouldStop then error("STOP_REQUESTED") end
    end
end

-- SafeSleep: sleep namun periodik memeriksa StopCheck agar responsive
local function SafeSleep(ms)
    local t = 0
    while t < ms do
        HubStopCheck()
        Sleep(50)
        t = t + 50
    end
end

-- ScriptBus: registrasi supaya Hub bisa stop_all / close_all_ui
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

-- ============ Helper functions dari PNB asli ============
function fnd(id)
    local count = 0
    for _, inv in pairs(GetInventory()) do
        if inv.id == id then
            count = count + inv.amount
        end
    end
    return count
end

function sycroneC()
  if Arah_player == "kiri" or Arah_player == "Kiri" then
    arah = 48
  else
    arah = 32
  end
  if Gems_mode == "cv" or Gems_mode == "Cv" then
      gems = 1
      cvdl = true
    elseif Gems_mode == "take" or Gems_mode == "Take" then
      gems = 1
      cvdl = false
    elseif Gems_mode == "drop" or Gems_mode == "Drop" then
      gems = 0
      cvdl = false
  end
  if Bgems_take == "yes" or Bgems_take == "Yes" then
      bgems = true
  else
      bgems = false
  end
  if Disable_player == "on" or Disable_player == "On" then
      lag1 = 1
  else lag1 = 0 end
  if Ignore_drop == "on" or Ignore_drop == "On" then
      lag2 = 1
  else lag2 = 0 end
  if Ignore_completely == "on" or Ignore_completely == "On" then
      lag3 = 1
  else lag3 = 0 end
end

function wtrmk(msg); LogToConsole("`0[`cPNB`0] **`w " .. msg); end
function overlayText(text); SendVariantList({[0] = "OnTextOverlay", [1] = "`0[`cPNB`0]`w " .. text}); end

function wJ(world_name12)
    SendPacket(3, "action|join_request\nname|" .. world_name12)
end

function isErrorDetected()
    local success, result = pcall(GetLocal)
    return not success or type(result) ~= "table"
end

function ErrorD(anc)
    if joinworld == true then
        overlayText(""..anc.." Not in world?, Rejoin..")
        SafeSleep(500)
        wJ(world_name)
    else
        overlayText(""..anc.." Disconnect?, Wait for reconnect..")
    end
    SafeSleep(5000)
    MagplantManager.rept = true
end

function sSendPacketRaw(typ, pkt)
  if isErrorDetected() then
    while isErrorDetected() do
      ErrorD("PktRaw")
    end
    joinworld = false
    SafeSleep(1000)
  end
  SendPacketRaw(typ, pkt)
end

function sSendPacket(typ, pkt)
  if isErrorDetected() then
    while isErrorDetected() do
        ErrorD("Pkt")
    end
    joinworld = false
    SafeSleep(1000)
  end
  SendPacket(typ, pkt)
end

function sGetPlayerItems()
  if isErrorDetected() then
    while isErrorDetected() do
        ErrorD("GetItems")
    end
    joinworld = false
    SafeSleep(1000)
  end
  return GetPlayerItems()
end

function sGetPlayerInfo()
  if isErrorDetected() then
    while isErrorDetected() do
        ErrorD("GetItems")
    end
    joinworld = false
    SafeSleep(1000)
  end
  return GetPlayerInfo()
end

function sGetTile(x, y)
  if isErrorDetected() then
    while isErrorDetected() do
        ErrorD("GetTile")
    end
    joinworld = false
    SafeSleep(1000)
  end
  return GetTile(x, y)
end

function sGetLocal()
  if isErrorDetected() then
    while isErrorDetected() do
        ErrorD("GetLocal")
    end
    joinworld = false
    SafeSleep(1000)
  end
  return GetLocal()
end

function GetData()
    arrozz = fnd(4604)
    cloverr = fnd(528)
    blackz = fnd(11550)
    blueg = fnd(7188)
    diaml = fnd(1796)
end

function server(t, s, v, x, y)
    sSendPacketRaw(false, {type = t, state = s, value = v, px = x, py = y, x = x * 32, y = y * 32})
end

function buyvend(buybrp, posX, posY)
    local tile = sGetTile(posX, posY)
    if tile and tile.fg == 9268 then
      sSendPacket(2, "action|dialog_return\ndialog_name|vend_edit\nx|"..posX.."|\ny|"..posY.."|\nbuttonClicked|pullstock")
      SafeSleep(500)
      sSendPacket(2, "action|dialog_return\ndialog_name|vend_buyconfirm\nx|"..posX.."|\ny|"..posY.."|\nbuyamount|"..buybrp.."|\n")
    else
      overlayText("Vending not found")
      SafeSleep(2000)
    end
end

function cheat(toggleOn)
    if toggleOn then
       sSendPacket(2, "action|dialog_return\n" ..
           "dialog_name|cheats\n" ..
           "check_autofarm|1\n" ..
           "check_bfg|1\n" ..
           "check_antibounce|1\n" ..
           "check_lonely|" .. lag1 .. "\n" ..
           "check_gems|" .. gems .. "\n" ..
           "check_ignoreo|" .. lag2 .. "\n" ..
           "check_ignoref|" .. lag3)
       addLog(" CheatMenu ON (autofarm+bfg+gems).")
    else
       sSendPacket(2, "action|dialog_return\n" ..
           "dialog_name|cheats\n" ..
           "check_autofarm|0\n" ..
           "check_bfg|0\n" ..
           "check_antibounce|0\n" ..
           "check_lonely|" .. lag1 .. "\n" ..
           "check_gems|" .. gems .. "\n" ..
           "check_ignoreo|" .. lag2 .. "\n" ..
           "check_ignoref|" .. lag3)
       addLog(" CheatMenu OFF.")
    end
end

-- Magplant manager functions (preserve logic)
local function isPositionExists(list, x, y)
    for _, pos in ipairs(list) do
        if pos[1] == x and pos[2] == y then
            return true
        end
    end
    return false
end

function MagplantManager:findMagplants()
    self.magplants = {}
    aMP=0
    for y = 199, 0, -1 do
      if y >= 10 and y % 10 == 0 then SafeSleep(1) end
        for x = 199, 0, -1 do
            local tile = sGetTile(x, y)
            if tile and tile.bg == BackgroundID and tile.fg == mpID and not isPositionExists(self.magplants, x, y) then
                SafeSleep(5)
                table.insert(self.magplants, {x, y})
                aMP = aMP + 1
            end
        end
    end
end

function MagplantManager:takeMagplant()
    if self.mgh then
        SafeSleep(900)
        sSendPacket(2, "action|input\n|text|/ghost")
        self.mgh = false
    end

    if not self.magplantTaken then
        if #self.magplants == 0 then
          self:findMagplants()
        end

        local targetMagplant
        if self.rept then
            targetMagplant = self.lastKnownMagplant or self.lastTakenMagplant
        else
            for i, magplant in ipairs(self.magplants) do
                if not isPositionExists(self.takenMagplants, magplant[1], magplant[2]) then
                    targetMagplant = magplant
                    table.remove(self.magplants, i)
                    break
                end
            end
        end
        
        if targetMagplant then
            local x, y = targetMagplant[1], targetMagplant[2]
            self.lastKnownMagplant = {x, y}
            yok = false
            SafeSleep(1000)
            overlayText(string.format("`!Taking the Magplant at (%d, %d)", x, y))
            addLog(string.format("Taking the Magplant at (%d, %d)", x, y))
            server(0, arah, 0, x, y - 1)
            SafeSleep(1000)
            server(3, 0, 32, x, y)
            SafeSleep(1000)
            sSendPacket(2, string.format("action|dialog_return\ndialog_name|magplant_edit\nx|%d|\ny|%d|\nbuttonClicked|getRemote", x, y))
            self.magplantTaken = true
            self.canReplace = true
            if not self.rept then
                table.insert(self.takenMagplants, {x, y})
                self.lastTakenMagplant = {x, y}
            end
        end
    end
end

function MagplantManager:nextMagplant()
    if self.canReplace then
        self.canReplace = false
        if #self.magplants == 0 then self:findMagplants() end
        
        if #self.magplants > 0 then
            self.currentIndex = (self.currentIndex % #self.magplants) + 1
            self.magplantTaken = false
        else
            wtrmk("`4No Magplants found!")
        end
    end
end

function MagplantManager:resetAndUpdate()
    if #self.magplants == 0 and #self.takenMagplants > 0 then
        wtrmk("`bAll Magplants taken, resetting list...")
        self.takenMagplants = {}
        self:findMagplants()
        self.magplantTaken = false
        aMPu = 1
    end

    if #self.magplants == 0 and #self.takenMagplants > 0 then
        wtrmk("`bAll Magplants are taken, waiting for new Magplants to be placed.")
        SafeSleep(5000)
        self:findMagplants()
    end

    if self.cmg then
        wtrmk("Oops! Magplant is empty! Let's go to the next Magplant!")
        self.cmg = false
        self:nextMagplant()
        self:takeMagplant()
    end
end

function MagplantManager:retake()
  if self.lastTakenMagplant then
    self.magplantTaken = false
    self.cmg = false
    self.rept = true
    self:takeMagplant()
    self.rept = false
  else
    self:takeMagplant()
  end
end

-- ============ Event hook (preserve) ============
AddHook("onvariant", "pnb_onvariant", function(var)
    -- gunakan logic asli (disesuaikan) dan return boolean sesuai behavior
    if var[0] == "OnTalkBubble" then
        if var[2]:find("Collected") then
          -- nothing
        elseif var[2]:find("You received a MAGPLANT 5000 Remote.") then
            yok = true
        elseif var[2]:find("The MAGPLANT 5000 is empty.") then
            MagplantManager.cmg = true
        end
                
    elseif var[0] == "OnConsoleMessage" then
        if var[1]:find("Your luck has worn off.") then clover = true end
        if var[1]:find("Your stomach's rumbling.") then arroz = true end
        if var[1]:find("You're luckier than before!") then clover = false end
        if var[1]:find("chance of a gem") then arroz = false end
        if var[1]:find("Where would you like to go?") then joinworld = true end
        if var[1]:find("World Locked") then MagplantManager.rept = true
        elseif var[1]:find("returns to normal") or var[1]:find("can't use this command here") then MagplantManager.mgh = true end
    elseif var[0] == "OnDialogRequest" then
      if var[1]:find("DigiVend") then return true end
      if var[1]:find("MAGPLANT 5000") then
        local amous = var[1]:match("Stock: `$(%d+)")
        local amou = 0
        if amous == nil then amou = 0 else amou = amous end
        stocks = amou
        return true
      end
      if var[1]:find("Black Backpack") then
        if var[1]:find("Breaking Gems") then arroz = false else arroz = true end
        if var[1]:find("Lucky!") then clover = false else clover = true end
        return true
      elseif var[1]:find("cheat") then return true
      elseif var[1]:find("telephone") then return true
      end
    elseif var[0] == "OnSDBroadcast" then
        return true
    end
    return false
end)

-- ============ R delays ============
local tamous, tamous1, tamous2 = 0, 0, 0
function R2delay(cyc1)
  if tamous2 > cyc1 then tamous2 = 0; return true else tamous2 = tamous2 + 1; return false end
end
function R1delay(cyc1)
  if tamous1 > cyc1 then tamous1 = 0; return true else tamous1 = tamous1 + 1; return false end
end
function Rdelay(cyc)
  if tamous > cyc then tamous = 0; return true else tamous = tamous + 1; return false end
end

function telefind()
    local savecorx196 = Posisi_x - 196
    local savecory196 = Posisi_y - 196
    local hasilsy = 3
    local hasiley = 3
    local hasilsx = 3
    local hasilex = 3

    if Posisi_y < 3  then hasilsy = Posisi_y
    elseif Posisi_y > 196 then
        if savecory196 == 1 then savecory196 = 2
        elseif savecory196 == 2 then savecory196 = 1
        elseif savecory196 == 3 then savecory196 = 0 end
        hasiley = savecory196
    end
    if Posisi_x < 3  then hasilsx = Posisi_x
    elseif Posisi_x > 196 then
        if savecorx196 == 1 then savecorx196 = 2
        elseif savecorx196 == 2 then savecorx196 = 1
        elseif savecorx196 == 3 then savecorx196 = 0 end
        hasilex = savecorx196
    end
  
    local startY = Posisi_y - hasilsy
    local endY = Posisi_y + hasiley
    local startX = Posisi_x - hasilsx
    local endX = Posisi_x + hasilex
    local foundit = true

    for y = startY, endY do
        for x = startX, endX do
            local tile = sGetTile(x, y)
            if tile and tile.fg == teleID then
                SafeSleep(5)
                foundit = false
                teleposx = x
                teleposy = y
            end
        end
    end
    if foundit then
      overlayText("`4Telephone not found")
      SafeSleep(100)
    else
      overlayText("`5Telephone found at: X "..teleposx.." Y "..teleposy)
      SafeSleep(100)
    end
end

-- initial setup from original script
GetData(); SafeSleep(100)
sycroneC(); SafeSleep(100)
telefind()
cheat(false); SafeSleep(5000)
cheats = true
sSendPacket(2, "action|input\n|text|/ghost"); SafeSleep(1000)
if MagplantManager.mgh then
    sSendPacket(2, "action|input\n|text|/ghost")
    MagplantManager.mgh = false
    SafeSleep(1000)
    FindPath(Posisi_x, Posisi_y, 700)
else
    FindPath(Posisi_x, Posisi_y, 700)
end
sSendPacket(2, "action|wrench\n|netid|"..netid); SafeSleep(200)

-- ============ pnbmain (dibuat responsive untuk StopCheck) ============
function pnbmain()
    HubStopCheck() -- cek stop global pada awal
    if MagplantManager.rept or not yok then
        if not cheats then
            cheat(false); SafeSleep(1000); cheats = true
        end
        SafeSleep(200)
        MagplantManager:resetAndUpdate()
        MagplantManager:retake()
        MagplantManager.magplantTaken = false
        wtrmk("Inside stocks: "..tostring(stocks))
    elseif MagplantManager.cmg then
        if not cheats then cheat(false); SafeSleep(1000); cheats = true end
        aMPu = aMPu + 1
        SafeSleep(200)
        MagplantManager:resetAndUpdate()
        MagplantManager:takeMagplant()
        overlayText("Inside stocks: `2"..stocks.."`0. `5Magplant: ("..aMPu.."/"..aMP..")")
    end

    if MagplantManager.mgh then
        SafeSleep(1000)
        sSendPacket(2, "action|input\n|text|/ghost")
        MagplantManager.mgh = false
    end

    if stocks == 0 then SafeSleep(200); MagplantManager.cmg=true; return end

    if cheats then
        local apunch = nil
        if arah == 48 then apunch = Posisi_x - 1 else apunch = Posisi_x + 1 end
        server(nil, nil, nil, Posisi_x, Posisi_y)
        server(0, arah, 0, Posisi_x, Posisi_y)
        SafeSleep(100)
        server(3, 0, 18, apunch, Posisi_y)
        server(0, arah, 0, Posisi_x, Posisi_y)
        SafeSleep(100)
        if not yok then return end
        cheat(true)
        SafeSleep(1000)
        cheats = false
    end

    if Rdelay(5) then
        if cvdl then
            local sTgems = (sGetPlayerItems() and sGetPlayerItems().gems) or 0
            if sTgems > cvpergems then
                sSendPacket(2,"action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|".. teleposx .."|\ny|".. teleposy .."|\nbuttonClicked|dlconvert")
                SafeSleep(100)
                if diaml > 99 then
                    sSendPacket(2,"action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|".. teleposx .."|\ny|".. teleposy .."|\nbuttonClicked|bglconvert")
                    SafeSleep(100)
                elseif blueg > 99 then
                    sSendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bgl")
                    SafeSleep(100)
                end
            end
        end
        if bgems then
            sSendPacket(2, "action|dialog_return\ndialog_name|popup\nbuttonClicked|bgem_suckall")
        end
    end

    if R1delay(20) then
        if autobuyvend == "on" then
            if arrozz < 1 then
                overlayText("Arroz is empty")
                if worldvend ~= "off" then
                    wJ(worldvend)
                    SafeSleep(15000)
                end
                if not cheats then cheat(false); SafeSleep(1000); cheats = true end
                overlayText("Buying arroz at: `5X "..aVposX.." Y "..aVposY)
                server(nil, nil, nil, aVposX, aVposY)
                server(3, arah, 32, aVposX, aVposY)
                SafeSleep(1000)
                buyvend(250, aVposX, aVposY)
                SafeSleep(1000)
                if worldvend ~= "off" then wJ(world_name); SafeSleep(15000) end
            end
            if cloverr < 1 then
                overlayText("clover is empty")
                if worldvend ~= "off" then wJ(worldvend); SafeSleep(15000) end
                if not cheats then cheat(false); SafeSleep(1000); cheats = true end
                overlayText("Buying clover at: `5X "..cVposX.." Y "..cVposY)
                server(nil, nil, nil, cVposX, cVposY)
                server(3, arah, 32, cVposX, cVposY)
                SafeSleep(1000)
                buyvend(250, cVposX, cVposY)
                SafeSleep(1000)
                if worldvend ~= "off" then wJ(world_name); SafeSleep(15000) end
            end
        end
        overlayText("`5Magplant: "..aMPu.."/"..aMP..". `9Arroz`0/`2Clover`0(`9"..arrozz.."`0|`2"..cloverr.."`0). `5[`s"..blackz.."Black`0|`e"..blueg.."bgl`0|`1"..diaml.."dl`5]")
    end

    if R2delay(50) then GetData() end

    if arroz then SafeSleep(700); server(3, 0, 4604, Posisi_x, Posisi_y); SafeSleep(900) end
    if clover then SafeSleep(700); server(3, 0, 528, Posisi_x, Posisi_y); SafeSleep(900) end
end

-- ============ START / STOP API untuk Hub / GUI ============
function StartPNB()
    if _G.pnbRunning then
        addLog("Sudah berjalan.")
        return
    end
    if _G.shouldStop then
        addLog("Tidak bisa start karena HUB sedang STOP mode.")
        return
    end

    _G.pnbRunning = true
    _G.pnbShow = true
    statusText = "Running..."
    pnbThread = RunThread(function()
        local ok, err = pcall(function()
            while _G.pnbRunning do
                HubStopCheck()
                pnbmain()
                SafeSleep(100)
            end
        end)

        -- cleanup
        _G.pnbRunning = false
        statusText = "Idle"

        if _G.shouldStop or _G.hubForceCloseUI then
            _G.pnbShow = false
        end

        if not ok then
            if tostring(err):find("STOP_REQUESTED") then
                addLog("PNB dihentikan manual")
            else
                addLog("Error saat run PNB: " .. tostring(err))
            end
        end
        pnbThread = nil
    end)
    addLog("▶ Mulai PNB di world " .. tostring(world_name))
end

function StopPNB()
    if not _G.pnbRunning then
        addLog("Tidak ada PNB berjalan.")
        return
    end
    statusText = "Stopping..."
    -- hentikan loop PNB (GUI tetap terbuka)
    _G.pnbRunning = false
    -- juga pastikan HubStopCheck mendeteksi stop jika ingin stop total
    -- namun kita tidak set _G.shouldStop di sini supaya Hub/other scripts tetap hidup
end

-- Handler untuk Hub (forceStop: jika true maka tutup UI juga)
local function HubStopHandler(forceClose)
    if _G.pnbRunning then statusText = "Stopping..." end
    _G.shouldStop = true
    _G.pnbRunning = false
    if forceClose then
        _G.hubForceCloseUI = true
        _G.pnbShow = false
    end
end
local function HubCloseUIHandler()
    _G.pnbShow = false
end

_G.ScriptBus:register("pnb", {
  stop     = HubStopHandler,
  close_ui = HubCloseUIHandler
})

-- ============ GUI (ImGui) untuk Settings (pakai _G.pnbShow) ============
AddHook("OnDraw", "PNB_GUI_HUB", function()
    if _G.hubForceCloseUI then return end
    if not _G.pnbShow then return end

    if ImGui.Begin("PNB Controller", true, ImGuiWindowFlags_AlwaysAutoResize) then
        ImGui.Text("🌍 World & Position Settings")
        ImGui.Separator()

        -- Start / Stop
        if not _G.pnbRunning then
            if ImGui.Button("▶ Start PNB") then StartPNB() end
        else
            if ImGui.Button("⏹ Stop PNB") then StopPNB() end
        end

        ImGui.SameLine()
        if ImGui.Button("Tutup GUI") then _G.pnbShow = false end

        ImGui.Text("Status: " .. (_G.pnbRunning and ("Running @" .. tostring(world_name)) or statusText))
        ImGui.Separator()

        -- Set Settings tombol
        if ImGui.Button("✅ Set Settings") then
            sycroneC()
            addLog("🔄 Settingan diperbarui dari GUI")
        end
        ImGui.Separator()

        -- Posisi
        _, Posisi_x = ImGui.InputInt("Posisi X", Posisi_x)
        _, Posisi_y = ImGui.InputInt("Posisi Y", Posisi_y)

        ImGui.Separator()
        ImGui.Text("Arah Player")
        if ImGui.RadioButton("Kanan", Arah_player == "kanan") then Arah_player = "kanan" end
        ImGui.SameLine()
        if ImGui.RadioButton("Kiri", Arah_player == "kiri") then Arah_player = "kiri" end

        ImGui.Separator()
        ImGui.Text("Gems Mode")
        if ImGui.RadioButton("Convert", Gems_mode == "cv") then Gems_mode = "cv" end
        ImGui.SameLine()
        if ImGui.RadioButton("Take", Gems_mode == "take") then Gems_mode = "take" end
        ImGui.SameLine()
        if ImGui.RadioButton("Drop", Gems_mode == "drop") then Gems_mode = "drop" end

        ImGui.Separator()
        ImGui.Text("Break Gems Take?")
        if ImGui.RadioButton("Yes", Bgems_take == "yes") then Bgems_take = "yes" end
        ImGui.SameLine()
        if ImGui.RadioButton("No", Bgems_take == "no") then Bgems_take = "no" end

        ImGui.Separator()
        ImGui.Text("Toggle Opsi")
        local d_on = (Disable_player == "on")
        local ig_on = (Ignore_drop == "on")
        local ic_on = (Ignore_completely == "on")
        _, d_on = ImGui.Checkbox("Disable Player", d_on); Disable_player = d_on and "on" or "off"
        _, ig_on = ImGui.Checkbox("Ignore Drop", ig_on); Ignore_drop = ig_on and "on" or "off"
        _, ic_on = ImGui.Checkbox("Ignore Completely", ic_on); Ignore_completely = ic_on and "on" or "off"

        ImGui.Separator()
        ImGui.Text("Advance Settings")
        local ab_on = (autobuyvend == "on")
        _, ab_on = ImGui.Checkbox("Auto Buy Vend", ab_on); autobuyvend = ab_on and "on" or "off"
        _, worldvend = ImGui.InputText("World Vend", worldvend, 32)
        _, aVposX = ImGui.InputInt("Arroz Vend X", aVposX)
        _, aVposY = ImGui.InputInt("Arroz Vend Y", aVposY)
        _, cVposX = ImGui.InputInt("Clover Vend X", cVposX)
        _, cVposY = ImGui.InputInt("Clover Vend Y", cVposY)

        ImGui.Separator()
        _, cvpergems = ImGui.InputInt("CV per Gems", cvpergems)

        ImGui.Separator()
        ImGui.Text("Item IDs")
        _, BackgroundID = ImGui.InputInt("Background ID", BackgroundID)
        _, mpID         = ImGui.InputInt("Magplant ID", mpID)
        _, teleID       = ImGui.InputInt("Telephone ID", teleID)

        ImGui.End()
    end
end)

-- ============ Listener: jika Hub set shouldStop => close UI otomatis ============
RunThread(function()
    local lastStop = _G.shouldStop
    while true do
        if _G.shouldStop and not lastStop then
            -- Hub baru saja mengaktifkan STOP global
            _G.pnbShow = false
        end
        lastStop = _G.shouldStop
        SafeSleep(100)
    end
end)

-- Expose minimal API for Hub / external usage
_G.PNB = _G.PNB or {}
_G.PNB.Start = StartPNB
_G.PNB.Stop  = StopPNB
_G.PNB.Show  = function(v) _G.pnbShow = (v==true) end
_G.PNB.Status = function() return { running = _G.pnbRunning, show = _G.pnbShow, statusText = statusText } end

-- stop check akhir (agar jika script dieksekusi langsung dan Hub meminta stop akan kena)
HubStopCheck()
