public bool:clientlib_isValidClient(client)
{
	if (client > 0 && client <= MaxClients)
	{
		if (IsClientConnected(client))
		{
			if (IsClientInGame(client))
			{
				if (IsClientAuthorized(client))
				{
					if (!IsClientSourceTV(client) && !IsClientReplay(client) && !IsFakeClient(client))
					{
						new String:steamid[32];
						
						GetClientAuthString(client, steamid, sizeof(steamid));
						
						if (!StrEqual(steamid, "BOT") && !StrEqual(steamid, "STEAM_ID_PENDING"))
						{
							if (g_ClientReady[client]) return true;
						}
					}
				}
			}
		}
	}
	return false;
}

public bool:clientlib_isValidClient_PRE(client)
{
	if (client > 0 && client <= MaxClients)
	{
		if (IsClientConnected(client))
		{
			if (IsClientInGame(client))
			{
				if (IsClientAuthorized(client))
				{
					if (!IsClientSourceTV(client) && !IsClientReplay(client) && !IsFakeClient(client))
					{
						new String:steamid[32];
						
						GetClientAuthString(client, steamid, sizeof(steamid));
						
						if (!StrEqual(steamid, "BOT") && !StrEqual(steamid, "STEAM_ID_PENDING")) return true;
					}
				}
			}
		}
	}
	return false;
}

public OnClientPostAdminCheck(client)
{
	if (clientlib_isValidClient_PRE(client)) sqllib_InsertPlayer(client);
}

public clientlib_ClientReady(client)
{
	if (clientlib_isValidClient_PRE(client))
	{
		g_ClientReady[client] = true;
		
		clientlib_CheckVip(client);
		
		nativelib_ClientReady(client);
		
		if (g_giveflagadmin) clientlib_CheckFlagAdmin(client);
		if (g_join_show) CreateTimer(5.0, pointlib_ShowPoints2, client);
		
		clientlib_CheckPlayers();
	}
}

public OnClientDisconnect(client)
{
	clientlib_CheckPlayers();
}

public bool:clientlib_IsAdmin(client)
{
	if (clientlib_isValidClient(client))
	{
		new AdminId:adminid = GetUserAdmin(client);
			
		if (StrEqual(g_adminflag, "a")) return GetAdminFlag(adminid, Admin_Reservation);
		if (StrEqual(g_adminflag, "b")) return GetAdminFlag(adminid, Admin_Generic);
		if (StrEqual(g_adminflag, "c")) return GetAdminFlag(adminid, Admin_Kick);
		if (StrEqual(g_adminflag, "d")) return GetAdminFlag(adminid, Admin_Ban);
		if (StrEqual(g_adminflag, "e")) return GetAdminFlag(adminid, Admin_Unban);
		if (StrEqual(g_adminflag, "f")) return GetAdminFlag(adminid, Admin_Slay);
		if (StrEqual(g_adminflag, "g")) return GetAdminFlag(adminid, Admin_Changemap);
		if (StrEqual(g_adminflag, "h")) return GetAdminFlag(adminid, Admin_Convars);
		if (StrEqual(g_adminflag, "i")) return GetAdminFlag(adminid, Admin_Config);
		if (StrEqual(g_adminflag, "j")) return GetAdminFlag(adminid, Admin_Chat);
		if (StrEqual(g_adminflag, "k")) return GetAdminFlag(adminid, Admin_Vote);
		if (StrEqual(g_adminflag, "l")) return GetAdminFlag(adminid, Admin_Password);
		if (StrEqual(g_adminflag, "m")) return GetAdminFlag(adminid, Admin_RCON);
		if (StrEqual(g_adminflag, "n")) return GetAdminFlag(adminid, Admin_Cheats);
		if (StrEqual(g_adminflag, "o")) return GetAdminFlag(adminid, Admin_Custom1);
		if (StrEqual(g_adminflag, "p")) return GetAdminFlag(adminid, Admin_Custom2);
		if (StrEqual(g_adminflag, "q")) return GetAdminFlag(adminid, Admin_Custom3);
		if (StrEqual(g_adminflag, "r")) return GetAdminFlag(adminid, Admin_Custom4);
		if (StrEqual(g_adminflag, "s")) return GetAdminFlag(adminid, Admin_Custom5);
		if (StrEqual(g_adminflag, "t")) return GetAdminFlag(adminid, Admin_Custom6);
		if (StrEqual(g_adminflag, "z")) return GetAdminFlag(adminid, Admin_Root);
	}
	
	return false;
}

