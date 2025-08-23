--[[ Remake doctor, fuck off moron ]]--

------------------------------------------------------------
--  KONFIGURASI
------------------------------------------------------------
Customize = {
  TreeID = 15757,
  Start = {
    Mode = "PTHT",
    Loop = 2,                     -- bisa number atau "unli"
    PosX = 0,
    PosY = GetLocal().pos.y // 32,
  },
  Delay = {
    Harvest  = 50,
    entering = 50,
    Plant    = 10,
  },
  Other = {
    Mray      = true,
    WebHooks  = "",
    DiscordID = "",
    ModePlant = "right",          -- "left" / "right"
  },
  Magplant = {
    Limit = 200,
    bcg   = 1158
  },
}

------------------------------------------------------------
--  STATE & UTIL
------------------------------------------------------------
local function WorldName()
  local w = GetWorld()
  return w and string.upper(w.name) or ""
end

local GrowID = GetLocal().name
local World  = WorldName()

-- Supervisor flags: kooperasi dgn HUB
local pt_alive    = true       -- thread supervisor hidup
local pt_running  = false      -- status farming berjalan
local ui_visible  = true       -- status GUI
_G.shouldStop     = _G.shouldStop or false  -- sinyal global dari HUB

-- counter/aset
local PTHT      = 0
local Limiter   = 200
local Current   = 1
local iM        = 0
local RemoteEmpty, Plant, Harvest = true, true, false

-- helper patuh HUB
local function ShouldStop()
  if _G.shouldStop then return true end
  
  if type(StopCheck) == "function" then
    local ok = pcall(StopCheck)
    if not ok then return true end
  end
  return false
end

local function SleepSafe(ms)
  local chunk = 50
  local left = ms
  while left > 0 do
    if ShouldStop() then return false end
    Sleep(math.min(chunk, left))
    left = left - chunk
  end
  return true
end

local function TextO(x)
  SendVariantList{[0] = "OnTextOverlay", [1] = x}
  LogToConsole(x)
end

local function Raw(H, I, J, K, L)
  SendPacketRaw(false, {
    type = H, state = I, value = J,
    px = K, py = L, x = K * 32, y = L * 32,
  })
end

------------------------------------------------------------
--  HOOK MAGPLANT STOCK
------------------------------------------------------------
AddHook("OnVariant", "PTHT_convert", function(vS)
  if vS[0]:find("OnDialogRequest") then
    if vS[1]:find("|15159|") then
      local vP = tonumber(vS[1]:match("Stock: `$(%d+)"))
      if vP then iM = vP end
    end
    return true
  end
  return false
end)

------------------------------------------------------------
--  FUNGSI ASLI
------------------------------------------------------------
local function iv(id)
  for _, it in pairs(GetInventory()) do
    if it.id == id then return it.amount end
  end
  return 0
end

local TotalTree = 0
function IsReady(tile)
    if tile and tile.extra and tile.extra.progress and tile.extra.progress == 1 then
        return true
    end
    return false
end

local function siz(str) -- Credit AsleepDream
  str = str:gsub("Dr%.", "")
  str = str:gsub("``", ""):gsub("`.", ""):gsub("@", ""):gsub(" of Legend", "")
  str = str:gsub("%[BOOST%]", ""):gsub("%[ELITE%]", ""):gsub("`w", "")
  return str
end

local function GetMagplant()
  local Found = {}
  for x = 0, 199 do
    for y = 0, 199 do
      local t = GetTile(x, y)
      if t.fg == 5638 and t.bg == Customize.Magplant.bcg then
        table.insert(Found, {x, y})
      end
    end
  end
  return Found
end

local TotalTree = 0
function GetTree(str)
    if str == a then
        local Total = 0
        for y = Customize.Start.PosY + 1, Customize.Start.PosY % 2 == 0 and 0 or 1, -2 do
            for x = Customize.Start.PosX, 199, 1 do
                if GetTile(x, y).fg ~= Customize.TreeID then
                    Total = Total + 1
                end
            end
        end
        return Total
    else
        for y = Customize.Start.PosY, Customize.Start.PosY % 2 == 0 and 0 or 1, -2 do
            for x = Customize.Start.PosX, 199, 1 do
                local tile = GetTile(x, y)
                if (Plant and tile.fg == Customize.TreeID) or (Harvest and tile.fg == Customize.TreeID and IsReady(tile)) then
                    TotalTree = TotalTree + 1
                end
            end
        end
        return TotalTree
    end
end

local function SendWebhook(url, data)
  MakeRequest(url, "POST", { ["Content-Type"] = "application/json" }, data)
