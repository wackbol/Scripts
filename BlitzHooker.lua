if myHero.charName ~= "Blitzcrank" then return end

local SOURCELIB_URL = "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua"
local SOURCELIB_PATH = LIB_PATH.."SourceLib.lua"

if FileExist(SOURCELIB_PATH) then
	require("SourceLib")
else
	DOWNLOADING_SOURCELIB = true
	DownloadFile(SOURCELIB_URL, SOURCELIB_PATH, function() print("Required libraries downloaded successfully, please reload") end)
end

if DOWNLOADING_SOURCELIB then print("Downloading required libraries, please wait...") return end



local RequireI = Require("SourceLib")
RequireI:Add("vPrediction", "https://raw.githubusercontent.com/SidaBoL/Chaos/master/VPrediction.lua")
RequireI:Check()

if RequireI.downloadNeeded == true then return end


local Qrange2, Qrange, Qwidth, Qspeed, Qdelay = 985, 985, 90, 2100, 0.25
local Rrange = 550

local SelectedTarget
local HookedPerson
local Hook

local spells = 
	{
		{name = "CaitlynAceintheHole", menuname = "Caitlyn (R)"},
		{name = "Crowstorm", menuname = "Fiddlesticks (R)"},
		{name = "DrainChannel", menuname = "Fiddlesticks (W)"},
		{name = "GalioIdolOfDurand", menuname = "Galio (R)"},
		{name = "KatarinaR", menuname = "Katarina (R)"},
		{name = "InfiniteDuress", menuname = "WarWick (R)"},
		{name = "AbsoluteZero", menuname = "Nunu (R)"},
		{name = "MissFortuneBulletTime", menuname = "Miss Fortune (R)"},
		{name = "AlZaharNetherGrasp", menuname = "Malzahar (R)"},	
	}
	
	local LastCastedSpell = {}

function OnLoad()
if myHero:GetSpellData(SUMMONER_1).name:find("summonerdot") then Ignite = SUMMONER_1
        elseif myHero:GetSpellData(SUMMONER_2).name:find("summonerdot") then Ignite = SUMMONER_2
    end

	Menu = scriptConfig("Blitzcrank", "Blitzcrank")
	Menu:addParam("AutoIgnR", "Auto R + Ignite!", SCRIPT_PARAM_ONKEYTOGGLE, false, 105)
	Menu:addParam("AutoKS", "Auto R KS!", SCRIPT_PARAM_ONKEYTOGGLE, false, 105)
	Menu:addParam("AutoR", "Ult Selected Target!", SCRIPT_PARAM_ONKEYTOGGLE, false, 105)
	Menu:addParam("AlwaysE", "E If Close!", SCRIPT_PARAM_ONKEYTOGGLE, false, 105)
	Menu:addParam("AutoE", "E After Hook!", SCRIPT_PARAM_ONKEYTOGGLE, false, 105)
	Menu:addParam("Grab", "Grab!", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Menu:addParam("RMS", "Remove Selected Target", SCRIPT_PARAM_ONKEYDOWN, false, 105)
	Menu:addSubMenu("Auto-Interrupt", "AutoInterrupt")
		for i, spell in ipairs(spells) do
			Menu.AutoInterrupt:addParam(spell.name, spell.menuname, SCRIPT_PARAM_ONOFF, true)
		end

 	Menu:addSubMenu("Auto-Grab", "AutoGrab")
	 	Menu.AutoGrab:addParam("AutoD", "Auto-Grab dashing enemies", SCRIPT_PARAM_ONOFF, true)
	 	Menu.AutoGrab:addParam("AutoS", "Auto-Grab immobile enemies", SCRIPT_PARAM_ONOFF, true)
	 	Menu.AutoGrab:addParam("DAG", "Don't auto grab if my health < %", SCRIPT_PARAM_SLICE, 0, 0, 100)

	Menu:addSubMenu("Targets", "Targets")
		for i, enemy in ipairs(GetEnemyHeroes()) do
			Menu.Targets:addParam(enemy.charName, enemy.charName, SCRIPT_PARAM_LIST, 3, {"Don't grab", "Normal grab", "Normal + Auto-grab"})
		end

	Menu:addSubMenu("Drawing", "Drawing")
		Menu.Drawing:addParam("Qrange", "Draw Q range", SCRIPT_PARAM_ONOFF, true)
	VP = VPrediction()
end

function CheckBLHeroCollision(Pos)
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) and GetDistance(enemy) < Qrange * 1.5 and Menu.Targets[enemy.charName] == 1 then
			local proj1, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(Vector(myHero), Pos, Vector(enemy))
			if (GetDistanceSqr(enemy, proj1) <= (VP:GetHitBox(enemy) * 2 + Qwidth) ^ 2) then
				return true
			end
		end
	end
	return false
