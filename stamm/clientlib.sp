#pragma semicolon 1

public bool:clientlib_isValidClient_PRE(client)
{
	if (client > 0 && client <= MaxClients)
	{
		if (IsClientInGame(client))
		{
			if (IsClientAuthorized(client))
			{
				if (!IsClientSourceTV(client) && !IsClientReplay(client) && !IsFakeClient(client))
				{
					decl String:steamid[32];
					
					clientlib_getSteamid(client, steamid, sizeof(steamid));
					
					if (!StrEqual(steamid, "BOT") && !StrEqual(steamid, "STEAM_ID_PENDING")) 
						return true;
				}
			}
		}
	}
	
	return false;
}

public bool:clientlib_isValidClient(client)
{
	return (clientlib_isValidClient_PRE(client) && g_ClientReady[client]);
}

public OnClientPostAdminCheck(client)
{
	if (clientlib_isValidClient_PRE(client)) 
		sqllib_InsertPlayer(client);
}

public clientlib_ClientReady(client)
{
	if (clientlib_isValidClient_PRE(client))
	{
		g_ClientReady[client] = true;
		
		clientlib_CheckVip(client);
		
		if (g_giveflagadmin) 
			clientlib_CheckFlagAdmin(client);
			
		if (g_join_show) 
			CreateTimer(5.0, pointlib_ShowPoints2, client);
		
		clientlib_CheckPlayers();

		nativelib_ClientReady(client);
	}
}

public OnClientDisconnect(client)
{
	clientlib_CheckPlayers();
}

