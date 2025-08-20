-- ## SC CREATED BY Void_String ## --
-- ## Modified with GUI Start/Stop by ChatGPT ## --

----------------------------------------------------
-- ============ KONFIGURASI DASAR ================ --
----------------------------------------------------
local Posisi_x = 186
local Posisi_y = 196

local Arah_player = "kanan"
local Gems_mode   = "cv"    
local Bgems_take  = "no"

local Disable_player   = "on"
local Ignore_drop      = "on"
local Ignore_completely= "on"

-- ADVANCE
---------------------------------
local autobuyvend = "off"
local worldvend = "off"
local aVposX, aVposY = Posisi_x, Posisi_y
local cVposX, cVposY = Posisi_x, Posisi_y
---------------------------------

local cvpergems = 300000


-- ID
local BackgroundID = 12840
local mpID         = 5638
local teleID       = 3898

----------------------------------------------------
-- ============ STATE & LOG SYSTEM ================ --
----------------------------------------------------
local runningPNB = false
local shouldStop = false
local pnbThread  = nil


----------------------------------------------------
-- ============ SCRIPT BASE ORIGINAL ============== --
----------------------------------------------------

local Tgems, arrozz, cloverr, blackz, blueg, diaml = 0, 0, 0, 0, 0, 0
local cvdl, bgems, gems, lag1, lag2, lag3, cheats, arah, arroz, clover = false, false, nil, 0, 0, 0, false, 32, false, false
local aMP, aMPu = 0, 1
local teleposx, teleposy = nil, nil
local Scans, yok, stp, jtw, prog, findit, ceki, modes, joinworld = true, false, false, false, false, true, true, true, false
local totalElapsed, timeString, M_E_T, Days, cycel_time, stocks = 0, nil, 24 * 60 * 60 * 1000, 0, 0, 0
local world_name = GetWorld().name
local netid = GetLocal().netid

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



function fnd(id)
    count = 0
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
  end
  if Gems_mode == "cv" or Gems_mode == "Cv" then
      gems = 1
      cvdl = true
    elseif Gems_mode == "take" or Gems_mode == "Take" then
      gems = 1
    elseif Gems_mode == "drop" or Gems_mode == "Drop" then
      gems = 0
  end
  if Bgems_take == "yes" or Bgems_take == "Yes" then
      bgems = true
  end
  if Disable_player == "on" or Disable_player == "On" then
      lag1 = 1
  end
  if Ignore_drop == "on" or Ignore_drop == "On" then
      lag2 = 1
  end
  if Ignore_completely == "on" or Ignore_completely == "On" then
      lag3 = 1
  end
end

function wtrmk(msg);LogToConsole("`0[`cPNB`0] **`w " .. msg);end

function overlayText(text);SendVariantList({[0] = "OnTextOverlay", [1] = "`0[`cPNB`0]`w " .. text});end


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
        Sleep(500)
        wJ(world_name)
        else
        overlayText(""..anc.." Discconect?, Wait for reconnect..")
        end
        Sleep(5000)
        MagplantManager.rept = true
end

function sSendPacketRaw(typ, pkt)
  if isErrorDetected() then
    while isErrorDetected() do
      ErrorD("PktRaw")
    end
    joinworld = false
    Sleep(1000)
  end
    SendPacketRaw(typ, pkt)
end

function sSendPacket(typ, pkt)
  if isErrorDetected() then
    while isErrorDetected() do
        ErrorD("Pkt")
    end
    joinworld = false
    Sleep(1000)
  end
    SendPacket(typ, pkt)
end

function sGetPlayerItems()
  if isErrorDetected() then
    while isErrorDetected() do
        ErrorD("GetItems")
    end
    joinworld = false
    Sleep(1000)
  end
  return GetPlayerItems()
end

function sGetPlayerInfo()
  if isErrorDetected() then
    while isErrorDetected() do
        ErrorD("GetItems")
    end
    joinworld = false
    Sleep(1000)
  end
  return GetPlayerInfo()
end

function sGetTile(x, y)
  if isErrorDetected() then
    while isErrorDetected() do
        ErrorD("GetTile")
    end
    joinworld = false
    Sleep(1000)
  end
    return GetTile(x, y)
