----------------------------------------------------
-- ============ KONFIGURASI DASAR ================ --
----------------------------------------------------
local Posisi_x = 186
local Posisi_y = 196

local Arah_player = "kanan"
local Gems_mode   = "cv"      -- "cv" / "take" / "drop"
local Bgems_take  = "no"      -- "yes" / "no"

local Disable_player    = "on" -- "on"/"off"
local Ignore_drop       = "on" -- "on"/"off"
local Ignore_completely = "on" -- "on"/"off"

-- ADVANCE
local autobuyvend = "off"  -- "on"/"off"
local worldvend   = "off"  -- "off" atau nama world
local aVposX, aVposY = Posisi_x, Posisi_y
local cVposX, cVposY = Posisi_x, Posisi_y

local cvpergems = 300000

-- ID
local BackgroundID = 12840
local mpID         = 5638
local teleID       = 3898

----------------------------------------------------
-- ============ GLOBAL FLAGS (HUB-SHARED) ========= --
----------------------------------------------------
_G.shouldStop      = _G.shouldStop or false
_G.hubForceCloseUI = _G.hubForceCloseUI or false
_G.pnbShow    = (_G.pnbShow ~= nil) and _G.pnbShow or true
_G.pnbRunning = _G.pnbRunning or false

if not _G.ScriptBus then
  _G.ScriptBus = {
    _map = {},
    register = function(self, name, handlers) self._map[name] = handlers end,
    stop_all = function(self)
      for _, h in pairs(self._map) do if h and h.stop     then pcall(h.stop, true) end end
    end,
    close_all_ui = function(self)
      for _, h in pairs(self._map) do if h and h.close_ui then pcall(h.close_ui) end end
    end
  }
end

----------------------------------------------------
-- ============ STATE & LOG SYSTEM ================ --
----------------------------------------------------
local pnbThread  = nil
local statusText = "Idle"

local function wtrmk(msg) LogToConsole("`0[`cPNB`0] **`w " .. tostring(msg)) end
local function addLog(msg) LogToConsole("`0[`cPNB`0] `7" .. tostring(msg)) end
local function overlayText(text) SendVariantList({[0]="OnTextOverlay",[1]="`0[`cPNB`0]`w "..text}) end

----------------------------------------------------
-- ============ RUNTIME CONTEXT =================== --
----------------------------------------------------
local Tgems, arrozz, cloverr, blackz, blueg, diaml = 0, 0, 0, 0, 0, 0
local cvdl, bgems, gems, lag1, lag2, lag3, cheats, arah, arroz, clover = false, false, nil, 0, 0, 0, false, 32, false, false
local aMP, aMPu = 0, 1
local teleposx, teleposy = nil, nil
local yok = false
local stocks = 0

local world_name = ""  -- akan diisi saat StartPNB()
local netid      = 0
local joinworld  = false

----------------------------------------------------
-- ============ AUTO REJOIN SIMPLE  =============== --
----------------------------------------------------
local function wJ(world_name12)
  SendPacket(3, "action|join_request\nname|" .. world_name12)
end

local function autoRejoin()
  if world_name == nil or world_name == "" then return end
  local ok, wr = pcall(GetWorld)
  if not ok or type(wr) ~= "table" then
    overlayText("`4[Rejoin] World context invalid, rejoin `"..world_name.."`")
    Sleep(1500)
    wJ(world_name)
    Sleep(3000)
    return
  end
  local cur = wr.name or ""
  if cur == nil or cur == "" then
    overlayText("`4[Rejoin] Detected out of world, rejoining `"..world_name.."` ...")
    Sleep(1500)
    wJ(world_name)
    Sleep(3000)
  elseif cur ~= world_name then
    overlayText("`e[Warning] You are in `"..cur.."`, expected `"..world_name.."`. Rejoining...")
    Sleep(1500)
    wJ(world_name)
    Sleep(3000)
  end
end

----------------------------------------------------
-- ============ SAFE WRAPPERS ===================== --
----------------------------------------------------
local function isErrorDetected()
  local ok, res = pcall(GetLocal)
  return (not ok) or (type(res) ~= "table")