end


function OnTick()


	if myHero:CanUseSpell(_Q) == READY then
		local HitChance2Targets = {}
		local SelectedTargetInRange = false
		local MinPercentageHP = myHero.health / myHero.maxHealth * 100

		for i, ally in ipairs(GetAllyHeroes()) do
			local mp = ally.health / ally.maxHealth * 100
			if mp <= MinPercentageHP and not ally.dead and GetDistance(ally) < 700 then
				MinPercentageHP = mp
			end
		end

		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, 1500) and Menu.Targets[enemy.charName] >= 1 then
				local CastPosition, HitChance, HeroPosition = VP:GetLineCastPosition(enemy, Qdelay, Qwidth, Qrange, Qspeed, myHero, true)
				
				if MinPercentageHP > Menu.AutoGrab.DAG and HitChance == 5 and Menu.AutoGrab.AutoD and Menu.Targets[enemy.charName] == 3 and GetDistance(myHero.visionPos, CastPosition) < Qrange then
					if not CheckBLHeroCollision(CastPosition) then
						CastSpell(_Q, CastPosition.x, CastPosition.z)
					end
				elseif MinPercentageHP > Menu.AutoGrab.DAG and HitChance == 4 and Menu.AutoGrab.AutoS and Menu.Targets[enemy.charName] == 3 and GetDistance(myHero.visionPos, CastPosition) < Qrange then
					if GetDistance(CastPosition) > 200 and not CheckBLHeroCollision(CastPosition) then
						CastSpell(_Q, CastPosition.x, CastPosition.z)
					end
				elseif MinPercentageHP > Menu.AutoGrab.DAG and HitChance == 3 and Menu.AutoGrab.AutoS and Menu.Targets[enemy.charName] == 3 and GetDistance(myHero.visionPos, CastPosition) < Qrange then
					if GetDistance(CastPosition) > 200 and not CheckBLHeroCollision(CastPosition) then
						CastSpell(_Q, CastPosition.x, CastPosition.z)
					end
				elseif HitChance == 2 and GetDistance(myHero.visionPos, CastPosition) < Qrange then
					if Menu.Targets[enemy.charName] > 1 then
						HitChance2Targets[enemy.networkID] = {unit = enemy, CastPosition = CastPosition}
					end
					if Menu.Grab and SelectedTarget and enemy.networkID == SelectedTarget.networkID then
						CastSpell(_Q, CastPosition.x, CastPosition.z)
					end
				end

				if SelectedTarget and enemy.networkID == SelectedTarget.networkID then
					SelectedTargetInRange = true
				end
			end
		end

		if not SelectedTargetInRange and Menu.Grab then
			local BestTarget = nil
			local MinL = math.huge
			for nid, target in pairs(HitChance2Targets) do
				local L = target.unit.health / myHero:CalcMagicDamage(target.unit, 100)
				if L < MinL then
					BestTarget = target.unit
					MinL = L
				end
			end
			if BestTarget then
				if not CheckBLHeroCollision(HitChance2Targets[BestTarget.networkID].CastPosition) then
					CastSpell(_Q, HitChance2Targets[BestTarget.networkID].CastPosition.x, HitChance2Targets[BestTarget.networkID].CastPosition.z)
				end
			end
		end
	end

if Menu.RMS then
if SelectedTarget ~= nil then
SelectedTarget = nil
print("<font color=\"#FF0000\">Blitzcrank: Targets Un-Selected Grabbing Best Target </font>")
end
end

if Menu.Grab and Menu.AlwaysE then
if myHero:CanUseSpell(_E) == READY then
for i, enemy in ipairs(GetEnemyHeroes()) do
if ValidTarget(enemy,200) then
CastSpell(_E)
end
end
end
end

if Menu.AutoR then
if myHero:CanUseSpell(_R) == READY then
if ValidTarget(SelectedTarget,500) then
CastSpell(_R)
end
end
end