end

function sGetLocal()
  if isErrorDetected() then
    while isErrorDetected() do
        ErrorD("GetLocal")
    end
    joinworld = false
    Sleep(1000)
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

function server(t, s, v, x, y);sSendPacketRaw(false, {type = t, state = s, value = v, px = x, py = y, x = x * 32, y = y * 32});end

function buyvend(buybrp, posX, posY)
local tile = sGetTile(posX, posY)
if tile and tile.fg == 9268 then
  sSendPacket(2, "action|dialog_return\ndialog_name|vend_edit\nx|"..posX.."|\ny|"..posY.."|\nbuttonClicked|pullstock")
  Sleep(500)
  sSendPacket(2, "action|dialog_return\ndialog_name|vend_buyconfirm\nx|"..posX.."|\ny|"..posY.."|\nbuyamount|"..buybrp.."|\n")
  else
    overlayText("Vending not found")
    addLog("Vending not found")
    
    Sleep(2000)
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
      if y >= 10 and y % 10 == 0 then;Sleep(1);end
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
            Sleep(1000)
            overlayText(string.format("`!Taking the Magplant at (%d, %d)", x, y))
            addLog(string.format("Taking the Magplant at (%d, %d)", x, y))
            server(0, arah, 0, x, y - 1)
            Sleep(1000)
            server(3, 0, 32, x, y)
            Sleep(1000)
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
        if #self.magplants == 0 then 
          self:findMagplants();end
        
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
        Sleep(5000)
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

