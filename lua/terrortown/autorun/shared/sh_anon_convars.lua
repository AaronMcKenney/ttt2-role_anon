--ConVar syncing
CreateConVar("ttt2_anon_max_num_known", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})

hook.Add("TTTUlxDynamicRCVars", "TTTUlxDynamicAnonymousCVars", function(tbl)
	tbl[ROLE_ANONYMOUS] = tbl[ROLE_ANONYMOUS] or {}

	--# The maximum number of fellow living Anonymous players that the player is informed about upon spawn.
	--  Note1: When an Anonymous spawns, there will always be at least one Anonymous player that they will not be told about.
	--  Note2: This only applies to players with the Anonymous ROLE. A player who joins the Anonymous TEAM without also having the role tells them nothing.
	--  Note3: A player who gains this role mid-round will not be told about dead Anonymous players.
	--  ttt2_anon_max_num_known [0..n] (default: 1)
	table.insert(tbl[ROLE_ANONYMOUS], {
		cvar = "ttt2_anon_max_num_known",
		slider = true,
		min = 0,
		max = 32,
		decimal = 0,
		desc = "ttt2_anon_max_num_known (Def: 1)"
	})
end)

hook.Add("TTT2SyncGlobals", "AddAnonymousGlobals", function()
	SetGlobalInt("ttt2_anon_max_num_known", GetConVar("ttt2_anon_max_num_known"):GetInt())
end)

cvars.AddChangeCallback("ttt2_anon_max_num_known", function(name, old, new)
	SetGlobalInt("ttt2_anon_max_num_known", tonumber(new))
end)
