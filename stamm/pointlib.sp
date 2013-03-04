#pragma semicolon 1

new Handle:pointlib_timetimer;
new Handle:pointlib_showpointer;

public pointlib_Start()
{
	Format(g_texttowrite_f, sizeof(g_texttowrite_f), g_texttowrite);
	
	RegServerCmd("stamm_add_points", pointlib_AddPlayerPoints, "Add Points of a Player: stamm_add_points <userid|steamid> <points>");
	RegServerCmd("stamm_del_points", pointlib_DelPlayerPoints, "Del Points of a Player: stamm_del_points <userid|steamid> <points>");
	RegServerCmd("stamm_set_points", pointlib_SetPlayerPoints, "Set Points of a Player: stamm_set_points <userid|steamid> <points>");

	if (!StrContains(g_texttowrite, "sm_"))
	{
		RegConsoleCmd(g_texttowrite, pointlib_ShowPoints);
		
		ReplaceString(g_texttowrite_f, sizeof(g_texttowrite_f), "sm_", "!");
	}
}

public Action:pointlib_PlayerTime(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (clientlib_isValidClient(i))
		{
			if ((GetClientTeam(i) == 2 || GetClientTeam(i) == 3) && g_min_player <= GetClientCount())
				pointlib_GivePlayerPoints(i, g_points, true);
		}
	}
	return Plugin_Continue;
}

public Action:pointlib_PointShower(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++) 
		pointlib_ShowPlayerPoints(i);
	
	return Plugin_Continue;
}

public Action:pointlib_AddPlayerPoints(args)
{
	if (GetCmdArgs() == 2)
	{
		decl String:useridString[64];
		decl String:numberString[25];
		
		GetCmdArg(1, useridString, sizeof(useridString));
		GetCmdArg(2, numberString, sizeof(numberString));

		new number = StringToInt(numberString);

		if (StrContains(useridString, "STEAM_", false) < 0)
		{
			new client = GetClientOfUserId(StringToInt(useridString));
			
			if (clientlib_isValidClient(client))
				pointlib_GivePlayerPoints(client, number, false);
			else
				ReplyToCommand(0, "Error. Couldn't find userid %s", useridString);
		}
		else
		{
			ReplaceString(useridString, sizeof(useridString), "STEAM_1:", "STEAM_0:", false);

			new client = clientlib_IsSteamIDConnected(useridString);

			if (client > 0)
				pointlib_GivePlayerPoints(client, number, false);
			else
			{
				decl String:query[128];

				Format(query, sizeof(query), "UPDATE `%s` SET `points`=`points`+(%i) WHERE `steamid`='%s'", g_tablename, number, useridString);

				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
				
				if (g_debug) 
					LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
			}
		}
	}
	else
		ReplyToCommand(0, "Usage: stamm_add_points <userid|steamid> <points>");
	
	return Plugin_Handled;
}

public Action:pointlib_SetPlayerPoints(args)
{
	if (GetCmdArgs() == 2)
	{
		decl String:useridString[64];
		decl String:numberString[25];
		
		GetCmdArg(1, useridString, sizeof(useridString));
		GetCmdArg(2, numberString, sizeof(numberString));

		new number = StringToInt(numberString);

		if (StrContains(useridString, "STEAM_", false) < 0)
		{
			new client = GetClientOfUserId(StringToInt(useridString));
			
			if (clientlib_isValidClient(client) && number >= 0)
			{
				new diff = number - g_playerpoints[client];

				pointlib_GivePlayerPoints(client, diff, false);
			}
			else
				ReplyToCommand(0, "Error. Couldn't find userid %s or number is less than zero.", useridString);
		}
		else
		{
			ReplaceString(useridString, sizeof(useridString), "STEAM_1:", "STEAM_0:", false);

			new client = clientlib_IsSteamIDConnected(useridString);

			if (client > 0)
			{
				new diff = number - g_playerpoints[client];

				pointlib_GivePlayerPoints(client, diff, false);
			}
			else
			{
				decl String:query[128];

				Format(query, sizeof(query), "UPDATE `%s` SET `points`=%i WHERE `steamid`='%s'", g_tablename, number, useridString);

				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
				
				if (g_debug) 
					LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
			}
		}
	}
	else
		ReplyToCommand(0, "Usage: stamm_set_points <userid|steamid> <points>");
	
	return Plugin_Handled;
}