-- Hook
AddHook("onvariant", "apaiturename", function(var)
    if var[0] == "OnTalkBubble" then
        if var[2]:find("Collected") then
          -- local Curgems = tonumber(var[2]:match("%d+"))
          -- Tgems = Tgems + Curgems
        elseif var[2]:find("You received a MAGPLANT 5000 Remote.") then
            yok = true
        elseif var[2]:find("The MAGPLANT 5000 is empty.") then
            MagplantManager.cmg = true
        end
                
    elseif var[0] == "OnConsoleMessage" then
        if var[1]:find("Your luck has worn off.") then
                    clover = true
                end
        if var[1]:find("Your stomach's rumbling.") then
                  arroz = true
                end
        if var[1]:find("You're luckier than before!") then
          clover = false
        end
        if var[1]:find("chance of a gem") then
           arroz = false
        end
        if var[1]:find("Where would you like to go?") then
          joinworld = true
        end
        if var[1]:find("World Locked") then
            MagplantManager.rept = true
        elseif var[1]:find("returns to normal") or var[1]:find("can't use this command here") then
            MagplantManager.mgh = true
        end
    elseif var[0] == "OnDialogRequest" then
      if var[1]:find("DigiVend") then
        return true
      end
      if var[1]:find("MAGPLANT 5000") then
        local amous = var[1]:match("Stock: `$(%d+)")
        local amou = 0
        if amous == nil then
          amou = 0
        else
          amou = amous
        end
        stocks = amou
        return true
      end
      if var[1]:find("Black Backpack") then
        if var[1]:find("Breaking Gems") then
          arroz = false
        else
          arroz = true
        end
        if var[1]:find("Lucky!") then
          clover = false
        else
          clover = true
        end
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

local tamous, tamous1, tamous2 = 0, 0, 0
function R2delay(cyc1)  
  if tamous2 > cyc1 then
    tamous2 = 0
    return true
  else
    tamous2 = tamous2 + 1
    return false
  end
end
function R1delay(cyc1)  
  if tamous1 > cyc1 then
    tamous1 = 0
    return true
  else
    tamous1 = tamous1 + 1
    return false
  end
end
function Rdelay(cyc)  
  if tamous > cyc then
    tamous = 0
    return true
  else
    tamous = tamous + 1
    return false
  end
end

function telefind()
    local savecorx196 = Posisi_x - 196
    local savecory196 = Posisi_y - 196
    local hasilsy = 3
    local hasiley = 3
    local hasilsx = 3
    local hasilex = 3

  if Posisi_y < 3  then
    hasilsy = Posisi_y
  elseif Posisi_y > 196 then
    if savecory196 == 1 then
      savecory196 = 2
    elseif savecory196 == 2 then
      savecory196 = 1
    elseif savecory196 == 3 then
      savecory196 = 0
    end
    hasiley = savecory196
  end
  if Posisi_x < 3  then
    hasilsx = Posisi_x
  elseif Posisi_x > 196 then
    if savecorx196 == 1 then
      savecorx196 = 2
    elseif savecorx196 == 2 then
      savecorx196 = 1
    elseif savecorx196 == 3 then
      savecorx196 = 0
    end
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
                Sleep(5)
                foundit = false
                teleposx = x
                teleposy = y
            end
        end
    end
    if foundit then
      overlayText("`4Telephone not found")
      addLog("Telephone not found")
      Sleep(100)
    else
      overlayText("`5Telephone found at: X "..teleposx.." Y "..teleposy)
      addLog("Telephone found at: X "..teleposx.." Y "..teleposy)
      Sleep(100)
    end
end


    



GetData();Sleep(100)
sycroneC();Sleep(100)
telefind()
cheat(false);Sleep(5000)
cheats = true
sSendPacket(2, "action|input\n|text|/ghost");Sleep(1000)
if MagplantManager.mgh then
        sSendPacket(2, "action|input\n|text|/ghost")
        MagplantManager.mgh = false
        Sleep(1000)
        FindPath(Posisi_x, Posisi_y, 700)
else 
  FindPath(Posisi_x, Posisi_y, 700)
end
sSendPacket(2, "action|wrench\n|netid|"..netid);Sleep(200)
function pnbmain()
    StopCheck()
  if MagplantManager.rept or not yok then
        if not cheats then
        cheat(false);Sleep(1000)
        cheats = true
        end
        Sleep(200)
        MagplantManager:resetAndUpdate()
        MagplantManager:retake()
        MagplantManager.magplantTaken = false
        wtrmk("Inside stocks: "..stocks)
        addLog("inside stocks: "..stocks)
    elseif MagplantManager.cmg then
        if not cheats then
        cheat(false);Sleep(1000)
        cheats = true
        end
        aMPu = aMPu + 1
        Sleep(200)
        MagplantManager:resetAndUpdate()
        MagplantManager:takeMagplant()
        overlayText("Inside stocks: `2"..stocks.."`0. `5Magplant: ("..aMPu.."/"..aMP..")")
        addLog("Inside stocks: "..stocks..". Magplant: ("..aMPu.."/"..aMP..")")
     end
    if MagplantManager.mgh then
        Sleep(1000)
        sSendPacket(2, "action|input\n|text|/ghost")
        MagplantManager.mgh = false
    end
  
    if stocks == 0 then;Sleep(200);MagplantManager.cmg=true;return;end
    
    if cheats then
      local apunch = nil
      if arah == 48 then
        apunch = Posisi_x - 1
      else
        apunch = Posisi_x + 1
      end
      
        server(nil, nil, nil, Posisi_x, Posisi_y)
        server(0, arah, 0, Posisi_x, Posisi_y)
        Sleep(100)
        server(3, 0, 18, apunch, Posisi_y)
        server(0, arah, 0, Posisi_x, Posisi_y)
        Sleep(100)
        if not yok then;return;end
        cheat(true)
        Sleep(1000)
        cheats = false
    end
  
  if Rdelay(5) then
    if cvdl then
      local sTgems = sGetPlayerItems().gems
      if sTgems > cvpergems then
      sSendPacket(2,"action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|".. teleposx .."|\ny|".. teleposy .."|\nbuttonClicked|dlconvert")
      Sleep(100)
        
        if diaml > 99 then
        sSendPacket(2,"action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|".. teleposx .."|\ny|".. teleposy .."|\nbuttonClicked|bglconvert")
        Sleep(100)

        elseif blueg > 99 then
          sSendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bgl")
          Sleep(100)
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
        addLog("Arroz is empty")
      if worldvend ~= "off" then
        wJ(worldvend)
        Sleep(15000)
      end
        if not cheats then
          cheat(false);Sleep(1000)
          cheats = true
        end
        overlayText("Buying arroz at: `5X "..aVposX.." Y "..aVposY)
        addLog("Buying arroz at: X "..aVposX.." Y "..aVposY)
        server(nil, nil, nil, aVposX, aVposY)
        server(3, arah, 32, aVposX, aVposY)
        Sleep(1000)
        buyvend(250, aVposX, aVposY)
        Sleep(1000)
        if worldvend ~= "off" then
        wJ(world_name)
        Sleep(15000)
      end
      end
      if cloverr < 1 then
        overlayText("clover is empty")
        addLog("clover is empty")
        if worldvend ~= "off" then
          wJ(worldvend)
          Sleep(15000)
        end
        if not cheats then
          cheat(false);Sleep(1000)
          cheats = true
        end
        overlayText("Buying clover at: `5X "..cVposX.." Y "..cVposY)
        addLog("Buying clover at: X "..cVposX.." Y "..cVposY)
        server(nil, nil, nil, cVposX, cVposY)
        server(3, arah, 32, cVposX, cVposY)
        Sleep(1000)
        buyvend(250, cVposX, cVposY)
        Sleep(1000)
        if worldvend ~= "off" then
        wJ(world_name)
        Sleep(15000)
      end
      end
    end
    overlayText("`5Magplant: "..aMPu.."/"..aMP..". `9Arroz`0/`2Clover`0(`9"..arrozz.."`0|`2"..cloverr.."`0). `5[`s"..blackz.."Black`0|`e"..blueg.."bgl`0|`1"..diaml.."dl`5]")
    addLog("Magplant: "..aMPu.."/"..aMP..". Arroz/Clover("..arrozz.."|"..cloverr.."). ["..blackz.."Black|"..blueg.."bgl|"..diaml.."dl]")
  end
  
  if R2delay(50) then
    GetData()
  end
  
  if arroz then
    Sleep(700);server(3, 0, 4604, Posisi_x, Posisi_y);Sleep(900)
        end
  if clover then
     Sleep(700);server(3, 0, 528, Posisi_x, Posisi_y);Sleep(900)
        end
  
end



function pnbstart()
  while not shouldStop do
    pnbmain()
    Sleep(100)
  end
         addLog("⛔ STOP dikirim + cheat OFF.")
    
end

----------------------------------------------------
-- ============ START & STOP WRAPPER ============== --
----------------------------------------------------
local function StartPNB()
    if runningPNB then
        addLog("Sudah berjalan.")
        return
    end
    runningPNB = true
    shouldStop = false
    pnbThread = RunThread(pnbstart)
    addLog("▶ Mulai PNB di world " .. world_name)

end

local function StopPNB()
    if not runningPNB then
    cheat(false)
        addLog("Tidak ada PNB berjalan.")
        return
    end
    shouldStop = true
    runningPNB = false
    cheat(false)
end

----------------------------------------------------
-- ============ GUI (IMGUI PANEL) ================= --
----------------------------------------------------
AddHook("OnDraw", "PNB_GUI", function()
    if ImGui.Begin("PNB Controller") then
        ImGui.Text("🌍 World & Position Settings")
        _, world_name = ImGui.InputText("World", world_name or "", 32)
        _, Posisi_x = ImGui.InputInt("PNB X", Posisi_x)
        _, Posisi_y = ImGui.InputInt("PNB Y", Posisi_y)

        ImGui.SameLine()
        if ImGui.Button("📍 Set From Player") then
            local me, w = GetLocal(), GetWorld()
            if me and w then
                Posisi_x, Posisi_y = me.pos.x // 32, me.pos.y // 32
                world_name = w.name
                addLog("Posisi diset dari player: ("..Posisi_x..","..Posisi_y..") @"..world_name)
            else
                addLog("Gagal set posisi (belum di world?)")
            end
        end

        ImGui.Separator()
        if not runningPNB then
            if ImGui.Button("▶ Start PNB") then StartPNB() end
        else
            if ImGui.Button("⏹ Stop PNB") then StopPNB() end
        end
ImGui.Text("Status: " .. (runningPNB and ("Running @" .. (world_name)) or "Idle"))

        ImGui.Separator()
        ImGui.End()
    end
end)