end

local function ErrorD(tagmsg)
  overlayText("`8"..tagmsg.."`7: reconnect check...")
  autoRejoin()
  Sleep(2000)
end

local function sSendPacketRaw(typ, pkt)
  if isErrorDetected() then
    while isErrorDetected() do ErrorD("PktRaw") end
    joinworld = false; Sleep(300)
  end
  SendPacketRaw(typ, pkt)
end

local function sSendPacket(typ, pkt)
  if isErrorDetected() then
    while isErrorDetected() do ErrorD("Pkt") end
    joinworld = false; Sleep(300)
  end
  SendPacket(typ, pkt)
end

local function sGetPlayerItems()
  if isErrorDetected() then
    while isErrorDetected() do ErrorD("GetItems") end
    joinworld = false; Sleep(300)
  end
  return GetPlayerItems()
end

local function sGetPlayerInfo()
  if isErrorDetected() then
    while isErrorDetected() do ErrorD("GetPlayerInfo") end
    joinworld = false; Sleep(300)
  end
  return GetPlayerInfo()
end

local function sGetTile(x, y)
  if isErrorDetected() then
    while isErrorDetected() do ErrorD("GetTile") end
    joinworld = false; Sleep(300)
  end
  return GetTile(x, y)
end

local function sGetLocal()
  if isErrorDetected() then
    while isErrorDetected() do ErrorD("GetLocal") end
    joinworld = false; Sleep(300)
  end
  return GetLocal()
end

----------------------------------------------------
-- StopCheck: Api Hub Stop Script
----------------------------------------------------
local function StopCheck()
  if _G.StopCheck then
    _G.StopCheck()
  else
    if _G.shouldStop then error("STOP_REQUESTED") end
  end
end

----------------------------------------------------
-- ============ UTIL & SYNC CONF ================= --
----------------------------------------------------
local function fnd(id)
  local count = 0
  for _, inv in pairs(GetInventory()) do
    if inv.id == id then count = count + inv.amount end
  end
  return count
end

local function sycroneC()
  arah = 32
  if Arah_player == "kiri" or Arah_player == "Kiri" then
    arah = 48
  end
  if Gems_mode == "cv" or Gems_mode == "Cv" then
    gems = 1; cvdl = true
  elseif Gems_mode == "take" or Gems_mode == "Take" then
    gems = 1; cvdl = false
  elseif Gems_mode == "drop" or Gems_mode == "Drop" then
    gems = 0; cvdl = false
  end
  bgems = (Bgems_take == "yes" or Bgems_take == "Yes")

  lag1 = (Disable_player    == "on" or Disable_player    == "On") and 1 or 0
  lag2 = (Ignore_drop       == "on" or Ignore_drop       == "On") and 1 or 0
  lag3 = (Ignore_completely == "on" or Ignore_completely == "On") and 1 or 0
end

local function GetData()
  arrozz = fnd(4604)
  cloverr = fnd(528)
  blackz  = fnd(11550)
  blueg   = fnd(7188)
  diaml   = fnd(1796)
end

local function server(t, s, v, x, y)
  sSendPacketRaw(false, {type=t, state=s, value=v, px=x, py=y, x=x*32, y=y*32})
end

local function buyvend(buybrp, posX, posY)
  local tile = sGetTile(posX, posY)
  if tile and tile.fg == 9268 then
    sSendPacket(2, "action|dialog_return\ndialog_name|vend_edit\nx|"..posX.."|\ny|"..posY.."|\nbuttonClicked|pullstock")
    Sleep(500)
    sSendPacket(2, "action|dialog_return\ndialog_name|vend_buyconfirm\nx|"..posX.."|\ny|"..posY.."|\nbuyamount|"..buybrp.."|\n")
  else
    overlayText("`4Vending not found @("..posX..","..posY..")")
    addLog("Vending not found")
    Sleep(800)
  end
end

