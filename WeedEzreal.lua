require "UOL"

local predTable = {"None"}
local currentPred = nil
local myHero = GetMyHero()
local ts
local minionmanager = nil
local modeTable = {"None"}

if myHero.charName ~= "Ezreal" then return end

function OnLoad()

  minionmanager = minionManager(MINION_ALL, 1500)

  if(myHero.charName == "Ezreal") then
    PrintChat("Welcome to Weed Ezreal. Good Luck, Have Fun!")
  end

  ts = TargetSelector(TARGET_LOW_HP_PRIORITY,1500)

  table.insert(modeTable, "Lasthit")
  table.insert(modeTable, "Push")

  initPreds()
  initMenu()

end

function initMenu()

  Config = scriptConfig("Weed Ezreal", "weedez")

  Config:addSubMenu("Combo Settings", "settComb")
  Config.settComb:addParam("useq", "Use Q", SCRIPT_PARAM_ONOFF, true)
  Config.settComb:addParam("Blank", "Min Mana for Q", SCRIPT_PARAM_INFO, "")
  Config.settComb:addParam("manaq", "Default value = 25", SCRIPT_PARAM_SLICE, 25, 0, 100, 0)
  Config.settComb:addParam("usew", "Use W", SCRIPT_PARAM_ONOFF, true)
  Config.settComb:addParam("Blank", "Min Mana for W", SCRIPT_PARAM_INFO, "")
  Config.settComb:addParam("manaw", "Default value = 45", SCRIPT_PARAM_SLICE, 45, 0, 100, 0)

  Config:addSubMenu("Harass Settings", "settHar")
  Config.settHar:addParam("useq", "Use Q", SCRIPT_PARAM_ONOFF, true)
  Config.settHar:addParam("Blank", "Min Mana for Q", SCRIPT_PARAM_INFO, "")
  Config.settHar:addParam("manaq", "Default value = 25", SCRIPT_PARAM_SLICE, 25, 0, 100, 0)
  Config.settHar:addParam("usew", "Use W", SCRIPT_PARAM_ONOFF, true)
  Config.settHar:addParam("Blank", "Min Mana for W", SCRIPT_PARAM_INFO, "")
  Config.settHar:addParam("manaw", "Default value = 45", SCRIPT_PARAM_SLICE, 45, 0, 100, 0)

  Config:addSubMenu("Laneclear Settings", "settLC")
  Config.settLC:addParam("useq", "Use Q in Laneclear", SCRIPT_PARAM_ONOFF, true)
  Config.settLC:addParam("Blank", "Min Mana for Q", SCRIPT_PARAM_INFO, "")
  Config.settLC:addParam("mana", "Default value = 50", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
  Config.settLC:addParam("mode", "Use Q for", SCRIPT_PARAM_LIST, 1, modeTable)
  Config.settLC:addParam("Blank", "Damage Buffer for Push Mode", SCRIPT_PARAM_INFO, "")
  Config.settLC:addParam("dmgbuff", "Default value = 50", SCRIPT_PARAM_SLICE, 50, 0, 200, 0)

  Config:addSubMenu("Lasthit Settings", "settLH")
  Config.settLH:addParam("useq", "Use Q in Lasthit", SCRIPT_PARAM_ONOFF, true)
  Config.settLH:addParam("Blank", "Min Mana for Q", SCRIPT_PARAM_INFO, "")
  Config.settLH:addParam("mana", "Default value = 50", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)

  Config:addSubMenu("Killsteal Settings", "settSteal")
  Config.settSteal:addParam("useq", "Use Q for Killsteal", SCRIPT_PARAM_ONOFF, true)

  Config:addSubMenu("Draw Settings", "settDraw")
  Config.settDraw:addParam("qrange", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
  Config.settDraw:addParam("wrange", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
  Config.settDraw:addParam("erange", "Draw E Range", SCRIPT_PARAM_ONOFF, true)

  Config:addSubMenu("Prediction Settings", "settPred")
  Config.settPred:addParam("pred", "Select Prediction", SCRIPT_PARAM_LIST, 1, predTable)

  UOL:AddToMenu(scriptConfig("OrbWalker", "OrbWalker"))

end

function initPreds()

  if FileExist(LIB_PATH .. "SPrediction.lua") then
    table.insert(predTable, "SPrediction")
    loadedSP = false
  end
  if FileExist(LIB_PATH .. "VPrediction.lua") then
    table.insert(predTable, "VPrediction")
    loadedVP = false
  end
  if FileExist(LIB_PATH .. "HPrediction.lua") then
    table.insert(predTable, "HPrediction")
    loadedHP = false
  end

end

function activePreds()

  if predTable[Config.settPred.pred] == "SPrediction" and not loadedSP then
    require "SPrediction"
    loadedSP, currentPred = true, SPrediction()
    loadedVP, loadedHP = false
  elseif predTable[Config.settPred.pred] == "VPrediction" and not loadedVP then
    require "VPrediction"
    loadedVP, currentPred = true, VPrediction()
    loadedSP, loadedHP = false
  elseif predTable[Config.settPred.pred] == "HPrediction" and not loadedHP then
    require "Hprediction"
    loadedHP, currentPred = true, HPrediction()
    Q = currentPred.Presets["Ezreal"]["Q"]
    W = currentPred.Presets["Ezreal"]["W"]
    loadedSP, loadedVP = false
    end

end

function OnTick()

  activePreds()

  if myHero.dead then return end

  ts:update()
  minionmanager:update()

  if(UOL:GetOrbWalkMode() == "LaneClear") then laneClearQ() end

  if(UOL:GetOrbWalkMode() == "LastHit") then lastHitQ() end

  if(UOL:GetOrbWalkMode() == "Combo") then onCombo() end

  if(UOL:GetOrbWalkMode() == "Harass") then onHarass() end

  killSteal()

end

function killSteal()

  for i=1, heroManager.iCount do
    local enemy = heroManager:getHero(i)
    if(Config.settSteal.useq and myHero:CanUseSpell(_Q) == READY and enemy.health < (getDmg("Q", enemy, myHero)+((myHero.damage)*1.1))-Config.settLC.dmgbuff) and not enemy.dead and enemy.bTargetable then
      local castx, castz = predict(enemy, "Q")
      if(castx ~= nil) then CastSpell(_Q, castx, castz) end
    end
  end

end

function laneClearQ()

  if not myHero:CanUseSpell(_Q) == READY then return end

  if(Config.settLC.useq and ((myHero.mana/myHero.maxMana)*100) > Config.settLC.mana and modeTable[Config.settLC.mode] == "Lasthit") then

    for i, minion in pairs(minionmanager.objects) do

      if(minion ~= nil and minion.bTargetable and minion.valid and minion.team ~= myHero.team and not minion.dead and minion.visible and minion.health < (getDmg("Q", minion, myHero)+((myHero.damage)*1.1))) then

        --PrintChat("LCQ")
        local castx, castz = predict(minion, "Q")
        if(castx ~= nil) then CastSpell(_Q, castx, castz) end
      end
    end
  end

  if(Config.settLC.useq and ((myHero.mana/myHero.maxMana)*100) > Config.settLC.mana and modeTable[Config.settLC.mode] == "Push") then

    for i, minion in pairs(minionmanager.objects) do

      if(minion ~= nil and minion.bTargetable and minion.valid and minion.team ~= myHero.team and not minion.dead and minion.visible and (minion.health < (getDmg("Q", minion, myHero)+((myHero.damage)*1.1)) or (minion.health > (getDmg("Q", minion, myHero)+((myHero.damage)*1.1))+50))) then

        --PrintChat("LCQ")
        local castx, castz = predict(minion, "Q")
        if(castx ~= nil) then CastSpell(_Q, castx, castz) end
      end
    end
  end

end

function lastHitQ()

  if not myHero:CanUseSpell(_Q) == READY then return end

  if(Config.settLH.useq and ((myHero.mana/myHero.maxMana)*100) > Config.settLH.mana) then

    for i, minion in pairs(minionmanager.objects) do

      if(minion ~= nil and minion.bTargetable and minion.valid and minion.team ~= myHero.team and not minion.dead and minion.visible and minion.health < (getDmg("Q", minion, myHero)+((myHero.damage)*1.1))) then

        --PrintChat("LHQ")
        local castx, castz = predict(minion, "Q")
        if(castx ~= nil) then CastSpell(_Q, castx, castz) end
      end
    end
  end

end

function onCombo()

  if(ts.target ~= nil) then

    local enemy = GetTarget()

    if enemy == nil then return end

    if(myHero:CanUseSpell(_Q) == READY and Config.settComb.useq and ((myHero.mana/myHero.maxMana)*100) > Config.settComb.manaq) then
      if enemy.team ~= myHero.team and enemy.bTargetable and enemy.visible == true and not enemy.dead then

        --PrintChat("CoQ")
        local castx, castz = predict(enemy, "Q")
        if(castx ~= nil) then CastSpell(_Q, castx, castz) end
      end
    end

    if(myHero:CanUseSpell(_W) == READY and Config.settComb.usew and ((myHero.mana/myHero.maxMana)*100) > Config.settComb.manaw) then

      if enemy.team ~= myHero.team and enemy.bTargetable and enemy.visible == true and not enemy.dead then

        --PrintChat("CoW")
        local castx, castz = predict(enemy, "W")
        if(castx ~= nil) then CastSpell(_W, castx, castz) end
      end
    end
  end

end

function onHarass()

  if(ts.target ~= nil) then

    local enemy = GetTarget()

    if enemy == nil then return end

    if(myHero:CanUseSpell(_Q) == READY and Config.settHar.useq and ((myHero.mana/myHero.maxMana)*100) > Config.settHar.manaq) then
      if enemy.team ~= myHero.team and enemy.bTargetable and enemy.visible and not enemy.dead then

        --PrintChat("HaQ")
        local castx, castz = predict(enemy, "Q")
        if(castx ~= nil) then CastSpell(_Q, castx, castz) end
      end
    end

    if(myHero:CanUseSpell(_W) == READY and Config.settHar.usew and ((myHero.mana/myHero.maxMana)*100) > Config.settHar.manaw) then

      if enemy.team ~= myHero.team and enemy.bTargetable and enemy.visible and not enemy.dead then

        --PrintChat("HaW")
        local castx, castz = predict(enemy, "W")
        if(castx ~= nil) then CastSpell(_W, castx, castz) end
      end
    end
  end

end

function GetTarget()
  if UOL:GetTarget() ~= nil and UOL:GetTarget().type == myHero.type then return UOL:GetTarget() end

  ts:update()
  if ts.target and not ts.target.dead and ts.target.type == myHero.type then
    return ts.target
  else
    return nil
  end
end

function GetVPred(target, spell)

  if(spell == "Q") then
    local CastPosition, HitChance, Position = currentPred:GetLineCastPosition(target, 0.25, 50, 1200, 2000, myHero, true)
    if CastPosition and HitChance >= 2 and GetDistance(CastPosition) < 1200 then
      return CastPosition.x, CastPosition.z
    end
  elseif(spell == "W") then
    local CastPosition, HitChance, Position = currentPred:GetLineCastPosition(target, 0.25, 50, 900, 1550, myHero, false)
    if CastPosition and HitChance >= 2 and GetDistance(CastPosition) < 900 then
      return CastPosition.x, CastPosition.z
    end
  else return nil, nil
  end

end

function GetSPred(target, spell)

  if(spell == "Q") then
    local CastPosition, HitChance, Position = currentPred:Predict(target, 1200, 2000, 0.25, 50, true, myHero)
    if CastPosition and HitChance >= 2 and GetDistance(CastPosition) < 1200 then
      return CastPosition.x, CastPosition.z
    end
  elseif(spell == "W") then
    local CastPosition, HitChance, Position = currentPred:Predict(target, 900, 1550, 0.25, 70, false, myHero)
    if CastPosition and HitChance >= 2 and GetDistance(CastPosition) < 900 then
      return CastPosition.x, CastPosition.z
    end
  else return nil, nil
  end

end

function GetHPred(target, spell)

  if(spell == "Q") then
    local CastPosition, HitChance = currentPred:GetPredict(Q, target, myHero)
    if CastPosition and HitChance >= 2 and GetDistance(CastPosition) < 1200 then
      return CastPosition.x, CastPosition.z
    end
  elseif(spell == "W") then
    local CastPosition, HitChance = currentPred:GetPredict(W, target, myHero)
    if CastPosition and HitChance >= 2 and GetDistance(CastPosition) < 900 then
      return CastPosition.x, CastPosition.z
    end
  else return nil, nil
  end

end

function predict(target, spell)

  if loadedSP then return GetSPred(target, spell)
  elseif loadedVP then return GetVPred(target, spell)
  elseif loadedHP then return GetHPred(target, spell)
  end

end

function OnDraw()

  if(Config.settDraw.qrange) then
    DrawCircle(myHero.x, myHero.y, myHero.z, 1200, 0x111111)
  end

  if(Config.settDraw.wrange) then
    DrawCircle(myHero.x, myHero.y, myHero.z, 900, 0x111111)
  end

  if(Config.settDraw.erange) then
    DrawCircle(myHero.x, myHero.y, myHero.z, 475, 0x111111)
  end

end