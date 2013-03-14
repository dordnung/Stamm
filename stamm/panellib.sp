#pragma semicolon 1

new Handle:panellib_info;
new Handle:panellib_levels;
new Handle:panellib_credits;
new Handle:panellib_cmdlist;
new Handle:panellib_adminpanel;

public panellib_Start()
{
	decl String:infoString[256];
		
	Format(g_sinfo_f, sizeof(g_sinfo_f), g_sinfo);
	Format(g_schange_f, sizeof(g_schange_f), g_schange);
	
	if (!StrContains(g_sinfo, "sm_"))
	{
		RegConsoleCmd(g_sinfo, panellib_InfoPanel);
		
		ReplaceString(g_sinfo_f, sizeof(g_sinfo_f), "sm_", "!");
	}
	
	if (!StrContains(g_schange, "sm_"))
	{
		RegConsoleCmd(g_schange, panellib_ChangePanel);
		
		ReplaceString(g_schange_f, sizeof(g_schange_f), "sm_", "!");
	}
	
	if (!StrContains(g_admin_menu, "sm_")) 
		RegAdminCmd(g_admin_menu, panellib_OpenAdmin, ADMFLAG_CUSTOM6);
	
	panellib_credits = CreatePanel();
	panellib_levels = CreateMenu(panellib_PassPanelHandler);
	panellib_info = CreatePanel();
	panellib_cmdlist = CreatePanel();
	panellib_adminpanel = CreatePanel();

	Format(infoString, sizeof(infoString), "%T", "AllLevels", LANG_SERVER);

	SetMenuTitle(panellib_levels, infoString);
	SetMenuExitButton(panellib_levels, true);

	for (new i=0; i < g_levels; i++)
	{
		Format(infoString, sizeof(infoString), "%s - %i %T", g_LevelName[i], g_LevelPoints[i], "Points", LANG_SERVER);
		AddMenuItem(panellib_levels, "", infoString);
	}

	for (new i=0; i < g_plevels; i++)
	{
		Format(infoString, sizeof(infoString), "%s - %T %s", g_LevelName[g_levels+i], "Flag", LANG_SERVER, g_LevelFlag[i]);
		AddMenuItem(panellib_levels, "", infoString);
	}
	
	Format(infoString, sizeof(infoString), "%T", "AdminMenu", LANG_SERVER);
	SetPanelTitle(panellib_adminpanel, infoString);
	
	DrawPanelText(panellib_adminpanel, "----------------------------------------------------");
	
	Format(infoString, sizeof(infoString), "%T", "PointsOfPlayer", LANG_SERVER);
	DrawPanelItem(panellib_adminpanel, infoString);
	
	Format(infoString, sizeof(infoString), "%T", "ResetPlayer", LANG_SERVER);
	DrawPanelItem(panellib_adminpanel, infoString);
	
	Format(infoString, sizeof(infoString), "%T", "HappyHour", LANG_SERVER);
	DrawPanelItem(panellib_adminpanel, infoString);
	
	Format(infoString, sizeof(infoString), "%T", "HappyHourEnd", LANG_SERVER);
	DrawPanelItem(panellib_adminpanel, infoString);
	
	Format(infoString, sizeof(infoString), "%T", "LoadFeature", LANG_SERVER);
	DrawPanelItem(panellib_adminpanel, infoString);
	
	Format(infoString, sizeof(infoString), "%T", "UnloadFeature", LANG_SERVER);
	DrawPanelItem(panellib_adminpanel, infoString);
	
	DrawPanelText(panellib_adminpanel, "----------------------------------------------------");
	
	Format(infoString, sizeof(infoString), "%T", "Close", LANG_SERVER);
	DrawPanelItem(panellib_adminpanel, infoString);
	
	Format(infoString, sizeof(infoString), "%T", "StammCMD", LANG_SERVER);
	SetPanelTitle(panellib_cmdlist, infoString);
	
	DrawPanelText(panellib_cmdlist, "-------------------------------------------");
	
	Format(infoString, sizeof(infoString), "%T %s", "StammPoints", LANG_SERVER, g_texttowrite_f);
	DrawPanelItem(panellib_cmdlist, infoString);
	
	Format(infoString, sizeof(infoString), "%T %s", "StammTop", LANG_SERVER, g_viplist_f);
	DrawPanelItem(panellib_cmdlist, infoString);
	
	Format(infoString, sizeof(infoString), "%T %s", "StammRank", LANG_SERVER, g_viprank_f);
	DrawPanelItem(panellib_cmdlist, infoString);
	
	Format(infoString, sizeof(infoString), "%T %s", "StammChange", LANG_SERVER, g_schange_f);
	DrawPanelItem(panellib_cmdlist, infoString);
	
	DrawPanelText(panellib_cmdlist, "-------------------------------------------");
	
	Format(infoString, sizeof(infoString), "%T", "Back", LANG_SERVER);
	DrawPanelItem(panellib_cmdlist, infoString);
	
	Format(infoString, sizeof(infoString), "%T", "Close", LANG_SERVER);
	DrawPanelItem(panellib_cmdlist, infoString);
	
	SetPanelTitle(panellib_credits, "Stamm Credits");
	
	DrawPanelText(panellib_credits, "-------------------------------------------");
	DrawPanelText(panellib_credits, "Author:");
	DrawPanelItem(panellib_credits, "Stamm Author is Popoklopsi");
	DrawPanelText(panellib_credits, "-------------------------------------------");
	DrawPanelText(panellib_credits, "Official Stamm Page: https://forums.alliedmods.net/showthread.php?t=142073");
	DrawPanelText(panellib_credits, "-------------------------------------------");
	
	Format(infoString, sizeof(infoString), "%T", "Back", LANG_SERVER);
	DrawPanelItem(panellib_credits, infoString);
	
	Format(infoString, sizeof(infoString), "%T", "Close", LANG_SERVER);
	DrawPanelItem(panellib_credits, infoString);
	
	SetPanelTitle(panellib_info, "Stamm by Popoklopsi");
	
	DrawPanelText(panellib_info, "-------------------------------------------");
	
	Format(infoString, sizeof(infoString), "%T", "PointInfo", LANG_SERVER);
	DrawPanelText(panellib_info, infoString);
	
	Format(infoString, sizeof(infoString), "1 %T", "Kill", LANG_SERVER);
	if (g_vip_type == 1 || g_vip_type == 4 || g_vip_type == 5 || g_vip_type == 7) 
		DrawPanelText(panellib_info, infoString);
		
	Format(infoString, sizeof(infoString), "1 %T", "Round", LANG_SERVER);
	if (g_vip_type == 2 || g_vip_type == 4 || g_vip_type == 6 || g_vip_type == 7) 
		DrawPanelText(panellib_info, infoString);
		
	Format(infoString, sizeof(infoString), "%i %T", g_time_point, "Minute", LANG_SERVER);
	if (g_vip_type == 3 || g_vip_type == 5 || g_vip_type == 6 || g_vip_type == 7) 
		DrawPanelText(panellib_info, infoString);
		
	DrawPanelText(panellib_info, "-------------------------------------------");
	
	Format(infoString, sizeof(infoString), "%T", "StammFeatures", LANG_SERVER);
	DrawPanelItem(panellib_info, infoString);
	
	Format(infoString, sizeof(infoString), "%T", "StammCMD", LANG_SERVER);
	DrawPanelItem(panellib_info, infoString);
	
	Format(infoString, sizeof(infoString), "%T", "AllLevels", LANG_SERVER);
	DrawPanelItem(panellib_info, infoString);
	
	DrawPanelItem(panellib_info, "Credits");
	DrawPanelText(panellib_info, "-------------------------------------------");
	
	Format(infoString, sizeof(infoString), "%T", "Close", LANG_SERVER);
	DrawPanelItem(panellib_info, infoString);
}