local function cheat(auto)
  sSendPacket(2, "action|dialog_return\n" ..
    "dialog_name|cheats\n" ..
    "check_autofarm|"..auto.."\n" ..
    "check_bfg|"..auto.."\n" ..
    "check_antibounce|"..auto.."\n" ..
    "check_lonely|" .. lag1 .. "\n" ..
    "check_gems|" .. gems .. "\n" ..
    "check_ignoreo|" .. lag2 .. "\n" ..
    "check_ignoref|" .. lag3)
end

----------------------------------------------------
-- ============ MAGPLANT MANAGER ================= --
----------------------------------------------------
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

local function isPositionExists(list, x, y)
  for _, pos in ipairs(list) do
    if pos[1] == x and pos[2] == y then return true end
  end
  return false
end

function MagplantManager:findMagplants()
  self.magplants = {}; aMP = 0
  for y = 199, 0, -1 do
    if y >= 10 and y % 10 == 0 then Sleep(1) end
    for x = 199, 0, -1 do
      local tile = sGetTile(x, y)
      if tile and tile.bg == BackgroundID and tile.fg == mpID and not isPositionExists(self.magplants, x, y) then
        Sleep(5)
        table.insert(self.magplants, {x, y})
        aMP = aMP + 1
      end
    end
  end
end

function MagplantManager:takeMagplant()
  if self.mgh then
    Sleep(900)
    sSendPacket(2, "action|input\n|text|/ghost")
    self.mgh = false
  end

  if not self.magplantTaken then
    if #self.magplants == 0 then self:findMagplants() end

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
      Sleep(300)
      overlayText(string.format("`!Taking the Magplant at (%d, %d)", x, y))
      addLog(string.format("Taking the Magplant at (%d, %d)", x, y))
      server(0, arah, 0, x, y - 1)
      Sleep(400)
      server(3, 0, 32, x, y)
      Sleep(400)
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
      addLog("No Magplants found!")
    end
  end
end

function MagplantManager:resetAndUpdate()
  if #self.magplants == 0 and #self.takenMagplants > 0 then
    wtrmk("`bAll Magplants taken, resetting list...")
    addLog("All Magplants taken, resetting list...")
    self.takenMagplants = {}
    self:findMagplants()
    self.magplantTaken = false
    aMPu = 1
  end

  if #self.magplants == 0 and #self.takenMagplants > 0 then
    wtrmk("`bAll Magplants are taken, waiting for new Magplants to be placed.")
    addLog("All Magplants are taken, waiting for new Magplants to be placed.")
    Sleep(2000)
    self:findMagplants()
  end

  if self.cmg then
    wtrmk("Oops! Magplant is empty! Let's go to the next Magplant!")
    addLog("Oops! Magplant is empty! Let's go to the next Magplant!")
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

----------------------------------------------------
-- ============ VARIANT HOOK ====================== --
----------------------------------------------------
AddHook("onvariant", "PNB_variant", function(var)
  if var[0] == "OnTalkBubble" then
    if var[2]:find("You received a MAGPLANT 5000 Remote.") then
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
    if var[1]:find("World Locked") then
      MagplantManager.rept = true
    elseif var[1]:find("returns to normal") or var[1]:find("can't use this command here") then
      MagplantManager.mgh = true
    end

  elseif var[0] == "OnDialogRequest" then
    if var[1]:find("DigiVend") then return true end
    if var[1]:find("MAGPLANT 5000") then
      local amous = var[1]:match("Stock: `$(%d+)")
      stocks = amous and tonumber(amous) or 0
      return true
    end
    if var[1]:find("Black Backpack") then
      if var[1]:find("Breaking Gems") then arroz = false else arroz = true end
      if var[1]:find("Lucky!") then clover = false else clover = true end
      return true
    elseif var[1]:find("cheat") then
      return true
    elseif var[1]:find("telephone") then
      return true
    end

  elseif var[0] == "OnSDBroadcast" then
    return true
  end
  return false
end)

----------------------------------------------------
-- ============ DELAY HELPERS ===================== --
----------------------------------------------------
local tamous, tamous1, tamous2 = 0, 0, 0
local function R2delay(cyc1)
  if tamous2 > cyc1 then tamous2 = 0; return true else tamous2 = tamous2 + 1; return false end