end

local function GetRemote()
  local Magplant = GetMagplant()
  if #Magplant > 0 then
    Raw(0, 32, 0, Magplant[Current][1], Magplant[Current][2])
    if not SleepSafe(500) then return end
    Raw(3,  0, 32, Magplant[Current][1], Magplant[Current][2])
    if not SleepSafe(500) then return end
    SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|"..Magplant[Current][1].."|\ny|"..Magplant[Current][2].."|\nbuttonClicked|getRemote")
    SleepSafe(5000)
  else
    RemoteEmpty = true
  end
end

------------------------------------------------------------
--  MODE SWITCH
------------------------------------------------------------
local UWSUsed = 0
function ChangeMode()
if Customize.Start.Mode:upper() == "PT" then
        TextO("`4[`wDoctor`4] `0Mode: `2PLANT ONLY")
        Plant = true
        Harvest = false
        return
    end

       if Plant then
           Plant = false
           if GetTree("b") >= GetTree("a") then
               UWSUsed = UWSUsed + 1
               TextO("`oTotal `2Used `c" .. UWSUsed .. " UWS")
               SendPacket(2, "action|dialog_return\ndialog_name|ultraworldspray")
               Sleep(5600)
               TextO("`4[`wDoctor`4] Harvest `0Mode")
               Harvest = true
           else
               TextO("`9Scanning `4Missing `0Plant")
               Plant = true
           end
           TotalTree = 0
       else
           Harvest = false
           if GetTree("a") >= GetTree("b") then
               TextO("`4[`wDoctor`4] Plant `0Mode")
               Plant = true
           else
               TextO("`9Scanning `4Missing `0Harvest")
               Harvest = true
           end
           TotalTree = 0
       end
   end
------------------------------------------------------------
--  ROTATION
------------------------------------------------------------
function Rotation()    
    if Customize.Other.ModePlant:lower() == "left" then
      if ShouldStop() or not pt_running then return end
        for x = 199, Customize.Start.PosX, Customize.Other.Mray and -10 or -1 do
            if GetWorld() == nil or GetWorld().name ~= World or RemoteEmpty then
                return
            end
            LogToConsole("`9 " .. os.date("%H:%M:%S") .. " `0[`4Doctor`0] `cCurrently `0" .. (Plant and "Planting" or "Harvest") .. " `4On `9X `8: `2" .. x)
            for Loop = 1, 2, 1 do
                for y = Customize.Start.PosY, Customize.Start.PosY % 2 == 0 and 0 or 1, -2 do
                    if GetWorld() == nil or GetWorld().name ~= World or RemoteEmpty then
                        return
                    end
                    local tile = GetTile(x, y)
                    if (Plant and tile.fg == 0) or (Harvest and tile.fg == Customize.TreeID and IsReady(tile)) then
                        Raw(0, 48, 0, x, y)
                        Sleep(Plant and Customize.Delay.Plant * 10 or Customize.Delay.Harvest * 5)
                        Raw(3, 48, Plant and 5640 or 18, x, y)
                        if GetWorld() == nil or GetWorld().name ~= World  or RemoteEmpty then
                            return
                        end
                        local py = math.min(y + 2, Customize.Start.PosY)
                        if Plant then
                            if GetTile(x, py).fg == Customize.TreeID then
                                Limiter = 0
                            else
                                Limiter = Limiter + 1
                            end
                        end
                    end
                    if Limiter >= Customize.Magplant.Limit then
                        local Magplant = GetMagplant()
                        Current = Current % #Magplant + 1
                        Limiter = 0
                        RemoteEmpty = true
                        return
                    end
                end
            end
        end
    else
        if Customize.Other.ModePlant:lower() == "right" then
        if ShouldStop() or not pt_running then return end
            for x = Customize.Start.PosX, 199, Customize.Other.Mray and 10 or 1 do
                if GetWorld() == nil or GetWorld().name ~= World or RemoteEmpty then
                    return
                end
                LogToConsole("`9 " .. os.date("%H:%M:%S") .. " `0[`4Doctor`0] `cCurrently `0" .. (Plant and "Planting" or "Harvest") .. " `4On `9X `8: `2" .. x)
                for Loop = 1, 2, 1 do
                    for y = Customize.Start.PosY, Customize.Start.PosY % 2 == 0 and 0 or 1, -2 do
                        if GetWorld() == nil or GetWorld().name ~= World or RemoteEmpty then
                            return
                        end
                        local tile = GetTile(x, y)
                        if (Plant and tile.fg == 0) or (Harvest and tile.fg == Customize.TreeID and IsReady(tile)) then
                            Raw(0, 32, 0, x, y)
                            Sleep(Plant and Customize.Delay.Plant * 10 or Customize.Delay.Harvest * 5)
                            Raw(3, 32, Plant and 5640 or 18, x, y)
                            if GetWorld() == nil or GetWorld().name ~= World  or RemoteEmpty then
                                return
                            end
                            local py = math.min(y + 2, Customize.Start.PosY)
                            if Plant then
                                if GetTile(x, py).fg == Customize.TreeID then
                                    Limiter = 0
                                else
                                    Limiter = Limiter + 1
                                end
                            end
                        end
                        if Limiter >= Customize.Magplant.Limit then
                            local Magplant = GetMagplant()
                            Current = Current % #Magplant + 1
                            Limiter = 0
                            RemoteEmpty = true
                            return
                        end
                    end
                end
            end
        end
    end

    if GetWorld() == nil or GetWorld().name ~= World then
        return
    end
    
    PTHT = PTHT + 1
    ChangeMode()