public Action:panellib_OpenAdmin(client, args)
{
	if (clientlib_isValidClient(client)) 
		panellib_CreateUserPanels(client, 4);
	
	return Plugin_Handled;
}

public Action:panellib_ChangePanel(client, args)
{
	panellib_CreateUserPanels(client, 1);
	
	return Plugin_Handled;
}

public panellib_CreateUserPanels(client, mode)
{
	if (mode == 1)
	{
		if (clientlib_isValidClient(client))
		{
			new Handle:ChangeMenu = CreateMenu(panellib_ChangePanelHandler);
			decl String:MenuItem[100];
			decl String:index[10];
			
			SetMenuExitButton(ChangeMenu, true);
			
			SetMenuTitle(ChangeMenu, "%T", "ChangeFeatures", client);
			
			for (new i=0; i < g_features; i++)
			{
				if (g_FeatureList[i][FEATURE_ENABLE] && g_FeatureList[i][FEATURE_CHANGE])
				{
					if (g_FeatureList[i][WANT_FEATURE][client]) 
						Format(MenuItem, sizeof(MenuItem), "%T", "FeatureOn", client, g_FeatureList[i][FEATURE_NAME]);
					else 
						Format(MenuItem, sizeof(MenuItem), "%T", "FeatureOff", client, g_FeatureList[i][FEATURE_NAME]);
					
					Format(index, sizeof(index), "%i", i);
					
					AddMenuItem(ChangeMenu, index, MenuItem);
				}
			}
			DisplayMenu(ChangeMenu, client, 60);
		}
	}
	if (mode == 3) 
		SendPanelToClient(panellib_info, client, panellib_InfoHandler, 20);
	if (mode == 4) 
		SendPanelToClient(panellib_adminpanel, client, panellib_AdminHandler, 40);
}

