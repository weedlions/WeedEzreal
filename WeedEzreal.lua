local ts
local minman
local myHero = GetMyHero()
local predTable = {"None"}
local currentPred = nil
local healactive = false
local Version = 1.001
local Heal, Barrier = nil
local OrbWalkers = {}
local LoadedOrb = nil
local modeTable = {""}

if myHero.charName ~= "Ezreal" then return end

function VPredLoader()
  local LibPath = LIB_PATH.."VPrediction.lua"
  if not (FileExist(LibPath)) then
    local Host = "raw.githubusercontent.com"
    local Path = "/SidaBoL/Scripts/master/Common/VPrediction.lua"
    DownloadFile("https://"..Host..Path, LibPath, function () prntChat("VPrediction installed. Please press 2x F9") end)
    require "VPrediction"
    currentPred = VPrediction()
  else
    require "VPrediction"
    currentPred = VPrediction()
  end
end
AddLoadCallback(function() VPredLoader() end)

function OnLoad()

  minman = minionManager(MINION_ENEMY, 1200)

  if(myHero.charName == "Ezreal") then
    prntChat("Welcome to Weed Ezreal. Good Luck, Have Fun!")
    prntChat("Version "..Version.." loaded.")
  end

  ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1200, DAMAGE_PHYSICAL)

  table.insert(modeTable, "Lasthit")
  table.insert(modeTable, "Push")

  CheckUpdates()
  initMenu()
  initSumms()
  InitOrbs()
  LoadOrb()

end

function initSumms()

  if myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier" then Barrier = 1
  elseif myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal" then Heal = 1 end

  if myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier" then Barrier = 2
  elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal" then Heal = 2 end

end