if Menu.AutoKS then
if myHero:CanUseSpell(_R) == READY then
for i, enemy in ipairs(GetEnemyHeroes()) do
if ValidTarget(enemy,550) and getDmg("R",enemy,myHero) > enemy.health then
CastSpell(_R)
end
end
end
end

if Menu.AutoIgnR then
if myHero:CanUseSpell(_R) == READY then
if (Ignite ~= nil and myHero:CanUseSpell(Ignite) == READY) then
for i, enemy in ipairs(GetEnemyHeroes()) do
RDamage = getDmg("R",enemy,myHero)
IgniteDamage = 50 + (20 * myHero.level)
if ValidTarget(enemy,600) and RDamage + IgniteDamage > enemy.health then
CastSpell(Ignite, enemy)
CastSpell(_R)
end
end
end
end
end

if Menu.AutoE then 
if (Hook ~= nil and HookedPerson ~= nil) then
		CastSpell(_E)
end
end


if myHero:CanUseSpell(_R) == READY then
		for i, spell in ipairs(spells) do
			if Menu.AutoInterrupt[spell.name] then
				for j, LastCast in pairs(LastCastedSpell) do
					if LastCast.name == spell.name:lower() and (os.clock() - LastCast.time) < 3 and GetDistance(LastCast.caster.visionPos, myHero.visionPos) < Rrange and ValidTarget(LastCast.caster) then
						CastSpell(_R, myHero.x, myHero.z)
						break
					end
				end
			end
		end
	end
end


function OnDraw()
	if Menu.Drawing.Qrange then
		DrawCircle2(myHero.x, myHero.y, myHero.z, Qrange, ARGB(255, 0, 255, 0))
	end
	
	if SelectedTarget ~= nil then
		DrawCircle2(SelectedTarget.x, SelectedTarget.y, SelectedTarget.z, 100, ARGB(255, 255, 0, 0))

		if Menu.Drawing.DrawWP then
			wayPointManager:DrawWayPoints(SelectedTarget)
		end
		if Menu.Drawing.DrawWPR then
        	DrawText3D(tostring(wayPointManager:GetWayPointChangeRate(SelectedTarget)), SelectedTarget.x, SelectedTarget.y, SelectedTarget.z, 30, ARGB(255,0,255,0), true)
		end
	end

end



function OnCreateObj(object)
	if object.name:lower():find("fistreturn") then
Hook = object
		for i, enemy in ipairs(GetEnemyHeroes()) do
	 		print(GetDistanceSqr(enemy, Hook))
			if enemy and GetDistanceSqr(enemy, Hook) < 10000 then
		  		HookedPerson = enemy
				DelayAction(function() HookedPerson = nil end, 1.5)
		 		break
			end
		end
	end
end

function OnDeleteObj(object)
	if object.name:lower():find("fistreturn") then
		Hook = nil
end
end


function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
	radius = radius or 300
	quality = math.max(8,math.floor(180/math.deg((math.asin((chordlength/(2*radius)))))))
	quality = 2 * math.pi / quality
	radius = radius*.92
	local points = {}
	for theta = 0, 2 * math.pi + quality, quality do
		local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
		points[#points + 1] = D3DXVECTOR2(c.x, c.y)
	end
	DrawLines2(points, width or 1, color or 4294967295)
end


function DrawCircle2(x, y, z, radius, color)
	local vPos1 = Vector(x, y, z)
	local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
	local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
	local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
	if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y })  then
		DrawCircleNextLvl(x, y, z, radius, 1, color, 75)	
	end
end

function OnWndMsg(Msg, Key)
	if Msg == WM_LBUTTONDOWN then
		local minD = 0
		local starget = nil
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) then
				if GetDistance(enemy, mousePos) <= minD or starget == nil then
					minD = GetDistance(enemy, mousePos)
					starget = enemy
				end
			end
		end
		
		if starget and minD < 500 then
			if SelectedTarget and starget.charName == SelectedTarget.charName then
				SelectedTarget = nil
	 			print("<font color=\"#FF0000\">Blitzcrank: "..starget.charName.." Un-Selected </font>")
			else
				SelectedTarget = starget
				print("<font color=\"#FF0000\">Blitzcrank: Primary Target selected: "..starget.charName.."</font>")
			end
		end
	end
end