public Action:panellib_InfoPanel(client, args)
{
	if (clientlib_isValidClient(client)) 
		panellib_CreateUserPanels(client, 3);
	
	return Plugin_Handled;
}

public panellib_ChangePanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (clientlib_isValidClient(param1))
		{
			decl String:ChangeChoose[64];
			new index;
			
			GetMenuItem(menu, param2, ChangeChoose, sizeof(ChangeChoose));

			if (!StrEqual(ChangeChoose, "close"))
			{
				index = StringToInt(ChangeChoose);
				
				g_FeatureList[index][WANT_FEATURE][param1] = !g_FeatureList[index][WANT_FEATURE][param1];
				
				nativelib_ClientChanged(param1, index, g_FeatureList[index][WANT_FEATURE][param1]);

				FakeClientCommand(param1, "say %s", g_schange_f);
			}
		}
	}
	else if (action == MenuAction_End) 
		CloseHandle(menu);
}

public panellib_FeaturelistLoadHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:choose[12];
		
		GetMenuItem(menu, param2, choose, sizeof(choose));
		
		featurelib_loadFeature(g_FeatureList[StringToInt(choose)][FEATURE_HANDLE]);
	}
	else if (action == MenuAction_End) 
		CloseHandle(menu);
}

public panellib_FeaturelistUnloadHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:choose[12];
		
		GetMenuItem(menu, param2, choose, sizeof(choose));
		
		featurelib_UnloadFeature(g_FeatureList[StringToInt(choose)][FEATURE_HANDLE]);
	}
	else if (action == MenuAction_End) 
		CloseHandle(menu);
}

public panellib_PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 2 && clientlib_isValidClient(param1)) 
			SendPanelToClient(panellib_info, param1, panellib_InfoHandler, 20);
	}
}

public panellib_PassPanelHandler(Handle:menu, MenuAction:action, param1, param2) 
{
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && clientlib_isValidClient(param1))
			SendPanelToClient(panellib_info, param1, panellib_InfoHandler, 20);
	}
}