end
------------------------------------------------------------
--  RECONNECT
------------------------------------------------------------
function Reconnect()
  if ShouldStop() or not pt_running then return end
       if GetWorld() == nil or GetWorld().name ~= World then
           SendPacket(3, "action|join_request\nname|" .. World .. "|\ninvitedWorld|0")
           TextO("`0Entering `4World `0: `e" .. World)
           SleepSafe(Customize.Delay.entering * 100)
           RemoteEmpty = true
       else
           if RemoteEmpty then
               TextO("`wTaking `4Remote")
               GetRemote()
               RemoteEmpty = false
           end
           Rotation()
       end
   end

------------------------------------------------------------
-- WEBHOOK
------------------------------------------------------------
local function allbout(tis)
  local days   = math.floor(tis / 86400)
  local hours  = math.floor((tis % 86400) / 3600)
  local minutes= math.floor((tis % 3600) / 60)
  local seconds= tis % 60
  return days, hours, minutes, seconds
end

local start_ts = os.time()

local function ahUh()
  local tis = os.time() - start_ts
  local nps = siz(GetLocal().name):match("%S+") or GetLocal().name
  local stk = iv(12600)
  local d,h,m,s = allbout(tis)

  local mg = GetMagplant()
  local mx, my = 0, 0
  if #mg > 0 and mg[Current] then mx, my = mg[Current][1], mg[Current][2] end

  local payload = [[
  {
    "embeds": [{
      "title": "Ptht Webhook",
      "fields": [
        { "name": "<:char:1257391556714037270> Player Name", "value": "]]..nps..[[\n<@]]..Customize.Other.DiscordID..[[>", "inline": false },
        { "name": "<:uws:1327232627182403665> Stock Uws", "value": "]]..stk..[[", "inline": true },
        { "name": "<:globee:1326955204263805001> World Name", "value": "]]..World..[[", "inline": true },
        { "name": "<:magplant:1267643788059480205> Magplant Position", "value": "(]]..mx..[[ , ]]..my..[[)", "inline": false },
        { "name": "<:magplant:1267643788059480205> Magplant Stock", "value": "]]..iM..[[", "inline": false },
        { "name": "<:verified:1326720169086685244> Status Ptht", "value": "]]..(PTHT // 2 + 1)..[[ / ]]..tostring(Customize.Start.Loop)..[[", "inline": true },
        { "name": " Ptht Time!", "value": ":timer: ETA: ]]..d..[[ days ]]..h..[[ hours ]]..m..[[ minute ]]..s..[[ second", "inline": false }
      ],
      "color": 14177041,
      "thumbnail": { "url": "https://cdn.discordapp.com/attachments/1320019030437789698/1388335828794871919/skin31.webp" }
    }]
  }]]
  SendWebhook(Customize.Other.WebHooks, payload)
end

