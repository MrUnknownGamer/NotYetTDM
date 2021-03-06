-- Building error reporting
-- Damagelog:Error(debug.getinfo(1).source, debug.getinfo(1).currentline, "connection error")
function Damagelog:Error(file, line, strg)
	print("Damagelogs: ERROR - "..file.." ("..line..") - "..strg)
end


AddCSLuaFile("damagelogs/shared/config.lua")
AddCSLuaFile("damagelogs/shared/sync.lua")
AddCSLuaFile("damagelogs/shared/weapontable.lua")

AddCSLuaFile("damagelogs/client/colors.lua")

include("damagelogs/shared/config.lua")
include("damagelogs/shared/sync.lua")
include("damagelogs/shared/weapontable.lua")

include("damagelogs/server/damageinfos.lua")
include("damagelogs/server/weapontable.lua")

-- Adding language files for download
local lFiles = file.Find("damagelogs/client/lang/*.lua", "LUA")
for i=1, #lFiles do
	AddCSLuaFile("damagelogs/client/lang/"..lFiles[i])
end


if GetConVar("Damagelog_EnableAutoslay"):GetBool() then
	-- include("damagelogs/server/rdm_manager.lua")
end

if GetConVar("Damagelog_EnableAutojail"):GetBool() then
	-- include("damagelogs/server/sh_rdm_manager.lua")
end

if GetConVar("Damagelog_EnableAutokarma"):GetBool() then
	-- include("damagelogs/server/sh_rdm_manager.lua")
end

if GetConVar("Damagelog_RDMManagerEnabled"):GetBool() then
	AddCSLuaFile("damagelogs/shared/rdm_manager.lua")
	AddCSLuaFile("damagelogs/client/rdm_manager.lua")
	include("damagelogs/shared/rdm_manager.lua")
	include("damagelogs/server/rdm_manager.lua")
	-- resource.AddFile("sound/ui/vote_failure.wav")
	-- resource.AddFile("sound/ui/vote_yes.wav")
end

-- Including Net Messages

util.AddNetworkString("DL_AskDamagelog")
util.AddNetworkString("DL_SendDamagelog")
util.AddNetworkString("DL_SendRoles")
-- util.AddNetworkString("DL_RefreshDamagelog")
util.AddNetworkString("DL_InformSuperAdmins")
-- util.AddNetworkString("DL_Ded")


Damagelog.DamageTable = Damagelog.DamageTable or {}
Damagelog.OldTables = Damagelog.OldTables or {}
Damagelog.ShootTables = Damagelog.ShootTables or {}
Damagelog.Roles = Damagelog.Roles or {}



function Damagelog:CheckDamageTable()
	if Damagelog.DamageTable[1] == "empty" then
		table.Empty(Damagelog.DamageTable)
	end
end

function Damagelog:TTTBeginRound()
	self.Time = 0
	if not timer.Exists("Damagelog_Timer") then
		timer.Create("Damagelog_Timer", 1, 0, function()
			self.Time = self.Time + 1
		end)
	end
	if IsValid(self:GetSyncEnt()) then
		local rounds = self:GetSyncEnt():GetPlayedRounds()
		self:GetSyncEnt():SetPlayedRounds(rounds + 1)
		if self.add_old then
			self.OldTables[rounds] = table.Copy(self.DamageTable)
		else
			self.add_old = true
		end
		self.ShootTables[rounds + 1] = {}
		self.Roles[rounds + 1] = {}
		for k,v in pairs(player.GetAll()) do
			self.Roles[rounds+1][v:Nick()] = v:GetRole()
		end
		self.CurrentRound = rounds + 1
	end
	self.DamageTable = { "empty" }
	self.OldLogsInfos = {}
	for k,v in pairs(player.GetAll()) do
		self.OldLogsInfos[v:Nick()] = {
			steamid = v:SteamID(),
			steamid64 = v:SteamID64(),
			role = v:GetRole()
		}
	end
end
hook.Add("TTTBeginRound", "TTTBeginRound_Damagelog", function()
	Damagelog:TTTBeginRound()
end)

-- rip from TTT
-- this one will return a string
function Damagelog:WeaponFromDmg(dmg)
	local inf = dmg:GetInflictor()
	local wep = nil
	if IsValid(inf) then
		if inf:IsWeapon() or inf.Projectile then
			wep = inf
		elseif dmg:IsDamageType(DMG_BLAST) then
			wep = "#Damagelog.DMG_BLAST"
		elseif dmg:IsDamageType(DMG_DIRECT) or dmg:IsDamageType(DMG_BURN) then
			wep = "#Damagelog.DMG_BURN"
		elseif dmg:IsDamageType(DMG_CRUSH) then
			wep = "falling or prop damage"
		elseif dmg:IsDamageType(DMG_SLASH) then
			wep = "a sharp object"
		elseif dmg:IsDamageType(DMG_CLUB) then
			wep = "clubbed to death"
		elseif dmg:IsDamageType(DMG_SHOCK) then
			wep = "an electric shock"
		elseif dmg:IsDamageType(DMG_ENERGYBEAM) then
			wep = "a laser"
		elseif dmg:IsDamageType(DMG_SONIC) then
			wep = "a teleport collision"
		elseif dmg:IsDamageType(DMG_PHYSGUN) then
			wep = "a massive bulk"
		elseif inf:IsPlayer() then
			wep = inf:GetActiveWeapon()
			if not IsValid(wep) then
				wep = IsValid(inf.dying_wep) and inf.dying_wep
			end
		end
	end
	if type(wep) != "string" then
		return IsValid(wep) and wep:GetClass()
	else
		return wep
	end