public Action:pointlib_DelPlayerPoints(args)
{
	if (GetCmdArgs() == 2)
	{
		decl String:useridString[64];
		decl String:numberString[25];
		
		GetCmdArg(1, useridString, sizeof(useridString));
		GetCmdArg(2, numberString, sizeof(numberString));

		new number = StringToInt(numberString) *-1;
		
		if (StrContains(useridString, "STEAM_", false) < 0)
		{
			new client = GetClientOfUserId(StringToInt(useridString));
			
			if (clientlib_isValidClient(client))
				pointlib_GivePlayerPoints(client, number, false);
			else
				ReplyToCommand(0, "Error. Couldn't find userid %s", useridString);
		}
		else
		{
			ReplaceString(useridString, sizeof(useridString), "STEAM_1:", "STEAM_0:", false);

			new client = clientlib_IsSteamIDConnected(useridString);

			if (client > 0)
				pointlib_GivePlayerPoints(client, number, false);
			else
			{
				decl String:query[128];

				Format(query, sizeof(query), "UPDATE `%s` SET `points`=`points`+(%i) WHERE `steamid`='%s'", g_tablename, number, useridString);

				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
				
				if (g_debug) 
					LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
			}
		}
	}
	else
		ReplyToCommand(0, "Usage: stamm_del_points <userid|steamid> <points>");
	
	return Plugin_Handled;
}

public Action:pointlib_ShowPoints2(Handle:timer, any:client)
{
	pointlib_ShowPlayerPoints(client);
	
	return Plugin_Handled;
}

public Action:pointlib_ShowPoints(client, arg)
{
	pointlib_ShowPlayerPoints(client);
	
	return Plugin_Handled;
}

public pointlib_GivePlayerPoints(client, number, bool:check)
{
	if (number < 0 && g_playerpoints[client] + number < 0)
		number = -g_playerpoints[client];

	if (check)
	{
		new Action:result;

		for (new i=0; i < g_features; i++)
		{
			if (g_FeatureList[i][FEATURE_ENABLE] == 1)
			{
				result = nativelib_PublicPlayerGetPointsPlugin(g_FeatureList[i][FEATURE_HANDLE], client, number);
				
				if (result != Plugin_Changed && result != Plugin_Continue)
					return;
			}
		}
	}

	if (number < 0 && g_playerpoints[client] + number < 0)
		g_playerpoints[client] = 0;
	else
		g_playerpoints[client] = g_playerpoints[client] + number;
		
	clientlib_CheckVip(client);
	clientlib_SavePlayer(client, number);

	nativelib_PublicPlayerGetPoints(client, number);
}

public pointlib_ShowPlayerPoints(client)
{
	if (clientlib_isValidClient(client))
	{
		decl String:name[MAX_NAME_LENGTH+1];
		
		GetClientName(client, name, sizeof(name));
		
		new restpoints = 0;
		new index = g_playerlevel[client];
		new points = g_playerpoints[client];
		
		if (index != g_levels && index < g_levels) 
			restpoints = g_LevelPoints[index] - g_playerpoints[client];
		
		if (!g_see_text)
		{
			if (index != g_levels && index < g_levels) 
				CPrintToChat(client, "%s %t", g_StammTag, "NoVIPClient", points, restpoints, g_LevelName[g_playerlevel[client]]);
			else 
				CPrintToChat(client, "%s %t", g_StammTag, "VIPClient", points, g_LevelName[index-1]);
		}
		else
		{
			if (index != g_levels && index < g_levels) 
				CPrintToChatAll("%s %t", g_StammTag, "NoVIPAll", name, points, restpoints, g_LevelName[g_playerlevel[client]]);
			else 
				CPrintToChatAll("%s %t", g_StammTag, "VIPAll", name, points, g_LevelName[index-1]);
		}
	}
}