if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("TTT2CopycatFilesCorpseUpdate")
end

roles.InitCustomTeam(ROLE.name, {
	icon = "vgui/ttt/dynamic/roles/icon_anon",
	color = Color(140, 140, 140, 255)
})

function ROLE:PreInitialize()
	self.color = Color(140, 140, 140, 255)
	self.abbr = "anon"

	--Scoring is less punishing here than on other evil roles, since Anonymous know little about their own team.
	--teamKillsMultiplier is the same as Innocents. killsMultiplier is the same as Serial Killer.
	self.score.teamKillsMultiplier = -8
	self.score.killsMultiplier = 5

	self.preventFindCredits = false

	self.fallbackTable = {}

	--Anonymous doesn't know who their fellow teammates are, nor do they have an open channel of communication
	self.unknownTeam = true
	--I think setting unknownTeam to true should be enough, but we set these other params just to be safe
	self.disabledTeamChat = true
	self.disabledTeamChatRecv = true
	self.disabledTeamVoice = true
	self.disabledTeamVoiceRecv = true

	self.defaultTeam = TEAM_ANONYMOUS
	self.defaultEquipment = SPECIAL_EQUIPMENT

	--The player's role is not broadcasted to all other players.
	self.isPublicRole = false

	--The Copycat will always be able to inspect bodies, confirm them, and be called to them.
	--Does not give them a Detective hat. That would only happen if isPublicRole is also set.
	self.isPolicingRole = true

	--Traitor like behavior: Able to see missing in action players as well as the haste mode timer.
	self.isOmniscientRole = true

	-- ULX ConVars
	self.conVarData = {
		--This is the crux of the Anonymous role's power: 0.35 pct matches traitor pct on BMF server, and presumably closely matches others (TTT2 uses 0.4 by default).
		--maximum set to 3 means that 3 players will have this role at the start of the game.
		pct = 1.0,
		maximum = 3,
		minPlayers = 9,
		random = 30,
		traitorButton = 0,

		--The Anonymous starts with 1 credit, but otherwise gains credits in a similar manner as a traitor.
		credits = 1,
		creditsAwardDeadEnable = 1,
		creditsAwardKillEnable = 1,
		shopFallback = SHOP_FALLBACK_TRAITOR,

		togglable = true
	}
end

local function IsInSpecDM(ply)
	if SpecDM and (ply.IsGhost and ply:IsGhost()) then
		return true
	end

	return false
end