public panellib_PlayerListHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) 
	{
		decl String:menuinfo[32];
		
		GetMenuItem(menu, param2, menuinfo, sizeof(menuinfo));
		
		new client = StringToInt(menuinfo);
		
		if (clientlib_isValidClient(param1))
		{	
			g_pointsnumber[param1] = client;
			
			CPrintToChat(param1, "%s %t", g_StammTag, "WritePoints");
			CPrintToChat(param1, "%s %t", g_StammTag, "WritePointsInfo");
		}
	}
	else if (action == MenuAction_End) 
		CloseHandle(menu);
}

public panellib_PlayerListHandlerDelete(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) 
	{
		decl String:query[256];
		decl String:menuinfo[32];
		decl String:name[MAX_NAME_LENGTH+1];
		decl String:steamid[64];
	
		GetMenuItem(menu, param2, menuinfo, sizeof(menuinfo));
		
		new client = StringToInt(menuinfo);
		
		if (clientlib_isValidClient(client) && clientlib_isValidClient(param1))
		{
			GetClientName(client, name, sizeof(name));
			clientlib_getSteamid(client, steamid, sizeof(steamid));
			
			CPrintToChat(param1, "%s %t", g_StammTag, "DeletedPoints", name);
			
			for (new i=0; i<3; i++) 
				CPrintToChat(client, "%s %t", g_StammTag, "YourDeletedPoints");
			
			g_playerpoints[client] = 0;
			g_playerlevel[client] = 0;
					
			Format(query, sizeof(query), "UPDATE `%s` SET `level`=0,`points`=0 WHERE `steamid`='%s'", g_tablename, steamid);
			
			SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
		}
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

public panellib_FeatureHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && clientlib_isValidClient(param1))
			panellib_InfoHandler(INVALID_HANDLE, MenuAction_Select, param1, 1);
	}
	else if (action == MenuAction_End) 
		CloseHandle(menu);
}

public panellib_CmdlistHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (clientlib_isValidClient(param1))
		{
			if (param2 == 1) 
				FakeClientCommandEx(param1, "say %s", g_texttowrite_f);
			if (param2 == 2) 
				FakeClientCommandEx(param1, "say %s", g_viplist_f);
			if (param2 == 3) 
				FakeClientCommandEx(param1, "say %s", g_viprank_f);
			if (param2 == 4)
				FakeClientCommandEx(param1, "say %s", g_schange_f);
			if (param2 == 5)
				SendPanelToClient(panellib_info, param1, panellib_InfoHandler, 20);
		}
	}
}

public panellib_InfoHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (clientlib_isValidClient(param1))
		{
			if (param2 == 4) 
				SendPanelToClient(panellib_credits, param1, panellib_PanelHandler, 20);
			if (param2 == 3) 
				DisplayMenu(panellib_levels, param1, 20);
			if (param2 == 2) 
				SendPanelToClient(panellib_cmdlist, param1, panellib_CmdlistHandler, 20);
			if (param2 == 1)
			{
				new Handle:featurelist = CreateMenu(panellib_FeatureListHandler);
				
				SetMenuTitle(featurelist, "%T", "HaveFeatures", param1);
				SetMenuExitBackButton(featurelist, true);
				
				decl String:featureid[10];
				
				for (new i=0; i < g_levels+g_plevels; i++)
				{
					Format(featureid, sizeof(featureid), "%i", i+1);
					
					AddMenuItem(featurelist, featureid, g_LevelName[i]);
				}
				
				DisplayMenu(featurelist, param1, 20);
			}
		}
	}
}