local function ahHa()
  local tis = os.time() - start_ts
  local npp = siz(GetLocal().name):match("%S+") or GetLocal().name
  local stk = iv(12600)
  local d,h,m,s = allbout(tis)

  local mg = GetMagplant()
  local mx, my = 0, 0
  if #mg > 0 and mg[Current] then mx, my = mg[Current][1], mg[Current][2] end

  local payload = [[
  {
    "content": "ptht done dumbs <@]]..Customize.Other.DiscordID..[[>",
    "embeds": [{
      "title": "Ptht Webhook",
      "fields": [
        { "name": "<:char:1257391556714037270> Player Name", "value": "]]..npp..[[\n<@]]..Customize.Other.DiscordID..[[>", "inline": false },
        { "name": "<:uws:1327232627182403665> Stock Uws", "value": "]]..stk..[[", "inline": true },
        { "name": "<:globee:1326955204263805001> World Name", "value": "]]..World..[[", "inline": true },
        { "name": "<:magplant:1267643788059480205> Magplant Position", "value": "(]]..mx..[[ , ]]..my..[[)", "inline": false },
        { "name": "<:magplant:1267643788059480205> Magplant Stock", "value": "]]..iM..[[", "inline": false },
        { "name": "<:verified:1326720169086685244> Status Ptht", "value": "]]..(PTHT // 2 + 1)..[[ / ]]..tostring(Customize.Start.Loop)..[[", "inline": true },
        { "name": " Ptht Time!", "value": ":timer: ETA: ]]..d..[[ days ]]..h..[[ hours ]]..m..[[ minute ]]..s..[[ second", "inline": false }
      ],
      "color": 14177041,
      "thumbnail": { "url": "https://cdn.discordapp.com/attachments/1320019030437789698/1388335828794871919/skin31.webp" }
    }]
  }]]
  SendWebhook(Customize.Other.WebHooks, payload)
end


  if Customize.Start.Mode:upper() == "PT" then
    Plant, Harvest = true, false
  elseif Customize.Start.Mode:upper() == "PTHT" then
    Plant, Harvest = true, false
  else
    Plant, Harvest = false, true