end
local function R1delay(cyc1)
  if tamous1 > cyc1 then tamous1 = 0; return true else tamous1 = tamous1 + 1; return false end
end
local function Rdelay(cyc)
  if tamous > cyc then tamous = 0; return true else tamous = tamous + 1; return false end
end

----------------------------------------------------
-- ============ TELEPHONE FIND ==================== --
----------------------------------------------------
local function telefind()
  local savecorx196 = Posisi_x - 196
  local savecory196 = Posisi_y - 196
  local hasilsy, hasiley = 3, 3
  local hasilsx, hasilex = 3, 3

  if Posisi_y < 3  then
    hasilsy = Posisi_y
  elseif Posisi_y > 196 then
    if savecory196 == 1 then savecory196 = 2
    elseif savecory196 == 2 then savecory196 = 1
    elseif savecory196 == 3 then savecory196 = 0 end
    hasiley = savecory196
  end

  if Posisi_x < 3  then
    hasilsx = Posisi_x
  elseif Posisi_x > 196 then
    if savecorx196 == 1 then savecorx196 = 2
    elseif savecorx196 == 2 then savecorx196 = 1
    elseif savecorx196 == 3 then savecorx196 = 0 end
    hasilex = savecorx196
  end

  local startY = Posisi_y - hasilsy
  local endY   = Posisi_y + hasiley
  local startX = Posisi_x - hasilsx
  local endX   = Posisi_x + hasilex
  local foundit = true

  for y = startY, endY do
    for x = startX, endX do
      local tile = sGetTile(x, y)
      if tile and tile.fg == teleID then
        Sleep(5)
        foundit = false; teleposx = x; teleposy = y
      end
    end
  end

  if foundit then
    overlayText("`4Telephone not found")
    addLog("Telephone not found near pos")
  else
    overlayText("`5Telephone found at: X "..teleposx.." Y "..teleposy)
    addLog("Telephone found at: X "..teleposx.." Y "..teleposy)
  end
  Sleep(80)
end