function initMenu()

  Config = scriptConfig("Weed Ezreal", "weedez")

  Config:addSubMenu("Combo Settings", "settComb")
  Config.settComb:addParam("useq", "Use Q", SCRIPT_PARAM_ONOFF, true)
  Config.settComb:addParam("manaq", "Min % Mana for Q", SCRIPT_PARAM_SLICE, 25, 0, 100, 0)
  Config.settComb:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
  Config.settComb:addParam("usew", "Use W", SCRIPT_PARAM_ONOFF, true)
  Config.settComb:addParam("manaw", "Min % Mana for W", SCRIPT_PARAM_SLICE, 45, 0, 100, 0)

  Config:addSubMenu("Harass Settings", "settHar")
  Config.settHar:addParam("useq", "Use Q", SCRIPT_PARAM_ONOFF, true)
  Config.settHar:addParam("manaq", "Min % Mana for Q", SCRIPT_PARAM_SLICE, 25, 0, 100, 0)
  Config.settHar:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
  Config.settHar:addParam("usew", "Use W", SCRIPT_PARAM_ONOFF, true)
  Config.settHar:addParam("manaw", "Min % Mana for W", SCRIPT_PARAM_SLICE, 45, 0, 100, 0)

  Config:addSubMenu("Laneclear Settings", "settLC")
  Config.settLC:addParam("useq", "Use Q in Laneclear", SCRIPT_PARAM_ONOFF, true)
  Config.settLC:addParam("mana", "Min % Mana for Q", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
  Config.settLC:addParam("mode", "Use Q for", SCRIPT_PARAM_LIST, 1, modeTable)
  Config.settLC:addParam("dmgbuff", "Damage Buffer for Push Mode", SCRIPT_PARAM_SLICE, 50, 0, 200, 0)

  Config:addSubMenu("Lasthit Settings", "settLH")
  Config.settLH:addParam("useq", "Use Q in Lasthit", SCRIPT_PARAM_ONOFF, true)
  Config.settLH:addParam("mana", "Min % Mana for Q", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)

  Config:addSubMenu("Killsteal Settings", "settSteal")
  Config.settSteal:addParam("useq", "Use Q for Killsteal", SCRIPT_PARAM_ONOFF, true)
  Config.settSteal:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
  Config.settSteal:addParam("usew", "Use W for Killsteal", SCRIPT_PARAM_ONOFF, true)
  Config.settSteal:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
  Config.settSteal:addParam("user", "Use R for Killsteal", SCRIPT_PARAM_ONOFF, true)
  Config.settSteal:addParam("maxrange", "Max Range for R Steal", SCRIPT_PARAM_SLICE, 3000, 0, 5000, 0)
  Config.settSteal:addParam("minrange", "Min Range for R Steal", SCRIPT_PARAM_SLICE, 1000, 0, 5000, 0)

  Config:addSubMenu("Auto Heal/Auto Barrier Settings", "settAHeal")
  Config.settAHeal:addParam("active", "Use Auto Heal/Barrier", SCRIPT_PARAM_ONOFF, true)
  Config.settAHeal:addParam("hp", "Use on X % HP", SCRIPT_PARAM_SLICE, 20, 0, 100, 0)

  Config:addSubMenu("HitChance Settings", "settHit")
  Config.settHit:addParam("qhit", "Q HitChance", SCRIPT_PARAM_SLICE, 2, 2, 4, 0)
  Config.settHit:addParam("whit", "W HitChance", SCRIPT_PARAM_SLICE, 2, 2, 4, 0)
  Config.settHit:addParam("rhit", "R HitChance", SCRIPT_PARAM_SLICE, 2, 2, 4, 0)
  Config.settHit:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
  Config.settHit:addParam("Blank", "Explanation", SCRIPT_PARAM_INFO, "")
  Config.settHit:addParam("Blank", "2 = High Hitchance", SCRIPT_PARAM_INFO, "")
  Config.settHit:addParam("Blank", "3 = Slowed Targets (~100%)", SCRIPT_PARAM_INFO, "")
  Config.settHit:addParam("Blank", "4 = Immobile Targets (~100%)", SCRIPT_PARAM_INFO, "")

  Config:addSubMenu("Draw Settings", "settDraw")
  Config.settDraw:addParam("qrange", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
  Config.settDraw:addParam("qpred", "Draw Q Prediction", SCRIPT_PARAM_ONOFF, true)
  Config.settDraw:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
  Config.settDraw:addParam("wrange", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
  Config.settDraw:addParam("wpred", "Draw W Prediction", SCRIPT_PARAM_ONOFF, false)
  Config.settDraw:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
  Config.settDraw:addParam("erange", "Draw E Range", SCRIPT_PARAM_ONOFF, true)
  Config.settDraw:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
  Config.settDraw:addParam("wayp", "Draw Waypoints", SCRIPT_PARAM_ONOFF, true)


end

function OnTick()

  if myHero.dead then return end

  ts:update()
  minman:update()

  if(getMode() == "Laneclear") then onLaneClear() end

  if(getMode() == "Lasthit") then onLastHit() end

  if(getMode() == "Combo") then onCombo() end

  if(getMode() == "Harass") then onHarass() end


  killSteal()
  if Config.settAHeal.active then autoHeal() end

end

--MODES-MODES-MODES--
--MODES-MODES-MODES--
--MODES-MODES-MODES--

function autoHeal()

  if ((myHero.health/myHero.maxHealth)*100) < Config.settAHeal.hp then
    if Barrier==1 and myHero:CanUseSpell(SUMMONER_1) then
      CastSpell(SUMMONER_1)
    elseif Heal==1 and myHero:CanUseSpell(SUMMONER_1) then
      CastSpell(SUMMONER_1)
    elseif Barrier==2 and myHero:CanUseSpell(SUMMONER_2) then
      CastSpell(SUMMONER_2)
    elseif Heal==2 and myHero:CanUseSpell(SUMMONER_2) then
      CastSpell(SUMMONER_2)
    end
  end

end

function killSteal()

  for i=1, heroManager.iCount do

    local enemy = heroManager:getHero(i)
    if(Config.settSteal.useq and myHero:CanUseSpell(_Q) == READY and enemy.health < (getDmg("Q", enemy, myHero)+((myHero.damage)*1.1)+(myHero.ap*0.4)) and not enemy.dead and enemy.valid and enemy.bTargetable and GetDistance(enemy.pos) < 1500) then

      local CastPosition = predict(enemy, "Q")
      if(CastPosition ~= nil) then CastSpell(_Q, CastPosition.x, CastPosition.z) end

    end

    if(Config.settSteal.usew and myHero:CanUseSpell(_W) == READY and enemy.health < (getDmg("W", enemy, myHero)+((myHero.ap)*0.8)) and enemy.valid and not enemy.dead and enemy.bTargetable and GetDistance(enemy.pos) < 1100) then

      local CastPosition = predict(enemy, "W")
      if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end

    end

    if(Config.settSteal.user and myHero:CanUseSpell(_R) == READY and enemy.health < (getDmg("R", enemy, myHero)+((myHero.ap)*0.9)+(myHero.damage)) and enemy.valid and not enemy.dead and enemy.bTargetable) then

      if GetDistance(enemy.pos) < Config.settSteal.maxrange and GetDistance(enemy.pos) > Config.settSteal.minrange then

        local CastPosition = predict(enemy, "R")
        if(CastPosition ~= nil) then CastSpell(_R, CastPosition.x, CastPosition.z) end

      end

    end

  end

end

--COMBO-COMBO-COMBO--
--COMBO-COMBO-COMBO--
--COMBO-COMBO-COMBO--
function onCombo()

  local target = GetTarget()

  if not myHero:CanUseSpell(_Q) == READY and not myHero:CanUseSpell(_W) == READY then return end
  if not target then return end

  --Q--
  if Config.settComb.useq and ((myHero.mana/myHero.maxMana)*100) > Config.settComb.manaq then

    local CastPosition = predict(target, "Q")
    if(CastPosition ~= nil) then CastSpell(_Q, CastPosition.x, CastPosition.z) end

  end
  --Q--

  --W--
  if Config.settComb.usew and ((myHero.mana/myHero.maxMana)*100) > Config.settComb.manaw then

    local CastPosition = predict(target, "W")
    if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end

  end
  --W--

end
--COMBO-COMBO-COMBO--
--COMBO-COMBO-COMBO--
--COMBO-COMBO-COMBO--

--HARASS-HARASS-HARASS--
--HARASS-HARASS-HARASS--
--HARASS-HARASS-HARASS--
function onHarass()

  local target = GetTarget()

  if not myHero:CanUseSpell(_Q) == READY and not myHero:CanUseSpell(_W) == READY then return end
  if not target then return end

  --Q--
  if Config.settHar.useq and ((myHero.mana/myHero.maxMana)*100) > Config.settHar.manaq then

    local CastPosition = predict(target, "Q")
    if(CastPosition ~= nil) then CastSpell(_Q, CastPosition.x, CastPosition.z) end

  end
  --Q--

  --W--
  if Config.settHar.usew and ((myHero.mana/myHero.maxMana)*100) > Config.settHar.manaw then

    local CastPosition = predict(target, "W")
    if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end

  end
  --W--

end
--HARASS-HARASS-HARASS--
--HARASS-HARASS-HARASS--
--HARASS-HARASS-HARASS--

--LC-LC-LC--
--LC-LC-LC--
--LC-LC-LC--
function onLaneClear()

  if not myHero:CanUseSpell(_Q) == READY then return end

  if Config.settLC.useq and ((myHero.mana/myHero.maxMana)*100) > Config.settLC.mana then

    for i, minion in pairs(minman.objects) do

      if minion.valid and not minion.dead and minion.visible then

        if modeTable[Config.settLC.mode] == "Lasthit" and minion.health < (getDmg("Q", minion, myHero)+((myHero.damage)*1.1)+(myHero.ap*0.4)) then

          local CastPosition = predict(minion, "Q")
          if(CastPosition ~= nil) then CastSpell(_Q, CastPosition.x, CastPosition.z) end

        elseif modeTable[Config.settLC.mode] == "Push" and (minion.health < (getDmg("Q", minion, myHero)+((myHero.damage)*1.1)+(myHero.ap*0.4)) or (minion.health > (getDmg("Q", minion, myHero)+((myHero.damage)*1.1))+Config.settLC.dmgbuff)) then

          local CastPosition = predict(minion, "Q")
          if(CastPosition ~= nil) then CastSpell(_Q, CastPosition.x, CastPosition.z) end

        end

      end

    end

  end

end
--LC-LC-LC--
--LC-LC-LC--
--LC-LC-LC--

--LH-LH-LH--
--LH-LH-LH--
--LH-LH-LH--
function onLastHit()

  if not myHero:CanUseSpell(_Q) == READY then return end

  if Config.settLH.useq and ((myHero.mana/myHero.maxMana)*100) > Config.settLH.mana then

    for i, minion in pairs(minman.objects) do

      if minion.valid and not minion.dead and minion.visible then

        if minion.health < (getDmg("Q", minion, myHero)+((myHero.damage)*1.1)+(myHero.ap*0.4)) then

          local CastPosition = predict(minion, "Q")
          if(CastPosition ~= nil) then CastSpell(_Q, CastPosition.x, CastPosition.z) end

        end

      end

    end

  end

end
--LH-LH-LH--
--LH-LH-LH--
--LH-LH-LH--

--MODES-END-MODES-END--
--MODES-END-MODES-END--
--MODES-END-MODES-END--

function GetTarget()

  ts:update()
  return ts.target

end


function predict(target, spell)

  if(spell == "Q") then
    local CastPosition, HitChance, Position = currentPred:GetLineCastPosition(target, 0.20, 50, 1200, 2000, myHero, true)
    if CastPosition and HitChance >= Config.settHit.qhit then
      return CastPosition
    end
  elseif(spell == "W") then
    local CastPosition, HitChance, Position = currentPred:GetLineCastPosition(target, 0.20, 50, 1000, 1550, myHero, false)
    if CastPosition and HitChance >= Config.settHit.whit then
      return CastPosition
    end
  elseif(spell == "R") then
    local CastPosition, HitChance, Position = currentPred:GetLineCastPosition(target, 1, 100, math.huge, 2000, myHero, false)
    if CastPosition and HitChance >= Config.settHit.qhit then
      return CastPosition
    end
  elseif(spell == "QPred") then
    local CastPosition, HitChance, Position = currentPred:GetLineCastPosition(target, 0.20, 50, 1200, 2000, myHero, true)
    if CastPosition then
      return CastPosition, HitChance
    end
  elseif(spell == "WPred") then
    local CastPosition, HitChance, Position = currentPred:GetLineCastPosition(target, 0.20, 50, 1000, 1550, myHero, false)
    if CastPosition then
      return CastPosition, HitChance
    end
  else return nil
  end

end

function OnDraw()

  if(Config.settDraw.qrange) then
    DrawCircle(myHero.x, myHero.y, myHero.z, 1200, 0x111111)
  end

  if(Config.settDraw.wrange) then
    DrawCircle(myHero.x, myHero.y, myHero.z, 1000, 0x111111)
  end

  if(Config.settDraw.erange) then
    DrawCircle(myHero.x, myHero.y, myHero.z, 475, 0x111111)
  end

  if Config.settDraw.wayp then
    for i=1, heroManager.iCount do
      local enemy = heroManager:getHero(i)

      if enemy.team ~= myHero.team and not enemy.dead then
        currentPred:DrawSavedWaypoints(enemy, 1)
      end
    end
  end

  if Config.settDraw.qpred then

    local target = GetTarget()

    if target ~= nil then

      local CastPosition, HitChance = predict(target, "QPred")
      if(CastPosition ~= nil and HitChance >= Config.settHit.qhit) then DrawLine3D(myHero.x, myHero.y, myHero.z, CastPosition.x, CastPosition.y, CastPosition.z, 3, ARGB(100,0,255,0))
      elseif(CastPosition ~= nil) then DrawLine3D(myHero.x, myHero.y, myHero.z, CastPosition.x, CastPosition.y, CastPosition.z, 3, ARGB(255,255,0,0)) end

    end

  end

  if Config.settDraw.wpred then

    local target = GetTarget()

    if target ~= nil then

      local CastPosition, HitChance = predict(target, "WPred")
      if(CastPosition ~= nil and HitChance >= Config.settHit.whit) then DrawLine3D(myHero.x, myHero.y, myHero.z, CastPosition.x, CastPosition.y, CastPosition.z, 3, ARGB(100,0,255,0))
      elseif(CastPosition ~= nil) then DrawLine3D(myHero.x, myHero.y, myHero.z, CastPosition.x, CastPosition.y, CastPosition.z, 3, ARGB(255,255,0,0)) end

    end

  end

end

function prntChat(message)

  PrintChat("<font color=\"#0B6121\"><b>--Weed Ezreal--</b></font> ".."<font color=\"#FFFFFF\"><b>"..message..".</b></font>")

end


function InitOrbs()
  if _G.Reborn_Loaded or _G.Reborn_Initialised or _G.AutoCarry ~= nil then
    table.insert(OrbWalkers, "SAC")
  end
  if _G.MMA_IsLoaded then
    table.insert(OrbWalkers, "MMA")
  end
  if _G._Pewalk then
    table.insert(OrbWalkers, "Pewalk")
  end
  if FileExist(LIB_PATH .. "/Nebelwolfi's Orb Walker.lua") then
    table.insert(OrbWalkers, "NOW")
  end
  if FileExist(LIB_PATH .. "/Big Fat Orbwalker.lua") then
    table.insert(OrbWalkers, "Big Fat Walk")
  end
  if FileExist(LIB_PATH .. "/SOW.lua") then
    table.insert(OrbWalkers, "SOW")
  end
  if FileExist(LIB_PATH .. "/SxOrbWalk.lua") then
    table.insert(OrbWalkers, "SxOrbWalk")
  end
  if #OrbWalkers > 0 then
    Config:addSubMenu("Orbwalkers", "Orbwalkers")
    Config:addSubMenu("Keys", "Keys")
    Config.Orbwalkers:addParam("Orbwalker", "OrbWalker", SCRIPT_PARAM_LIST, 1, OrbWalkers)
    Config.Keys:addParam("info", "Detecting keys from: "..OrbWalkers[Config.Orbwalkers.Orbwalker], SCRIPT_PARAM_INFO, "")
    local OrbAlr = false
    Config.Orbwalkers:setCallback("Orbwalker", function(value)
      if OrbAlr then return end
      OrbAlr = true
      Menu.Orbwalkers:addParam("info", "Press F9 2x to load your selected Orbwalker.", SCRIPT_PARAM_INFO, "")
      prntChat("Press F9 2x to load your selected Orbwalker")
    end)
  end
end

function LoadOrb()
  if OrbWalkers[Config.Orbwalkers.Orbwalker] == "SAC" then
    LoadedOrb = "Sac"
    TIMETOSACLOAD = false
    DelayAction(function() TIMETOSACLOAD = true end,15)
  elseif OrbWalkers[Config.Orbwalkers.Orbwalker] == "MMA" then
    LoadedOrb = "Mma"
  elseif OrbWalkers[Config.Orbwalkers.Orbwalker] == "Pewalk" then
    LoadedOrb = "Pewalk"
  elseif OrbWalkers[Config.Orbwalkers.Orbwalker] == "NOW" then
    LoadedOrb = "Now"
    require "Nebelwolfi's Orb Walker"
    _G.NOWi = NebelwolfisOrbWalkerClass()
    Config.Orbwalkers:addSubMenu("NOW", "NOW")
    _G.NebelwolfisOrbWalkerClass(Config.Orbwalkers.NOW)
  elseif OrbWalkers[Config.Orbwalkers.Orbwalker] == "Big Fat Walk" then
    LoadedOrb = "Big"
    require "Big Fat Orbwalker"
  elseif OrbWalkers[Config.Orbwalkers.Orbwalker] == "SOW" then
    LoadedOrb = "Sow"
    require "SOW"
    Config.Orbwalkers:addSubMenu("SOW", "SOW")
    _G.SOWi = SOW(_G.VP)
    SOW:LoadToMenu(Config.Orbwalkers.SOW)
  elseif OrbWalkers[Config.Orbwalkers.Orbwalker] == "SxOrbWalk" then
    LoadedOrb = "SxOrbWalk"
    require "SxOrbWalk"
    Config.Orbwalkers:addSubMenu("SxOrbWalk", "SxOrbWalk")
    SxOrb:LoadToMenu(Config.Orbwalkers.SxOrbWalk)
  end
end

function getMode()
  if LoadedOrb == "Sac" and TIMETOSACLOAD then
    if _G.AutoCarry.Keys.AutoCarry then return "Combo" end
    if _G.AutoCarry.Keys.MixedMode then return "Harass" end
    if _G.AutoCarry.Keys.LaneClear then return "Laneclear" end
    if _G.AutoCarry.Keys.LastHit then return "Lasthit" end
  elseif LoadedOrb == "Mma" then
    if _G.MMA_IsOrbwalking() then return "Combo" end
    if _G.MMA_IsDualCarrying() then return "Harass" end
    if _G.MMA_IsLaneClearing() then return "Laneclear" end
    if _G.MMA_IsLastHitting() then return "Lasthit" end
  elseif LoadedOrb == "Pewalk" then
    if _G._Pewalk.GetActiveMode().Carry then return "Combo" end
    if _G._Pewalk.GetActiveMode().Mixed then return "Harass" end
    if _G._Pewalk.GetActiveMode().LaneClear then return "Laneclear" end
    if _G._Pewalk.GetActiveMode().Farm then return "Lasthit" end
  elseif LoadedOrb == "Now" then
    if _G.NOWi.Config.k.Combo then return "Combo" end
    if _G.NOWi.Config.k.Harass then return "Harass" end
    if _G.NOWi.Config.k.LaneClear then return "Laneclear" end
    if _G.NOWi.Config.k.LastHit then return "Lasthit" end
  elseif LoadedOrb == "Big" then
    if _G["BigFatOrb_Mode"] == "Combo" then return "Combo" end
    if _G["BigFatOrb_Mode"] == "Harass" then return "Harass" end
    if _G["BigFatOrb_Mode"] == "LaneClear" then return "Laneclear" end
    if _G["BigFatOrb_Mode"] == "LastHit" then return "Lasthit" end
  elseif LoadedOrb == "Sow" then
    if _G.SOWi.Menu.Mode0 then return "Combo" end
    if _G.SOWi.Menu.Mode1 then return "Harass" end
    if _G.SOWi.Menu.Mode2 then return "Laneclear" end
    if _G.SOWi.Menu.Mode3 then return "Lasthit" end
  elseif LoadedOrb == "SxOrbWalk" then
    if _G.SxOrb.isFight then return "Combo" end
    if _G.SxOrb.isHarass then return "Harass" end
    if _G.SxOrb.isLaneClear then return "Laneclear" end
    if _G.SxOrb.isLastHit then return "Lasthit" end
  end
end



local serveradress = "raw.githubusercontent.com"
local scriptadress = "/weedlions/WeedEzreal/master"
local scriptname = "WeedEzreal"
local adressfull = "http://"..serveradress..scriptadress.."/"..scriptname..".lua"
function CheckUpdates()
  local ServerVersionDATA = GetWebResult(serveradress , scriptadress.."/"..scriptname..".version")
  if ServerVersionDATA then
    local ServerVersion = tonumber(ServerVersionDATA)
    if ServerVersion then
      if ServerVersion > tonumber(Version) then
        prntChat("Updating, don't press F9")
        DownloadUpdate()
      else
        prntChat("You have the latest version")
      end
    else
      prntChat("An error occured, while updating")
    end
  else
    prntChat("Could not connect to update Server")
  end
end

function DownloadUpdate()
  DownloadFile(adressfull, SCRIPT_PATH..scriptname..".lua", function ()
    prntChat("Updated, press 2x F9")
  end)
end