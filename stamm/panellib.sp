/**
 * -----------------------------------------------------
 * File        panellib.sp
 * Authors     David <popoklopsi> Ordnung
 * License     GPLv3
 * Web         http://popoklopsi.de
 * -----------------------------------------------------
 * 
 * Copyright (C) 2012-2013 David <popoklopsi> Ordnung
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>
 */


// Use semicolons
#pragma semicolon 1

// Panels
new Handle:panellib_info;
new Handle:panellib_levels;
new Handle:panellib_credits;
new Handle:panellib_cmdlist;
new Handle:panellib_adminpanel;


// Init. Panellib 
public panellib_Start()
{
	decl String:infoString[256];
		
	Format(g_sinfo_f, sizeof(g_sinfo_f), g_sinfo);
	Format(g_schange_f, sizeof(g_schange_f), g_schange);
	

	// register sinfo and schange and take out "_sm"
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
	
	// Register sadmin
	if (!StrContains(g_admin_menu, "sm_")) 
	{
		RegAdminCmd(g_admin_menu, panellib_OpenAdmin, ADMFLAG_CUSTOM6);
	}

	// Create new Panels
	panellib_credits = CreatePanel();
	panellib_levels = CreateMenu(panellib_PassPanelHandler);
	panellib_info = CreatePanel();
	panellib_cmdlist = CreatePanel();
	panellib_adminpanel = CreatePanel();


	// Create Level Overview
	Format(infoString, sizeof(infoString), "%T", "AllLevels", LANG_SERVER);

	SetMenuTitle(panellib_levels, infoString);
	SetMenuExitButton(panellib_levels, true);

	// Add all non privat levels
	for (new i=0; i < g_levels; i++)
	{
		Format(infoString, sizeof(infoString), "%s - %i %T", g_LevelName[i], g_LevelPoints[i], "Points", LANG_SERVER);
		AddMenuItem(panellib_levels, "", infoString);
	}

	// Add private levels
	for (new i=0; i < g_plevels; i++)
	{
		Format(infoString, sizeof(infoString), "%s - %T %s", g_LevelName[g_levels+i], "Flag", LANG_SERVER, g_LevelFlag[i]);
		AddMenuItem(panellib_levels, "", infoString);
	}
	


	// Create Admin Menu
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




	// Create Command overview
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
	



	// Create Stamm Credits
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
	


	// Create Main info Panel
	SetPanelTitle(panellib_info, "Stamm by Popoklopsi");
	
	DrawPanelText(panellib_info, "-------------------------------------------");
	
	Format(infoString, sizeof(infoString), "%T", "PointInfo", LANG_SERVER);
	DrawPanelText(panellib_info, infoString);
	

	// Add points information
	// Kill
	Format(infoString, sizeof(infoString), "1 %T", "Kill", LANG_SERVER);

	if (g_vip_type == 1 || g_vip_type == 4 || g_vip_type == 5 || g_vip_type == 7) 
	{
		DrawPanelText(panellib_info, infoString);
	}


	// Rounds
	Format(infoString, sizeof(infoString), "1 %T", "Round", LANG_SERVER);

	if (g_vip_type == 2 || g_vip_type == 4 || g_vip_type == 6 || g_vip_type == 7) 
	{
		DrawPanelText(panellib_info, infoString);
	}
		

	// Time
	Format(infoString, sizeof(infoString), "%i %T", g_time_point, "Minute", LANG_SERVER);

	if (g_vip_type == 3 || g_vip_type == 5 || g_vip_type == 6 || g_vip_type == 7) 
	{
		DrawPanelText(panellib_info, infoString);
	}
		
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


// Open admin menu
public Action:panellib_OpenAdmin(client, args)
{
	// Only for valid clients
	if (clientlib_isValidClient(client)) 
	{
		panellib_CreateUserPanels(client, 4);
	}

	return Plugin_Handled;
}

// Open change panel
public Action:panellib_ChangePanel(client, args)
{
	panellib_CreateUserPanels(client, 1);
	
	return Plugin_Handled;
}


// Intern function to create and send Panels
public panellib_CreateUserPanels(client, mode)
{
	// Change panel, always up to date
	if (mode == 1)
	{
		// Only valid clients
		if (clientlib_isValidClient(client))
		{
			new Handle:ChangeMenu = CreateMenu(panellib_ChangePanelHandler);
			decl String:MenuItem[100];
			decl String:index[10];
			
			SetMenuExitButton(ChangeMenu, true);
			
			SetMenuTitle(ChangeMenu, "%T", "ChangeFeatures", client);
			

			// Loop through all features
			for (new i=0; i < g_features; i++)
			{
				// Only enabled features and changeable features
				if (g_FeatureList[i][FEATURE_ENABLE] && g_FeatureList[i][FEATURE_CHANGE])
				{
					// Text to enable or disable feature
					if (g_FeatureList[i][WANT_FEATURE][client])
					{ 
						Format(MenuItem, sizeof(MenuItem), "%T", "FeatureOn", client, g_FeatureList[i][FEATURE_NAME]);
					}
					else
					{ 
						Format(MenuItem, sizeof(MenuItem), "%T", "FeatureOff", client, g_FeatureList[i][FEATURE_NAME]);
					}

					// Save index and add
					Format(index, sizeof(index), "%i", i);
					
					AddMenuItem(ChangeMenu, index, MenuItem);
				}
			}

			// Now display the menu
			DisplayMenu(ChangeMenu, client, 60);
		}
	}

	// Open info handler
	if (mode == 3) 
	{
		SendPanelToClient(panellib_info, client, panellib_InfoHandler, 20);
	}

	// Open Admin menu
	if (mode == 4) 
	{
		SendPanelToClient(panellib_adminpanel, client, panellib_AdminHandler, 40);
	}
}


// Want the info Panel
public Action:panellib_InfoPanel(client, args)
{
	// Open it for valid users
	if (clientlib_isValidClient(client)) 
	{
		panellib_CreateUserPanels(client, 3);
	}

	return Plugin_Handled;
}


// Changed feature state
public panellib_ChangePanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (clientlib_isValidClient(param1))
		{
			decl String:ChangeChoose[64];
			new index;
			
			// Get selected item
			GetMenuItem(menu, param2, ChangeChoose, sizeof(ChangeChoose));

			// Get the index
			index = StringToInt(ChangeChoose);
			
			// Just set to opposite
			g_FeatureList[index][WANT_FEATURE][param1] = !g_FeatureList[index][WANT_FEATURE][param1];
			
			// Notice to API
			nativelib_ClientChanged(param1, index, g_FeatureList[index][WANT_FEATURE][param1]);

			//Open it again
			panellib_CreateUserPanels(param1, 1);
		}
	}

	else if (action == MenuAction_End) 
	{
		// destroy menu
		CloseHandle(menu);
	}
}