public clientlib_IsSteamIDConnected(String:steamid[])
{
	decl String:cSteamid[64];

	for (new client = 1; client <= MaxClients; client++)
	{
		if (clientlib_isValidClient(client))
		{
			clientlib_getSteamid(client, cSteamid, sizeof(cSteamid));

			if (StrEqual(steamid, cSteamid, false))
				return client;
		}
	}

	return 0;
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

public clientlib_IsSpecialVIP(client)
{
	if (clientlib_isValidClient(client))
	{
		new adminFlags = GetUserFlagBits(client);

		for (new i=0; i < g_plevels; i++)
		{		
			if (StrEqual(g_LevelFlag[i], "a") && (adminFlags & ADMFLAG_RESERVATION)) return i;
			if (StrEqual(g_LevelFlag[i], "b") && (adminFlags & ADMFLAG_GENERIC)) return i;
			if (StrEqual(g_LevelFlag[i], "c") && (adminFlags & ADMFLAG_KICK)) return i;
			if (StrEqual(g_LevelFlag[i], "d") && (adminFlags & ADMFLAG_BAN)) return i;
			if (StrEqual(g_LevelFlag[i], "e") && (adminFlags & ADMFLAG_UNBAN)) return i;
			if (StrEqual(g_LevelFlag[i], "f") && (adminFlags & ADMFLAG_SLAY)) return i;
			if (StrEqual(g_LevelFlag[i], "g") && (adminFlags & ADMFLAG_CHANGEMAP)) return i;
			if (StrEqual(g_LevelFlag[i], "h") && (adminFlags & ADMFLAG_CONVARS)) return i;
			if (StrEqual(g_LevelFlag[i], "i") && (adminFlags & ADMFLAG_CONFIG)) return i;
			if (StrEqual(g_LevelFlag[i], "j") && (adminFlags & ADMFLAG_CHAT)) return i;
			if (StrEqual(g_LevelFlag[i], "k") && (adminFlags & ADMFLAG_VOTE)) return i;
			if (StrEqual(g_LevelFlag[i], "l") && (adminFlags & ADMFLAG_PASSWORD)) return i;
			if (StrEqual(g_LevelFlag[i], "m") && (adminFlags & ADMFLAG_RCON)) return i;
			if (StrEqual(g_LevelFlag[i], "n") && (adminFlags & ADMFLAG_CHEATS)) return i;
			if (StrEqual(g_LevelFlag[i], "o") && (adminFlags & ADMFLAG_CUSTOM1)) return i;
			if (StrEqual(g_LevelFlag[i], "p") && (adminFlags & ADMFLAG_CUSTOM2)) return i;
			if (StrEqual(g_LevelFlag[i], "q") && (adminFlags & ADMFLAG_CUSTOM3)) return i;
			if (StrEqual(g_LevelFlag[i], "r") && (adminFlags & ADMFLAG_CUSTOM4)) return i;
			if (StrEqual(g_LevelFlag[i], "s") && (adminFlags & ADMFLAG_CUSTOM5)) return i;
			if (StrEqual(g_LevelFlag[i], "t") && (adminFlags & ADMFLAG_CUSTOM6)) return i;
			if (StrEqual(g_LevelFlag[i], "z") && (adminFlags & ADMFLAG_ROOT)) return i;
		}
	}
	
	return -1;
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
		pointlib_GivePlayerPoints(client, g_LevelPoints[g_levels-1]);
}

public clientlib_CheckVip(client)
{
	if (sqllib_db != INVALID_HANDLE && clientlib_isValidClient(client))
	{
		decl String:steamid[64];
		new clientpoints = g_playerpoints[client];
		
		clientlib_getSteamid(client, steamid, sizeof(steamid));
		
		new levelstufe = levellib_PointsToID(client, clientpoints);
		
		if (levelstufe == -1) 
			return;
		
		if (levelstufe > 0 && levelstufe != g_playerlevel[client])
		{
			decl String:name[MAX_NAME_LENGTH+1];
			decl String:setquery[256];	

			new bool:isUP = true;

			if (g_playerlevel[client] > levelstufe)
				isUP = false;
			
			g_playerlevel[client] = levelstufe;
			
			GetClientName(client, name, sizeof(name));
			
			CPrintToChatAll("%s %t", g_StammTag, "LevelNowVIP", name, g_LevelName[levelstufe-1]);
			CPrintToChat(client, "%s %t", g_StammTag, "JoinVIP");
			
			if (!StrEqual(g_lvl_up_sound, "0") && isUP)
			{
				if (otherlib_getGame() != 2) 
					EmitSoundToAll(g_lvl_up_sound);
				else
				{
					for (new i=0; i <= MaxClients; i++)
					{
						if (clientlib_isValidClient(i)) 
							ClientCommand(i, "play %s", g_lvl_up_sound);
					}
				}
			}

			Format(setquery, sizeof(setquery), "UPDATE `%s` SET `level`=%i WHERE `steamid`='%s'", g_tablename, levelstufe, steamid);
			
			if (g_debug) 
				LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", setquery);
			
			SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, setquery);

			nativelib_PublicPlayerBecomeVip(client);
		}
		else
		{
			if (levelstufe == 0 && levelstufe != g_playerlevel[client])
			{
				decl String:queryback[256];
								
				g_playerlevel[client] = 0;

				Format(queryback, sizeof(queryback), "UPDATE `%s` SET `level`=0 WHERE `steamid`='%s'", g_tablename, steamid);
				
				if (g_debug) 
					LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", queryback);
				
				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, queryback);
			}
		}
	}
}

public clientlib_SavePlayer(client, number)
{
	if (sqllib_db != INVALID_HANDLE && clientlib_isValidClient(client))
	{
		decl String:query[4024];
		decl String:steamid[64];
		
		clientlib_getSteamid(client, steamid, sizeof(steamid));
		
		if (g_playerpoints[client] == 0)
			Format(query, sizeof(query), "UPDATE `%s` SET `points`=0 ", g_tablename);
		else
			Format(query, sizeof(query), "UPDATE `%s` SET `points`=`points`+(%i) ", g_tablename, number);
			
		for (new i=0; i < g_features; i++)
			Format(query, sizeof(query), "%s, `%s`=%i", query, g_FeatureList[i][FEATURE_BASE], g_FeatureList[i][WANT_FEATURE][client]);
		
		Format(query, sizeof(query), "%s WHERE `steamid`='%s'", query, steamid);
		
		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
		
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		
		nativelib_ClientSave(client);
	}
}