----------------------------------------------------
-- ============ PNB MAIN LOOP ===================== --
----------------------------------------------------
local function pnbmain()
  StopCheck()
  autoRejoin()

  if MagplantManager.rept or not yok then
    if not cheats then cheat(0); Sleep(400); cheats = true end
    Sleep(100)
    MagplantManager:resetAndUpdate()
    MagplantManager:retake()
    MagplantManager.magplantTaken = false
    wtrmk("inside stocks: "..tostring(stocks)); addLog("inside stocks: "..tostring(stocks))

  elseif MagplantManager.cmg then
    if not cheats then cheat(0); Sleep(400); cheats = true end
    aMPu = aMPu + 1
    Sleep(100)
    MagplantManager:resetAndUpdate()
    MagplantManager:takeMagplant()
    overlayText("inside stocks: `2"..tostring(stocks).."`0. `5Magplant: ("..aMPu.."/"..aMP..")")
    addLog("Inside stocks: "..tostring(stocks)..". Magplant: ("..aMPu.."/"..aMP..")")
  end

  if MagplantManager.mgh then
    Sleep(600)
    sSendPacket(2, "action|input\n|text|/ghost")
    MagplantManager.mgh = false
  end

  if stocks == 0 then Sleep(120); MagplantManager.cmg = true; return end

  if cheats then
    local apunch = (arah == 48) and (Posisi_x - 1) or (Posisi_x + 1)
    server(nil, nil, nil, Posisi_x, Posisi_y)
    server(0, arah, 0, Posisi_x, Posisi_y)
    Sleep(60)
    server(3, 0, 18, apunch, Posisi_y)
    server(0, arah, 0, Posisi_x, Posisi_y)
    Sleep(60)
    if not yok then return end
    cheat(1)
    Sleep(300)
    cheats = false
  end

  if Rdelay(5) then
    if cvdl then
      local sTgems = sGetPlayerItems().gems
      if sTgems > cvpergems and teleposx and teleposy then
        sSendPacket(2,"action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|".. teleposx .."|\ny|".. teleposy .."|\nbuttonClicked|dlconvert")
        Sleep(50)
        if diaml > 99 then
          sSendPacket(2,"action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|".. teleposx .."|\ny|".. teleposy .."|\nbuttonClicked|bglconvert")
          Sleep(50)
        elseif blueg > 99 then
          sSendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bgl")
          Sleep(50)
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
        overlayText("Arroz is empty"); addLog("Arroz is empty")
        if worldvend ~= "off" then wJ(worldvend); Sleep(4000) end
        if not cheats then cheat(0); Sleep(300); cheats = true end
        overlayText("Buying arroz @ `5("..aVposX..","..aVposY..")")
        server(nil, nil, nil, aVposX, aVposY)
        server(3, arah, 32, aVposX, aVposY); Sleep(300)
        buyvend(250, aVposX, aVposY); Sleep(300)
        if worldvend ~= "off" then wJ(world_name); Sleep(4000) end
      end
      if cloverr < 1 then
        overlayText("Clover is empty"); addLog("Clover is empty")
        if worldvend ~= "off" then wJ(worldvend); Sleep(4000) end
        if not cheats then cheat(0); Sleep(300); cheats = true end
        overlayText("Buying clover @ `5("..cVposX..","..cVposY..")")
        server(nil, nil, nil, cVposX, cVposY)
        server(3, arah, 32, cVposX, cVposY); Sleep(300)
        buyvend(250, cVposX, cVposY); Sleep(300)
        if worldvend ~= "off" then wJ(world_name); Sleep(4000) end
      end
    end
    overlayText("`5Magplant: "..aMPu.."/"..aMP..". `9Arroz`0/`2Clover`0(`9"..arrozz.."`0|`2"..cloverr.."`0). `5[`s"..blackz.."Black`0|`e"..blueg.."bgl`0|`1"..diaml.."dl`5]")
    addLog("Magplant: "..aMPu.."/"..aMP..". Arroz/Clover("..arrozz.."|"..cloverr.."). ["..blackz.."Black|"..blueg.."bgl|"..diaml.."dl]")
  end

  if R2delay(50) then
    GetData()
  end

  if arroz then Sleep(300); server(3, 0, 4604, Posisi_x, Posisi_y); Sleep(300) end
  if clover then Sleep(300); server(3, 0, 528,  Posisi_x, Posisi_y); Sleep(300) end
end

----------------------------------------------------
-- ============ START & STOP WRAPPER ============== --
----------------------------------------------------
function StartPNB()
  if _G.pnbRunning then addLog("⚠ PNB sudah berjalan."); return end
  if _G.shouldStop then addLog("Tidak bisa start, HUB sedang STOP mode."); return end

  -- Sync runtime context aman
  local loc = sGetLocal()
  local wr  = GetWorld()
  world_name = (wr and wr.name) or world_name or ""
  netid      = (loc and loc.netid) or 0

  GetData(); Sleep(50)
  sycroneC(); Sleep(50)
  telefind()
  cheat(0); Sleep(200)
  cheats = true

  sSendPacket(2, "action|input\n|text|/ghost"); Sleep(300)
  if MagplantManager.mgh then
    sSendPacket(2, "action|input\n|text|/ghost")
    MagplantManager.mgh = false
    Sleep(200)
    FindPath(Posisi_x, Posisi_y, 700)
  else
    FindPath(Posisi_x, Posisi_y, 700)
  end

  sSendPacket(2, "action|wrench\n|netid|"..tostring(netid)); Sleep(300)

  _G.pnbRunning = true
  _G.pnbShow    = true
  statusText    = "Running..."

  -- Main loop thread
  pnbThread = RunThread(function()
    local ok, err = pcall(function()
      while _G.pnbRunning do
        StopCheck()
        pnbmain()
        Sleep(100)
      end
    end)
    _G.pnbRunning = false
    statusText = "Idle"
    if _G.shouldStop or _G.hubForceCloseUI then _G.pnbShow = false end
    if not ok then
      if tostring(err):find("STOP_REQUESTED") then
        addLog("✅ PNB dihentikan.")
      else
        addLog("❌ Error: " .. tostring(err))
      end
    end
    pnbThread = nil
  end)

  -- AutoRejoin watchdog
  RunThread(function()
    while _G.pnbRunning do
      autoRejoin()
      Sleep(1500)
    end
  end)

  addLog("▶ Mulai PNB di world " .. tostring(world_name))