// Want to load a feature
public panellib_FeaturelistLoadHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:choose[12];
		
		// Get selected and load it
		GetMenuItem(menu, param2, choose, sizeof(choose));
		
		featurelib_loadFeature(g_FeatureList[StringToInt(choose)][FEATURE_HANDLE]);
	}

	// Stop menu
	else if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
}

// Want to unload a feature
public panellib_FeaturelistUnloadHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:choose[12];
		
		// Get item and unload
		GetMenuItem(menu, param2, choose, sizeof(choose));
		
		featurelib_UnloadFeature(g_FeatureList[StringToInt(choose)][FEATURE_HANDLE]);
	}

	// Close
	else if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
}

// Open Info Panel
public panellib_PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 2 && clientlib_isValidClient(param1)) 
		{
			SendPanelToClient(panellib_info, param1, panellib_InfoHandler, 20);
		}
	}
}


// Just a pass panel handler for back button
public panellib_PassPanelHandler(Handle:menu, MenuAction:action, param1, param2) 
{
	if (action == MenuAction_Cancel)
	{
		// Pressed back
		if (param2 == MenuCancel_ExitBack && clientlib_isValidClient(param1))
		{
			// Send info panel again
			SendPanelToClient(panellib_info, param1, panellib_InfoHandler, 20);
		}
	}
}


// Add Points to a player
public panellib_PlayerListHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) 
	{
		decl String:menuinfo[32];
		
		// get player
		GetMenuItem(menu, param2, menuinfo, sizeof(menuinfo));
		
		new client = StringToInt(menuinfo);
		
		// Valid user
		if (clientlib_isValidClient(param1) && clientlib_isValidClient(client))
		{	
			// Client should write points to add
			g_pointsnumber[param1] = client;
			
			CPrintToChat(param1, "%s %t", g_StammTag, "WritePoints");
			CPrintToChat(param1, "%s %t", g_StammTag, "WritePointsInfo");
		}
	}
	else if (action == MenuAction_End) 
	{
		// Close
		CloseHandle(menu);
	}
}

