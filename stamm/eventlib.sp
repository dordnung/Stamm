#pragma semicolon 1

public eventlib_Start()
{
	if (otherlib_getGame() == 3)
	{
		HookEvent("teamplay_round_start", eventlib_RoundStart);
		HookEvent("arena_round_start", eventlib_RoundStart);
	}
	else if (otherlib_getGame() == 4)
		HookEvent("dod_round_start", eventlib_RoundStart);
	else
		HookEvent("round_start", eventlib_RoundStart);
	
	HookEvent("player_death", eventlib_PlayerDeath);
}

public Action:eventlib_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ((g_vip_type == 2 || g_vip_type == 4 || g_vip_type == 6 || g_vip_type == 7) && GetClientCount() >= g_min_player)
	{
		for (new client = 1; client <= MaxClients; client++)
		{
			if (clientlib_isValidClient(client))
			{
				if (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)
					pointlib_GivePlayerPoints(client, g_points);
			}
		}
	}
	
	if (g_happyhouron) 
		CPrintToChatAll("%s %t", g_StammTag, "HappyActive", g_points);
}

public Action:eventlib_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (clientlib_isValidClient(userid) && clientlib_isValidClient(client))
	{
		if (g_vip_type == 1 || g_vip_type == 4 || g_vip_type == 5 || g_vip_type == 7)
		{
			if (GetClientCount() >= g_min_player && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3) &&  userid != client && GetClientTeam(userid) != GetClientTeam(client))
				pointlib_GivePlayerPoints(client, g_points);
		}
	}
}