end

function Damagelog:SendDamagelog(ply, round)
	if self.MySQL_Error and not ply.DL_MySQL_Error then
		-- ply:ChatPrint("Warning : Damagelogs MySQL connection error. The error has been saved on data/damagelog/mysql_error.txt")
		Damagelog:Error(debug.getinfo(1).source, debug.getinfo(1).currentline, "mysql connection error")
		ply.DL_MySQL_Error = true
	end
	local damage_send
	local roles = self.Roles[round]
	local current = false
	if round == -1 then
		if not self.last_round_map then return end
		if GetConVar("Damagelog_UseMySQL"):GetBool() and self.MySQL_Connected then
			local query = self.database:query("SELECT UNCOMPRESS(damagelog) FROM damagelog_oldlogs WHERE date = "..self.last_round_map)
			query.onSuccess = function(q)
				local data = q:getData()
				if data and data[1] then
					local encoded = data[1]["UNCOMPRESS(damagelog)"]
					local decoded = util.JSONToTable(encoded)
					if not decoded then
						decoded = { roles = {}, DamageTable = {"empty"} }
					end
					self:TransferLogs(decoded.DamageTable, ply, round, decoded.roles)
				end
			end
			query:start()
		elseif not GetConVar("Damagelog_UseMySQL"):GetBool() then
			local query = sql.QueryValue("SELECT damagelog FROM damagelog_oldlogs WHERE date = "..self.last_round_map)
			if not query then return end
			local decoded = util.JSONToTable(query)
			if not decoded then
				decoded = { roles = {}, DamageTable = {"empty"} }
			end
			self:TransferLogs(decoded.DamageTable, ply, round, decoded.roles)		
		end
	elseif round == self:GetSyncEnt():GetPlayedRounds() then
		if not ply:CanUseDamagelog() then return end
		damage_send = self.DamageTable
		current = true
	else
		damage_send = self.OldTables[round]
	end
	if not damage_send then 
		damage_send = { "empty" } 
	end
	self:TransferLogs(damage_send, ply, round, roles, current)
end

function Damagelog:TransferLogs(damage_send, ply, round, roles, current)
	net.Start("DL_SendRoles")
	net.WriteTable(roles or {})
	net.Send(ply)
	local count = #damage_send
	for k,v in ipairs(damage_send) do
		net.Start("DL_SendDamagelog")
		if v == "empty" then
			net.WriteUInt(1, 1)
		elseif v == "ignore" then
			if count == 1 then
				net.WriteUInt(1, 1)
			else
				net.WriteUInt(0,1)
				net.WriteTable({"ignore"})
			end
		else
			net.WriteUInt(0, 1)
			net.WriteTable(v)
		end
		net.WriteUInt(k == count and 1 or 0, 1)
		net.Send(ply)
	end
	if current and ply:IsActive() then
		net.Start("DL_InformSuperAdmins")
		net.WriteString(ply:Nick())
		local filter = RecipientFilter()
		filter:AddPlayer()
		if GetConVar("Damagelog_AbuseMessageMode"):GetBool() then
			net.Send(player.GetHumans())
		else
			local superadmins = {}
			for k,v in pairs(player.GetHumans()) do -- We think, bots shouldn't be admin
				if v:IsSuperAdmin() then
					table.insert(superadmins, v)
				end
			end
			net.Send(superadmins)
		end
	end
end

net.Receive("DL_AskDamagelog", function(_, ply)
	local roundnumber = net.ReadInt(20)
	if (IsValid(roundnumber) and roundnumber > -1) then
		Damagelog:SendDamagelog(ply, roundnumber)
	else
		Damagelog:Error(debug.getinfo(1).source, debug.getinfo(1).currentline, "Roundnumber invalid or negative")
	end
end)

hook.Add("PlayerDeath", "Damagelog_PlayerDeathLastLogs", function(ply)
	if GAMEMODE.round_state == ROUND_ACTIVE and Damagelog.Time then
		local found_dmg = {}
		for k,v in ipairs(Damagelog.DamageTable) do
			if (type(v) == "table" and (v.time >= Damagelog.Time - 10) and (v.time <= Damagelog.Time)) then
				table.insert(found_dmg, v)
			end
		end
		if not ply.DeathDmgLog then
			ply.DeathDmgLog = {}
		end
		ply.DeathDmgLog[Damagelog.CurrentRound] = found_dmg
	end
end)