// Delete a player
public panellib_PlayerListHandlerDelete(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) 
	{
		decl String:query[256];
		decl String:menuinfo[32];
		decl String:name[MAX_NAME_LENGTH+1];
		decl String:steamid[64];
	
		// get player to delete
		GetMenuItem(menu, param2, menuinfo, sizeof(menuinfo));
		
		new client = StringToInt(menuinfo);
		

		// Must be valid
		if (clientlib_isValidClient(client) && clientlib_isValidClient(param1))
		{
			// Get the name and steamid
			GetClientName(client, name, sizeof(name));
			clientlib_getSteamid(client, steamid, sizeof(steamid));
			
			// Notice deletion
			CPrintToChat(param1, "%s %t", g_StammTag, "DeletedPoints", name);
			
			// Print to deleted client, 3 TIMES :o
			for (new i=0; i<3; i++) 
			{
				CPrintToChat(client, "%s %t", g_StammTag, "YourDeletedPoints");
			}

			// Set level and points to zero
			g_playerpoints[client] = 0;
			g_playerlevel[client] = 0;
					
			// Update in database
			Format(query, sizeof(query), "UPDATE `%s` SET `level`=0,`points`=0 WHERE `steamid`='%s'", g_tablename, steamid);
			
			SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
		}
	}
	else if (action == MenuAction_End)
	{
		// Close
		CloseHandle(menu);
	}
}


// Handle Feature list back button
public panellib_FeatureHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Cancel)
	{
		// Pressed back
		if (param2 == MenuCancel_ExitBack && clientlib_isValidClient(param1))
		{
			// Proceed here
			panellib_InfoHandler(INVALID_HANDLE, MenuAction_Select, param1, 1);
		}
	}
	else if (action == MenuAction_End) 
	{
		// close
		CloseHandle(menu);
	}
}


// Pressed a command
public panellib_CmdlistHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (clientlib_isValidClient(param1))
		{
			// Explicit show command
			// Get selected Command
			if (param2 == 1) 
			{
				FakeClientCommandEx(param1, "say %s", g_texttowrite_f);
			}
			if (param2 == 2) 
			{
				FakeClientCommandEx(param1, "say %s", g_viplist_f);
			}
			if (param2 == 3) 
			{
				FakeClientCommandEx(param1, "say %s", g_viprank_f);
			}
			if (param2 == 4)
			{
				FakeClientCommandEx(param1, "say %s", g_schange_f);
			}
			if (param2 == 5)
			{
				// Go back
				SendPanelToClient(panellib_info, param1, panellib_InfoHandler, 20);
			}
		}
	}
}


// Pressed something on the info handler
public panellib_InfoHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (clientlib_isValidClient(param1))
		{
			if (param2 == 4) 
			{
				// Credits
				SendPanelToClient(panellib_credits, param1, panellib_PanelHandler, 20);
			}

			if (param2 == 3)
			{ 
				// Open level overview
				DisplayMenu(panellib_levels, param1, 20);
			}

			if (param2 == 2) 
			{
				// Open command list menu
				SendPanelToClient(panellib_cmdlist, param1, panellib_CmdlistHandler, 20);
			}

			// Open feature list
			if (param2 == 1)
			{
				new Handle:featurelist = CreateMenu(panellib_FeatureListHandler);
				
				// title and exit button
				SetMenuTitle(featurelist, "%T", "HaveFeatures", param1);
				SetMenuExitBackButton(featurelist, true);
				
				decl String:featureid[10];
				
				// Loop through levels
				for (new i=0; i < g_levels+g_plevels; i++)
				{
					// Add level
					Format(featureid, sizeof(featureid), "%i", i+1);
					
					AddMenuItem(featurelist, featureid, g_LevelName[i]);
				}
				

				// Send
				DisplayMenu(featurelist, param1, 20);
			}
		}
	}
}