if SERVER then
	--Used to prevent informing Anonymous roles twice (once during role setup before the round has begun, and again during the point where it begins)
	--Note: GiveRoleLoadout occurs during ROUND_ACTIVE, so we can't rely on that alone.
	local ANON_SETUP_COMPLETE = nil

	local function PlyIsLivingAnonymous(ply)
		return (IsValid(ply) and ply:IsPlayer() and ply:Alive() and not IsInSpecDM(ply) and ply:GetSubRole() == ROLE_ANONYMOUS)
	end

	local function GetLivingAnonymous()
		local alive_anon_id_list = {}

		for _, ply in ipairs(player.GetAll()) do
			if PlyIsLivingAnonymous(ply) then
				alive_anon_id_list[#alive_anon_id_list + 1] = ply:SteamID64()
			end
		end

		return alive_anon_id_list
	end

	local function RandomizeTable(tbl)
		--TTT2 adds in table.Randomize(tbl), but for some reason it is returning nil. Here we have a copy of that function, which for some reason works. Strange.
		local out_tbl = {}

		while #tbl > 0 do
			out_tbl[#out_tbl + 1] = table.remove(tbl, math.random(#tbl))
		end

		return out_tbl
	end

	local function GetNameFromSteamID64(steam_id)
		local name = "[UNKNOWN PLAYER]"

		for _, ply_i in ipairs(player.GetAll()) do
			if ply_i:SteamID64() == steam_id then
				name = ply_i:GetName()
				break
			end
		end

		return name
	end

	local function GetPlayerFromSteamID64(steam_id)
		local ply = nil

		for _, ply_i in ipairs(player.GetAll()) do
			if ply_i:SteamID64() == steam_id then
				ply = ply_i
				break
			end
		end

		return ply
	end

	local function GetNumPlayersWithRole(role)
		local plys_with_role = 0

		for _, ply in ipairs(player.GetAll()) do
			if ply:GetSubRole() == role then
				plys_with_role = plys_with_role + 1
			end
		end

		return plys_with_role
	end

	local function InformAnonymousAboutTeammates(ply)
		local num_anonymous = GetNumPlayersWithRole(ROLE_ANONYMOUS)
		local max_num_known = GetConVar("ttt2_anon_max_num_known"):GetInt()
		if max_num_known >= num_anonymous - 1 then
			--max_num_known must be less than the # of teammates that the anonymous currently has.
			--Otherwise, all Anonymous players at the beginning of the round would know who each other are, which defeats the purpose of the role.
			max_num_known = num_anonymous - 2
		end

		if not IsValid(ply) or not ply:IsPlayer() or max_num_known <= 0 or (ply.anon_known_ids and ply.anon_num_ids >= max_num_known) then
			return
		end

		if not ply.anon_known_ids then
			ply.anon_known_ids = {}
			--Note: #ply.anon_known_ids won't provide the number of items in a set. It only works if each item is a number because lua is dumb
			ply.anon_num_ids = 0
		end

		local alive_anon_id_list = GetLivingAnonymous(ply)
		alive_anon_id_list = RandomizeTable(alive_anon_id_list)

		--UNCOMMENT FOR DEBUGGING
		--local debug_alive_anon_name_list_str = "ANON_DEBUG InformAnonymousAboutTeammates: " .. ply:GetName() .. " might learn the role of [ "
		--for _, anon_id in ipairs(alive_anon_id_list) do
		--	debug_alive_anon_name_list_str = debug_alive_anon_name_list_str .. GetNameFromSteamID64(anon_id) .. " "
		--end
		--print(debug_alive_anon_name_list_str .. "]")

		for _, anon_id in ipairs(alive_anon_id_list) do
			if ply:SteamID64() ~= anon_id and not ply.anon_known_ids[anon_id] then
				ply.anon_known_ids[anon_id] = true
				ply.anon_num_ids = ply.anon_num_ids + 1
				events.Trigger(EVENT_ANON_INFORM, ply, GetPlayerFromSteamID64(anon_id))

				if ply.anon_num_ids >= max_num_known then
					break
				end
			end
		end

		--UNCOMMENT FOR DEBUGGING
		--debug_anon_known_ids_str = "ANON_DEBUG InformAnonymousAboutTeammates: " .. ply:GetName() .. " Knows the role and team of [ "
		--for _, ply_i in ipairs(player.GetAll()) do
		--	if IsValid(ply_i) and ply.anon_known_ids and ply.anon_known_ids[ply_i:SteamID64()] then
		--		debug_anon_known_ids_str = debug_anon_known_ids_str .. ply_i:GetName() .. " "
		--	end
		--end
		--print(debug_anon_known_ids_str .. "]\n")
	end

	function ROLE:GiveRoleLoadout(ply, isRoleChange)
		--At the start of the round, don't inform anonymous of their fellow teammates if we're still figuring out who is anonymous.
		--If a player has gotten this role mid-game, maybe inform them about 1+ teammates.
		if ANON_SETUP_COMPLETE and (not ply.anon_known_ids or ply.anon_num_ids <= 0) and GetRoundState() == ROUND_ACTIVE then
			--print("ANON_DEBUG GiveRoleLoadout: Calling InformAnonymousAboutTeammates for " .. ply:GetName())
			InformAnonymousAboutTeammates(ply)
		end
	end

	local function ResetAnonymousForServer()
		ANON_SETUP_COMPLETE = nil
		for _, ply in ipairs(player.GetAll()) do
			--Don't reset anon_known_ids at start of round if the player is anonymous, as that will overwrite the logic in GiveRoleLoadout.
			if GetRoundState() == ROUND_POST or ply:GetSubRole() ~= ROLE_ANONYMOUS then
				ply.anon_known_ids = nil
				ply.anon_num_ids = nil
			end
		end
	end

	hook.Add("TTTBeginRound", "TTTBeginRoundAnonymousForServer", function()
		ResetAnonymousForServer()

		--HACK: For some reason TTT2 is not honoring the "maximum" and "pct" fields My understanding is that:
		--  If we randomly select this role with "random", then it must be considered during role selection. I believe this one is working properly.
		--  A maximum of 3 means that up to 3 players can have this role.
		--  A pct of 1.0 means that all players should have this role (after detectives and traitors have been selected)
		--  Combined, a maximum of 3 and a pct of 1.0 means that exactly 3 players will have this role, provided that there are enough players leftover
		--Currently, I see that usually just 1 player receives this role, which is bad. This role's gimmick requires that a chunk of the players have this role.
		--So here we hack it by changing the roles of base innocents to Anonymous, until we hit maximum.
		local num_anonymous = GetNumPlayersWithRole(ROLE_ANONYMOUS)
		local ideal_num_anonymous = math.min(#player.GetAll() * GetConVar("ttt_anonymous_pct"):GetFloat(), GetConVar("ttt_anonymous_max"):GetInt())
		local rand_ply_list = RandomizeTable(player.GetAll())
		if num_anonymous > 0 and num_anonymous < ideal_num_anonymous then
			for _, ply in ipairs(rand_ply_list) do
				if ply:GetSubRole() == ROLE_INNOCENT then
					ply:SetRole(ROLE_ANONYMOUS)
					num_anonymous = num_anonymous + 1
					events.Trigger(EVENT_ANON_FORCE, ply)

					if num_anonymous >= ideal_num_anonymous then
						break
					end
				end
			end
		end

		ANON_SETUP_COMPLETE = true

		for _, ply in ipairs(player.GetAll()) do
			if PlyIsLivingAnonymous(ply) then
				--print("ANON_DEBUG TTTBeginRound: Calling InformAnonymousAboutTeammates for " .. ply:GetName())
				InformAnonymousAboutTeammates(ply)
			end
		end

	end)

	hook.Add("TTT2SpecialRoleSyncing", "TTT2SpecialRoleSyncingAnonymous", function(ply, tbl)
		--The ply in the args should know about other Anonymous players whose role they are supposed to be informed about.
		--Notice that we cease sending this information if either player stops being Anonymous.
		if GetRoundState() == ROUND_POST or not IsValid(ply) or ply:GetSubRole() ~= ROLE_ANONYMOUS then
			return
		end

		for ply_i in pairs(tbl) do
			if ply.anon_known_ids and ply.anon_known_ids[ply_i:SteamID64()] and ply_i:GetSubRole() == ROLE_ANONYMOUS then
				tbl[ply_i] = {ROLE_ANONYMOUS, ply_i:GetTeam()}
			end
		end
	end)

	hook.Add("TTT2ModifyRadarRole", "TTT2ModifyRadarRoleAnonymous", function(ply, target)
		--Same logic as used in TTT2SpecialRoleSyncing hook
		if GetRoundState() == ROUND_POST or not IsValid(ply) or ply:GetSubRole() ~= ROLE_ANONYMOUS then
			return
		end

		if ply.anon_known_ids and ply.anon_known_ids[target:SteamID64()] and target:GetSubRole() == ROLE_ANONYMOUS then
			return ROLE_ANONYMOUS, target:GetTeam()
		end
	end)

	hook.Add("TTTPrepareRound", "TTTPrepareRoundAnonymousForServer", ResetAnonymousForServer)
	hook.Add("TTTEndRound", "TTTEndRoundAnonymousForServer", ResetAnonymousForServer)
end
