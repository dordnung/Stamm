new Handle:pointlib_timetimer;
new Handle:pointlib_showpointer;

public pointlib_Start()
{
	Format(g_texttowrite_f, sizeof(g_texttowrite_f), g_texttowrite);
	
	RegServerCmd("set_stamm_points", pointlib_SetPlayerPoints, "Set Points of a Player: set_stamm_points <userid> <points>");
	RegServerCmd("add_stamm_points", pointlib_AddPlayerPoints, "Add Points of a Player: add_stamm_points <userid> <points>");
	RegServerCmd("del_stamm_points", pointlib_DelPlayerPoints, "Del Points of a Player: del_stamm_points <userid> <points>");
	
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
			{
				pointlib_GivePlayerPoints(i);
				clientlib_CheckVip(i);
			}
		}
	}
	return Plugin_Continue;
}

public Action:pointlib_PointShower(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++) pointlib_ShowPlayerPoints(i);
	
	return Plugin_Continue;
}


public Action:pointlib_SetPlayerPoints(args)
{
	if (GetCmdArgs() == 2)
	{
		new String:useridString[25];
		new String:numberString[25];
		
		GetCmdArg(1, useridString, sizeof(useridString));
		GetCmdArg(2, numberString, sizeof(numberString));
		
		new client = GetClientOfUserId(StringToInt(useridString));
		new number = StringToInt(numberString);
		
		if (clientlib_isValidClient(client))
		{	
			g_playerpoints[client] = number;
			clientlib_CheckVip(client);
		}
	}
	
	return Plugin_Handled;
}

public Action:pointlib_AddPlayerPoints(args)
{
	if (GetCmdArgs() == 2)
	{
		new String:useridString[25];
		new String:numberString[25];
		
		GetCmdArg(1, useridString, sizeof(useridString));
		GetCmdArg(2, numberString, sizeof(numberString));
		
		new client = GetClientOfUserId(StringToInt(useridString));
		new number = StringToInt(numberString);
		
		if (clientlib_isValidClient(client))
		{	
			g_playerpoints[client] = g_playerpoints[client] + number;
			clientlib_CheckVip(client);
		}
	}
	
	return Plugin_Handled;
}

public Action:pointlib_DelPlayerPoints(args)
{
	if (GetCmdArgs() == 2)
	{
		new String:useridString[25];
		new String:numberString[25];
		
		GetCmdArg(1, useridString, sizeof(useridString));
		GetCmdArg(2, numberString, sizeof(numberString));
		
		new client = GetClientOfUserId(StringToInt(useridString));
		new number = StringToInt(numberString);
		
		
		if (clientlib_isValidClient(client))
		{	
			g_playerpoints[client] = g_playerpoints[client] - number;
			if (g_playerpoints[client] < 0) g_playerpoints[client] = 0;
			
			clientlib_CheckVip(client);
		}
	}
	
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

public pointlib_GivePlayerPoints(client)
{
	g_playerpoints[client] = g_playerpoints[client] + g_points;
	nativelib_PublicPlayerGetPoints(client, g_points);
}

public pointlib_ShowPlayerPoints(client)
{
	if (clientlib_isValidClient(client))
	{
		new String:name[MAX_NAME_LENGTH+1];
		
		GetClientName(client, name, sizeof(name));
		
		new restpoints = 0;
		new index = g_playerlevel[client];
		new points = g_playerpoints[client];
		if (index != g_levels) restpoints = g_LevelPoints[index] - g_playerpoints[client];
		
		if (!g_see_text)
		{
			if (index != g_levels) CPrintToChat(client, "%s %T", g_StammTag, "NoVIPClient", LANG_SERVER, points, restpoints, g_LevelName[g_playerlevel[client]]);
			else CPrintToChat(client, "%s %T", g_StammTag, "VIPClient", LANG_SERVER, points, g_LevelName[g_levels-1]);
		}
		else
		{
			if (index != g_levels) CPrintToChatAll("%s %T", g_StammTag, "NoVIPAll", LANG_SERVER, name, points, restpoints, g_LevelName[g_playerlevel[client]]);
			else CPrintToChatAll("%s %T", g_StammTag, "VIPAll", LANG_SERVER, name, points, g_LevelName[g_levels-1]);
		}
	}
}