end

function StopPNB()
  if not _G.pnbRunning then addLog("Tidak ada PNB yang berjalan."); return end
  statusText = "Stopping..."
  _G.pnbRunning = false
  pcall(function() cheat(0) end)
end

function ClosePNB()
  _G.pnbRunning = false
  _G.pnbShow    = false
  pcall(function() cheat(0) end)
  addLog("❌ PNB + GUI ditutup.")
end

------------------------------------------------------------
-- Handler untuk HUB (Stop semua / Close UI semua)
------------------------------------------------------------
local function HubStopHandler(forceClose)
  if _G.pnbRunning then statusText = "Stopping..." end
  _G.shouldStop = true
  _G.pnbRunning = false
  pcall(function() cheat(0) end)
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

----------------------------------------------------
-- ==================== GUI ======================= --
----------------------------------------------------
local HOOK_NAME = "PNB_GUI_Controller"
AddHook("OnDraw", HOOK_NAME, function()
  if _G.hubForceCloseUI then return end
  if not _G.pnbShow then return end

  if ImGui.Begin("PNB Controller", true, ImGuiWindowFlags_AlwaysAutoResize) then
    if ImGui.BeginTabBar("PNB_TabBar") then
      -- TAB MAIN
      if ImGui.BeginTabItem("Main Settings") then
        ImGui.Text("Pengaturan PNB")
        if not _G.pnbRunning then
          if ImGui.Button("▶ Start PNB") then RunThread(StartPNB) end
          ImGui.SameLine()
          if ImGui.Button("Tutup GUI") then ClosePNB() end
        else
          if ImGui.Button("⏹ Stop PNB ") then StopPNB() end
          ImGui.SameLine()
          ImGui.BeginDisabled(true); ImGui.Button("Tutup GUI"); ImGui.EndDisabled()
        end

        ImGui.Separator()
        if ImGui.Button("✅ Apply Settings") then sycroneC(); addLog("🔄 Settingan diperbarui dari GUI") end
        ImGui.SameLine()
        _, world_name = ImGui.InputText("World", world_name, 24)

        ImGui.Separator()
        ImGui.Text("Toggle Opsi:")
        local chk
        chk, Disable_player    = ImGui.Checkbox("Disable Player", Disable_player == "on")
        Disable_player = chk and "on" or "off"
        chk, Ignore_drop       = ImGui.Checkbox("Ignore Drop", Ignore_drop == "on")
        Ignore_drop = chk and "on" or "off"
        chk, Ignore_completely = ImGui.Checkbox("Ignore Completely", Ignore_completely == "on")
        Ignore_completely = chk and "on" or "off"

        ImGui.Separator()
        if ImGui.Button("🔍 Refind Telephone") then telefind() end
        ImGui.SameLine()
        if ImGui.Button("♻ Force AutoRejoin") then autoRejoin() end

        ImGui.Separator()
        ImGui.Text("Status: " .. (_G.pnbRunning and ("Running @"..world_name) or "Idle"))
        ImGui.EndTabItem()
      end

      -- TAB SETTINGS
      if ImGui.BeginTabItem("Settings") then
        ImGui.Text("🌍 World & Position Settings")
        ImGui.Separator()
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
        ImGui.Text("Advance Settings")
        local b
        b, autobuyvend = ImGui.Checkbox("Auto Buy Vend", autobuyvend == "on")
        autobuyvend = b and "on" or "off"
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

        ImGui.EndTabItem()
      end

      ImGui.EndTabBar()
    end
    ImGui.End()
  end
end)

------------------------------------------------------------
-- ============ Listener HUB STOP (auto close UI) =========
------------------------------------------------------------
RunThread(function()
  local lastStop = _G.shouldStop
  while true do
    if _G.shouldStop and not lastStop then
      _G.pnbShow = false
    end
    lastStop = _G.shouldStop
    Sleep(100)
  end
end)