// Choose a level, now show features for this level
public panellib_FeatureListHandler(Handle:menu, MenuAction:action, param1, param2)
{
	// Selected and valid client
	if (action == MenuAction_Select && clientlib_isValidClient(param1))
	{
		decl String:Chooseit[10];
		decl String:featuretext[128];
		
		GetMenuItem(menu, param2, Chooseit, sizeof(Chooseit));
		
		// Get level
		new id = StringToInt(Chooseit);
		new Handle:featurelist = CreateMenu(panellib_FeatureHandler);
		
		SetMenuTitle(featurelist, "%T", "HaveFeatures", param1);
		SetMenuExitBackButton(featurelist, true);
		

		// Loop through all features
		for (new i=0; i < g_features; i++)
		{
			// Only enabled ones
			if (g_FeatureList[i][FEATURE_ENABLE])
			{
				// Loop through all descriptions on this level
				for (new j=0; j < g_FeatureList[i][FEATURE_DESCS][id]; j++)
				{
					// Only valid textes
					if (!StrEqual(g_FeatureHaveDesc[i][id][j], ""))
					{
						// Add text
						Format(featuretext, sizeof(featuretext), "%s", g_FeatureHaveDesc[i][id][j]);
						
						AddMenuItem(featurelist, "", featuretext);
					}
				}
			}
		}
		
		// Display menu
		DisplayMenu(featurelist, param1, 20);
	}

	else if (action == MenuAction_Cancel)
	{
		// Go back
		if (param2 == MenuCancel_ExitBack && clientlib_isValidClient(param1))
		{
			SendPanelToClient(panellib_info, param1, panellib_InfoHandler, 20);
		}
	}

	// Close
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
}


// Admin menu handler
public panellib_AdminHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		// Valid client
		if (clientlib_isValidClient(param1))
		{
			decl String:Chooseit[128];
			
			new Handle:playerlist;
			new Handle:featurelist;
			
			// Choose a player
			Format(Chooseit, sizeof(Chooseit), "%T", "ChoosePlayer", param1);
			
			// Delete or add points
			if (param2 == 1) 
			{
				playerlist = CreateMenu(panellib_PlayerListHandler);
			}
			else if (param2 == 2) 
			{
				playerlist = CreateMenu(panellib_PlayerListHandlerDelete);
			}

			// delete or add points
			if (param2 == 1 || param2 == 2)
			{
				decl String:clientname[MAX_NAME_LENGTH + 1];
				decl String:clientString[6];
						
				SetMenuTitle(playerlist, Chooseit);
				
				// Client loop
				for (new i = 1; i <= MaxClients; i++)
				{
					// Check valid
					if (clientlib_isValidClient(i))
					{
						// Add client
						Format(clientString, sizeof(clientString), "%i", i);
						
						GetClientName(i, clientname, sizeof(clientname));
						
						AddMenuItem(playerlist, clientString, clientname);
					}
				}

				// Display
				DisplayMenu(playerlist, param1, 30);
			}

			// Start happy hour
			if (param2 == 3)
			{	
				// Only when not running
				if (!g_happyhouron) 
				{
					otherlib_MakeHappyHour(param1);
				}
				else if (g_happyhouron) 
				{
					CPrintToChat(param1, "%s %t", g_StammTag, "HappyRunning");
				}
			}

			// stopp happy hour
			if (param2 == 4)
			{	
				// Only if running
				if (g_happyhouron)
				{ 
					otherlib_EndHappyHour();
				}
				else if (!g_happyhouron) 
				{
					CPrintToChat(param1, "%s %t", g_StammTag, "HappyNotRunning");
				}
			}

			// Load or unload feature
			if (param2 == 5 || param2 == 6)
			{	
				decl String:itemString[12];

				new bool:found = false;
				
				// Load
				if (param2 == 5)
				{
					featurelist = CreateMenu(panellib_FeaturelistLoadHandler);
				}

				// Unload
				if (param2 == 6)
				{
					featurelist = CreateMenu(panellib_FeaturelistUnloadHandler);
				}

				Format(Chooseit, sizeof(Chooseit), "%T", "ChooseFeature", param1);
				SetMenuTitle(featurelist, Chooseit);
				
				// Feature loop
				for (new i=0; i < g_features; i++)
				{
					// Check enable or disabled
					if ((g_FeatureList[i][FEATURE_ENABLE] == 0 && param2 == 5) || (g_FeatureList[i][FEATURE_ENABLE] == 1 && param2 == 6))
					{
						// ADD 
						Format(itemString, sizeof(itemString), "%i", i);
						AddMenuItem(featurelist, itemString, g_FeatureList[i][FEATURE_NAME]);
						
						// Check found
						found = true;
					}
				}
				
				// If found open
				if (found) 
				{
					DisplayMenu(featurelist, param1, 30);
				}
				else
				{ 
					CPrintToChat(param1, "%s %t", g_StammTag, "NoFeatureFound");
				}
			}
		}
	}
}