public panellib_FeatureListHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && clientlib_isValidClient(param1))
	{
		decl String:Chooseit[10];
		decl String:featuretext[128];
		
		GetMenuItem(menu, param2, Chooseit, sizeof(Chooseit));
		
		new id = StringToInt(Chooseit);
		new Handle:featurelist = CreateMenu(panellib_FeatureHandler);
		
		SetMenuTitle(featurelist, "%T", "HaveFeatures", param1);
		SetMenuExitBackButton(featurelist, true);
		
		for (new i=0; i < g_features; i++)
		{
			if (g_FeatureList[i][FEATURE_ENABLE])
			{
				for (new j=0; j < g_FeatureList[i][FEATURE_DESCS][id]; j++)
				{
					if (!StrEqual(g_FeatureHaveDesc[i][id][j], ""))
					{
						Format(featuretext, sizeof(featuretext), "%s", g_FeatureHaveDesc[i][id][j]);
						
						AddMenuItem(featurelist, "", featuretext);
					}
				}
			}
		}
		
		DisplayMenu(featurelist, param1, 20);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && clientlib_isValidClient(param1))
			SendPanelToClient(panellib_info, param1, panellib_InfoHandler, 20);
	}
	if (action == MenuAction_End) 
		CloseHandle(menu);
}

public panellib_AdminHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (clientlib_isValidClient(param1))
		{
			decl String:Chooseit[128];
			
			new Handle:playerlist;
			new Handle:featurelist;
			
			Format(Chooseit, sizeof(Chooseit), "%T", "ChoosePlayer", param1);
			
			if (param2 == 1) 
				playerlist = CreateMenu(panellib_PlayerListHandler);
			else if (param2 == 2) 
				playerlist = CreateMenu(panellib_PlayerListHandlerDelete);
				
			if (param2 == 1 || param2 == 2)
			{
				decl String:clientname[MAX_NAME_LENGTH + 1];
				decl String:clientString[6];
						
				SetMenuTitle(playerlist, Chooseit);
				
				for (new i = 1; i <= MaxClients; i++)
				{
					if (clientlib_isValidClient(i))
					{
						Format(clientString, sizeof(clientString), "%i", i);
						
						GetClientName(i, clientname, sizeof(clientname));
						
						AddMenuItem(playerlist, clientString, clientname);
					}
				}
				DisplayMenu(playerlist, param1, 30);
			}
			if (param2 == 3)
			{	
				if (!g_happyhouron) 
					otherlib_MakeHappyHour(param1);
				else if (g_happyhouron) 
					CPrintToChat(param1, "%s %t", g_StammTag, "HappyRunning");
			}
			if (param2 == 4)
			{	
				if (g_happyhouron) 
					otherlib_EndHappyHour();
				else if (!g_happyhouron) 
					CPrintToChat(param1, "%s %t", g_StammTag, "HappyNotRunning");
			}
			if (param2 == 5)
			{	
				decl String:itemString[12];

				new bool:found = false;
				
				featurelist = CreateMenu(panellib_FeaturelistLoadHandler);
				
				Format(Chooseit, sizeof(Chooseit), "%T", "ChooseFeature", param1);
				SetMenuTitle(featurelist, Chooseit);
				
				for (new i=0; i < g_features; i++)
				{
					if (g_FeatureList[i][FEATURE_ENABLE] == 0)
					{
						Format(itemString, sizeof(itemString), "%i", i);
						AddMenuItem(featurelist, itemString, g_FeatureList[i][FEATURE_NAME]);
						found = true;
					}
				}
				
				if (found) 
					DisplayMenu(featurelist, param1, 30);
				else 
					CPrintToChat(param1, "%s %t", g_StammTag, "NoFeatureFound");
			}
			if (param2 == 6)
			{	
				decl String:itemString[12];
				new bool:found = false;
				
				featurelist = CreateMenu(panellib_FeaturelistUnloadHandler);
				
				Format(Chooseit, sizeof(Chooseit), "%T", "ChooseFeature", param1);
				SetMenuTitle(featurelist, Chooseit);
				
				for (new i=0; i < g_features; i++)
				{
					if (g_FeatureList[i][FEATURE_ENABLE] == 1)
					{
						Format(itemString, sizeof(itemString), "%i", i);
						AddMenuItem(featurelist, itemString, g_FeatureList[i][FEATURE_NAME]);
						found = true;
					}
				}
				
				if (found) 
					DisplayMenu(featurelist, param1, 30);
				else 
					CPrintToChat(param1, "%s %t", g_StammTag, "NoFeatureFound");
			}
		}
	}
}