end
------------------------------------------------------------
------------------------------------------------------------
RunThread(function()
  
  local ps = [[set_default_color||
add_label_with_icon|big|`oWelcome|left|2480|
add_textbox|   `oThanks for Using PTHT|
add_spacer|small|
add_url_button||`w"`eDiscord Server `w"|NOFLAGS|https://discord.com/invite/PM3YrhF3GW|0Free 9CreativePS `0Scripts for `2GrowLauncher. bJOIN NOW!|0|0|
add_space|big|
add_textbox|`bPowered By Doctor|
end_dialog|c|Exit|
add_quick_exit||]]
  SendVariantList{[0] = "OnDialogRequest", [1] = ps}

  
  for i = 1, 2 do
    if not SleepSafe(1000) then break end
    SendPacket(2, "action|input\n|text|`8[  `4PtHt Doctor`8] `cCount `w"..Customize.Start.Mode.." `c"..tostring(Customize.Start.Loop).." `4Mode: `9"..Customize.Other.ModePlant:upper())
  end

  
  while pt_alive do
    if ShouldStop() then break end

    if pt_running then
      
      World = WorldName()

      if Customize.Start.Loop == "unli" then
        Reconnect()
        ahUh()
      elseif type(Customize.Start.Loop) == "number" then
        Reconnect()
        if (PTHT // 2) + 1 == Customize.Start.Loop then
          Rotation()
          ahHa()
          SendPacket(2, "action|input\ntext|`4[`0PTHT`4] `bFINISHED `c"..(PTHT // 2 + 1).." `4LEAVE `9WORLD")
          LogToConsole("`9Your job PTHT DONE")
          SleepSafe(7000)
          SendPacket(3, "action|join_request\nname|EXIT|\ninvitedWorld|0")
          pt_running = false -- selesai target loop → stop otomatis
        elseif PTHT % 2 ~= 0 then
          SendPacket(2, "action|input\ntext|`4[`2PTHT`4] `0[ `cRotation `4: `9"..(PTHT // 2 + 1).." `b/ `9"..tostring(Customize.Start.Loop).." (wink) `w]")
          SleepSafe(4000)
          ahUh()
          -- sisa PTHT
          local remaining = Customize.Start.Loop - (PTHT // 2 + 1)
          SendPacket(2, "action|input\n|text|`0SISA PTHT  (halo) `4= `4[`9"..tostring(remaining).."`4] (troll)")
          SleepSafe(6000)
        end
      end
    else
      
      SleepSafe(150)
    end
  end

  
  pt_alive   = false
  pt_running = false
  ui_visible = false
  TextO("`4[PTHT] Terminated by HUB/GUI.")
end)

------------------------------------------------------------
--  IMGUI CONTROLLER (AddHook)
------------------------------------------------------------
AddHook("OnDraw", "PTHT_GUI", function()
  if _G.shouldStop or not ui_visible then return end

  ImGui.Begin(" PTHT Controller", true, ImGuiWindowFlags_AlwaysAutoResize)

  if ImGui.BeginTabBar("PTHT_Tabs") then
    ----------------------------------------------------
    -- TAB MAIN
    ----------------------------------------------------
    if ImGui.BeginTabItem(" Main") then
        if not pt_running then
      if ImGui.Button("▶ Start PTHT", 140, 32) then
        if not pt_running then
          World = WorldName()
          pt_running = true
          TextO("`2[PTHT] Started.")
        end
      end

      ImGui.SameLine()
        if ImGui.Button("❌ Tutup GUI", 288, 32) then
        pt_running = false
        ui_visible = false
        _G.shouldStop = true
        TextO("`4[PTHT] Terminate requested.")
        end
      else
      if ImGui.Button("⏹ Stop PTHT", 140, 32) then
        if pt_running then
          pt_running = false
          TextO("`e[PTHT] Paused. Thread alive.")
        end
      end
ImGui.SameLine()
          ImGui.BeginDisabled(true); ImGui.Button("Tutup GUI"); ImGui.EndDisabled()
      end

      ImGui.Separator()
      -- World & Posisi
      ImGui.Text("World : "..World)
      if ImGui.Button(" Set Pos dari Player") then
        local me, w = GetLocal(), GetWorld()
        if me and w then
  
          Customize.Start.PosY = me.pos.y // 32
          World = w.name
          TextO("✅ Posisi & World diset dari player: ("..Customize.Start.PosX..","..Customize.Start.PosY..") @"..World)
        else
          TextO("⚠ Tidak bisa set dari player (belum di world?)")
        end
      end

      -- Webhook
      _, Customize.Other.WebHooks = ImGui.InputText("Webhook URL", Customize.Other.WebHooks, 256)

      ImGui.Separator()
      -- Status
      ImGui.Text("📊 Status Info")
      ImGui.Text("World     : "..World)
      ImGui.Text("Mode      : "..Customize.Start.Mode)
      ImGui.Text("ModePlant : "..Customize.Other.ModePlant)
      ImGui.Text("PTHT Count: "..tostring(PTHT))
      ImGui.Text("Status    : "..(pt_running and "Running" or "Idle"))
      ImGui.EndTabItem()
    end

    ----------------------------------------------------
    -- TAB SETTINGS
    ----------------------------------------------------
    if ImGui.BeginTabItem("Settings") then
      -- Tree ID
      _, Customize.TreeID = ImGui.InputInt("Tree ID", Customize.TreeID)

      -- Mode dropdown
      local modes = {"PT", "PTHT"}
      local currentMode = 1
      for i, v in ipairs(modes) do
        if v == Customize.Start.Mode then currentMode = i end
      end
      if ImGui.BeginCombo("Mode", modes[currentMode]) then
        for i, v in ipairs(modes) do
          if ImGui.Selectable(v, i == currentMode) then
            Customize.Start.Mode = v
          end
        end
        ImGui.EndCombo()
      end

      -- Loop Count
      _, Customize.Start.Loop = ImGui.InputInt("Loop Count", Customize.Start.Loop)

      -- Posisi Manual
      _, Customize.Start.PosX = ImGui.InputInt("Pos X", Customize.Start.PosX)
      _, Customize.Start.PosY = ImGui.InputInt("Pos Y", Customize.Start.PosY)

      -- Delay
      _, Customize.Delay.Harvest  = ImGui.InputInt("Delay Harvest",  Customize.Delay.Harvest)
      _, Customize.Delay.entering = ImGui.InputInt("Delay Entering", Customize.Delay.entering)
      _, Customize.Delay.Plant    = ImGui.InputInt("Delay Plant",    Customize.Delay.Plant)

      -- Discord
      _, Customize.Other.DiscordID = ImGui.InputText("Discord ID", Customize.Other.DiscordID, 64)

      -- ModePlant dropdown
      local plantModes = {"left", "right"}
      local currentPlantMode = 1
      for i, v in ipairs(plantModes) do
        if v == Customize.Other.ModePlant then currentPlantMode = i end
      end
      if ImGui.BeginCombo("Mode Plant", plantModes[currentPlantMode]) then
        for i, v in ipairs(plantModes) do
          if ImGui.Selectable(v, i == currentPlantMode) then
            Customize.Other.ModePlant = v
          end
        end
        ImGui.EndCombo()
      end

      _, Customize.Other.Mray = ImGui.Checkbox("Use Mray", Customize.Other.Mray)

      -- Magplant
      _, Customize.Magplant.Limit = ImGui.InputInt("Magplant Limit", Customize.Magplant.Limit)
      _, Customize.Magplant.bcg   = ImGui.InputInt("Magplant BG",    Customize.Magplant.bcg)

      ImGui.EndTabItem()
    end

    ImGui.EndTabBar()
  end

  ImGui.End()
end)