public clientlib_CheckFlagAdmin(client)
{
	new AdminId:adminid = GetUserAdmin(client);
	
	if (g_giveflagadmin == 1 && GetAdminFlag(adminid, Admin_Custom1)) clientlib_GiveFastVIP(client);
	if (g_giveflagadmin == 2 && GetAdminFlag(adminid, Admin_Custom2)) clientlib_GiveFastVIP(client);
	if (g_giveflagadmin == 3 && GetAdminFlag(adminid, Admin_Custom3)) clientlib_GiveFastVIP(client);
	if (g_giveflagadmin == 4 && GetAdminFlag(adminid, Admin_Custom4)) clientlib_GiveFastVIP(client);
	if (g_giveflagadmin == 5 && GetAdminFlag(adminid, Admin_Custom5)) clientlib_GiveFastVIP(client);
	if (g_giveflagadmin == 6 && GetAdminFlag(adminid, Admin_Custom6)) clientlib_GiveFastVIP(client);
}

public clientlib_GiveFastVIP(client)
{
	if (g_playerlevel[client] < g_levels)
	{
		g_playerpoints[client] = g_LevelPoints[g_levels-1];
		clientlib_CheckVip(client);
	}
}

public clientlib_CheckVip(client)
{
	if (sqllib_db != INVALID_HANDLE && clientlib_isValidClient(client))
	{
		new String:steamid[64];
		new String:query[256];
		
		GetClientAuthString(client, steamid, sizeof(steamid));
		
		Format(query, sizeof(query), "SELECT payed FROM %s WHERE steamid='%s'", g_tablename, steamid);
		if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		
		SQL_TQuery(sqllib_db, sqllib_CheckPayed, query, client);
	}
}

public clientlib_CheckVip_Post(client)
{
	if (sqllib_db != INVALID_HANDLE && clientlib_isValidClient(client))
	{
		new String:steamid[64];
		new clientpoints = g_playerpoints[client];
		
		GetClientAuthString(client, steamid, sizeof(steamid));
		
		new levelstufe = levellib_PointsToID(clientpoints);
		if (levelstufe == -1) return;
		
		if (levelstufe > 0 && levelstufe != g_playerlevel[client])
		{		
			new String:name[MAX_NAME_LENGTH+1];
			new String:setquery[256];	
			
			g_playerlevel[client] = levelstufe;
			
			GetClientName(client, name, sizeof(name));
			
			CPrintToChatAll("%s %T", g_StammTag, "LevelNowVIP", LANG_SERVER, name, g_LevelName[levelstufe-1]);
			CPrintToChat(client, "%s %T", g_StammTag, "JoinVIP", LANG_SERVER);
			
			nativelib_PublicPlayerBecomeVip(client);
			
			if (!StrEqual(g_lvl_up_sound, "0"))
			{
				if (otherlib_getGame() != 2) EmitSoundToAll(g_lvl_up_sound);
				else
				{
					for (new i=0; i <= MaxClients; i++)
					{
						if (clientlib_isValidClient(i)) ClientCommand(i, "play %s", g_lvl_up_sound);
					}
				}
			}

			Format(setquery, sizeof(setquery), "UPDATE %s SET level='%i' WHERE steamid='%s'", g_tablename, levelstufe, steamid);
			
			if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", setquery);
			
			SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, setquery);
		}
		else
		{
			if (levelstufe == 0 && levelstufe != g_playerlevel[client])
			{
				new String:queryback[512];
								
				g_playerlevel[client] = 0;

				Format(queryback, sizeof(queryback), "UPDATE %s SET level=0 WHERE steamid='%s'", g_tablename, steamid);
				
				if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", queryback);
				
				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, queryback);
			}
		}
		clientlib_SavePlayer(client);
	}
}

public clientlib_SavePlayer(client)
{
	if (sqllib_db != INVALID_HANDLE && clientlib_isValidClient(client))
	{
		decl String:query[2024];
		new String:steamid[64];
		
		GetClientAuthString(client, steamid, sizeof(steamid));
		
		if (g_allow_change)
		{
			Format(query, sizeof(query), "UPDATE %s SET points=%i ", g_tablename, g_playerpoints[client]);
			for (new i=0; i < g_features; i++) Format(query, sizeof(query), "%s, %s='%i'", query, g_FeatureBase[i], g_WantFeature[i][client]);
			
			Format(query, sizeof(query), "%s WHERE steamid='%s'", query, steamid);
		}
		else Format(query, sizeof(query), "UPDATE %s SET points=%i WHERE steamid='%s'", g_tablename, g_playerpoints[client], steamid);
		
		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
		
		if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		
		nativelib_ClientSave(client);
	}
}