public clientlib_getSteamid(client, String:steamid[], size)
{
	GetClientAuthString(client, steamid, size);
	
	ReplaceString(steamid, size, "STEAM_1:", "STEAM_0:");
}

public Action:clientlib_CmdSay(client, args)
{
	decl String:text[128];
	decl String:name[MAX_NAME_LENGTH+1];
	
	GetClientName(client, name, sizeof(name));
	GetCmdArgString(text, sizeof(text));
	
	ReplaceString(text, sizeof(text), "\"", "");
	
	if (clientlib_isValidClient(client))
	{
		if (g_happynumber[client] == 1)
		{
			new timetoset = StringToInt(text);
			
			if (timetoset > 1)  
				g_happynumber[client] = timetoset;
			else
			{
				g_happynumber[client] = 0;
				CPrintToChat(client, "%s %t", g_StammTag, "aborted");
				
				return Plugin_Handled;
			}
			
			CPrintToChat(client, "%s %t", g_StammTag, "WriteHappyFactor");
			CPrintToChat(client, "%s %t", g_StammTag, "WriteHappyFactorInfo");
			
			g_happyfactor[client] = 1;
				
			return Plugin_Handled;	
		}
		else if (g_happyfactor[client] == 1)
		{
			new factortoset = StringToInt(text);
			
			if (factortoset > 1 && !g_happyhouron) 
			{
				g_happyfactor[client] = 0;

				otherlib_StartHappyHour(g_happynumber[client]*60, factortoset);
				
				g_happynumber[client] = 0;
			}
			else
			{
				CPrintToChat(client, "%s %t", g_StammTag, "aborted");
				
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
				CPrintToChat(client, "%s %t", g_StammTag, "aborted");
				
				return Plugin_Handled;
			}
			
			new choose = g_pointsnumber[client];
			new pointstoset = StringToInt(text);
			
			if (clientlib_isValidClient(choose))
			{
				new String:names[MAX_NAME_LENGTH+1];
				
				GetClientName(choose, names, sizeof(names));
				
				pointlib_GivePlayerPoints(choose, pointstoset);
				
				CPrintToChat(client, "%s %t", g_StammTag, "SetPoints", names, g_playerpoints[client]);
				CPrintToChat(choose, "%s %t", g_StammTag, "SetPoints2", g_playerpoints[client]);
			}
			
			g_pointsnumber[client] = 0;
			
			return Plugin_Handled;
		}
		else if (StrEqual(text, g_viplist) && StrContains(g_viplist, "sm_") != 0)
		{
			sqllib_GetVipTop(client, 0);
		}
		else if (StrEqual(text, g_viprank) && StrContains(g_viprank, "sm_") != 0)
		{
			sqllib_GetVipRank(client, 0);
		}
		else if (StrEqual(text, g_sinfo) && StrContains(g_sinfo, "sm_") != 0)
			panellib_CreateUserPanels(client, 3);
		else if (StrEqual(text, g_schange) && StrContains(g_schange, "sm_") != 0)
			panellib_CreateUserPanels(client, 1);
		else if (StrEqual(text, g_sme) && StrContains(g_sme, "sm_") != 0)
			panellib_CreateUserPanels(client, 2);
		else if (StrEqual(text, g_texttowrite) && StrContains(g_texttowrite, "sm_") != 0)
			pointlib_ShowPlayerPoints(client);
		else if (StrEqual(text, g_admin_menu) && StrContains(g_admin_menu, "sm_") != 0 && clientlib_IsAdmin(client))
			panellib_CreateUserPanels(client, 4);
	}
	
	return Plugin_Continue;
}

public clientlib_CheckPlayers()
{
	new players = GetClientCount();
	new factor = (MaxClients - players) + 1;
	
	if (g_extra_points > 0)
	{
		if (!g_happyhouron) 
			g_points = factor;
	}
}