public Action:clientlib_CmdSay(client, args)
{
	new String:text[128];
	new String:name[MAX_NAME_LENGTH+1];
	
	GetClientName(client, name, sizeof(name));
	GetCmdArgString(text, sizeof(text));
	
	ReplaceString(text, sizeof(text), "\"", "");
	
	if (clientlib_isValidClient(client))
	{
		if (g_happynumber[client] == 1)
		{
			new timetoset = StringToInt(text);
			
			if (timetoset > 1)  g_happynumber[client] = timetoset;
			else
			{
				g_happynumber[client] = 0;
				CPrintToChat(client, "%s %T", g_StammTag, "aborted", LANG_SERVER);
				return Plugin_Handled;
			}
			
			CPrintToChat(client, "%s %T", g_StammTag, "WriteHappyFactor", LANG_SERVER);
			CPrintToChat(client, "%s %T", g_StammTag, "WriteHappyFactorInfo", LANG_SERVER);
			
			g_happyfactor[client] = 1;
				
			return Plugin_Handled;	
		}
		else if (g_happyfactor[client] == 1)
		{
			new factortoset = StringToInt(text);
			
			if (factortoset > 1 && !g_happyhouron) 
			{
				g_happyfactor[client] = 0;
				g_points = factortoset;
				g_happyhouron = 1;
				
				CPrintToChatAll("%s %T", g_StammTag, "HappyActive", LANG_SERVER, g_points);
				
				g_HappyTimer = CreateTimer(float(g_happynumber[client])*60, otherlib_StopHappyHour);
				
				nativelib_HappyStart(g_happynumber[client], factortoset);
				
				g_happynumber[client] = 0;
			}
			else
			{
				CPrintToChat(client, "%s %T", g_StammTag, "aborted", LANG_SERVER);
				g_happynumber[client] = 0;
				g_happyfactor[client] = 0;
			}
				
			return Plugin_Handled;	
		}
		else if (g_pointsnumber[client] > 0)
		{
			if (StrEqual(text, " "))
			{
				g_pointsnumber[client] = 0;
				CPrintToChat(client, "%s %T", g_StammTag, "aborted", LANG_SERVER);
				return Plugin_Handled;
			}
			
			new choose = g_pointsnumber[client];
			new pointstoset = StringToInt(text);
			
			if (clientlib_isValidClient(choose))
			{
				new String:names[MAX_NAME_LENGTH+1];
				
				GetClientName(choose, names, sizeof(names));
				
				g_playerpoints[choose] = pointstoset;
				
				CPrintToChat(client, "%s %T", g_StammTag, "SetPoints", LANG_SERVER, names, pointstoset);
				CPrintToChat(choose, "%s %T", g_StammTag, "SetPoints2", LANG_SERVER, pointstoset);
				
				clientlib_CheckVip(choose);
			}
			
			g_pointsnumber[client] = 0;
			
			return Plugin_Handled;
		}
		else if (StrEqual(text, g_viplist) && StrContains(g_viplist, "sm_") != 0)
		{
			if (sqllib_db != INVALID_HANDLE)
			{
				new String:query[128];
				
				Format(query, sizeof(query), "SELECT name, points FROM %s WHERE level > 0 ORDER BY points DESC LIMIT 100", g_tablename);
				
				if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
			
				SQL_TQuery(sqllib_db, sqllib_GetVIPTopQuery, query, client);
			}
		}
		else if (StrEqual(text, g_viprank) && StrContains(g_viprank, "sm_") != 0)
		{
			if (sqllib_db != INVALID_HANDLE)
			{
				new String:query[128];
				
				Format(query, sizeof(query), "SELECT points, steamid FROM %s WHERE level > 0 ORDER BY points DESC", g_tablename);
				
				if (g_debug) LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
				
				SQL_TQuery(sqllib_db, sqllib_GetVIPRankQuery, query, client);
			}
		}
		else if (StrEqual(text, g_sinfo) && StrContains(g_sinfo, "sm_") != 0) panellib_CreateUserPanels(client, 3);
		else if (StrEqual(text, g_schange) && StrContains(g_schange, "sm_") != 0) panellib_CreateUserPanels(client, 1);
		else if (StrEqual(text, g_sme) && StrContains(g_sme, "sm_") != 0) panellib_CreateUserPanels(client, 2);
		else if (StrEqual(text, g_texttowrite) && StrContains(g_texttowrite, "sm_") != 0) pointlib_ShowPlayerPoints(client);
		else if (StrEqual(text, g_admin_menu) && StrContains(g_admin_menu, "sm_") != 0 && clientlib_IsAdmin(client)) panellib_CreateUserPanels(client, 4);
		
	}
	return Plugin_Continue;
}

public clientlib_CheckPlayers()
{
	new players = GetClientCount();
	new factor = (MaxClients - players) + 1;
	
	if (g_extra_points > 0)
	{
		if (!g_happyhouron) g_points = factor;
	}
}