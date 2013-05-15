/**
 * -----------------------------------------------------
 * File        pointlib.sp
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


// Use semicolon
#pragma semicolon 1



new Handle:pointlib_timetimer;
new Handle:pointlib_showpointer;




// Init. pointslib
public pointlib_Start()
{
	Format(g_sTextToWriteF, sizeof(g_sTextToWriteF), g_sTextToWrite);
	
	// Register commands for add, del and set points
	RegServerCmd("stamm_add_points", pointlib_AddPlayerPoints, "Add Points of a Player: stamm_add_points <userid|steamid> <points>");
	RegServerCmd("stamm_del_points", pointlib_DelPlayerPoints, "Del Points of a Player: stamm_del_points <userid|steamid> <points>");
	RegServerCmd("stamm_set_points", pointlib_SetPlayerPoints, "Set Points of a Player: stamm_set_points <userid|steamid> <points>");


	// Register main stamm command and strip "sm_"
	if (!StrContains(g_sTextToWrite, "sm_"))
	{
		RegConsoleCmd(g_sTextToWrite, pointlib_ShowPoints);
		
		ReplaceString(g_sTextToWriteF, sizeof(g_sTextToWriteF), "sm_", "!");
	}
}





// Handle timer to add points
public Action:pointlib_PlayerTime(Handle:timer)
{
	// Client loop
	for (new i = 1; i <= MaxClients; i++)
	{
		if (clientlib_isValidClient(i))
		{
			// right team -> add global points
			if ((GetClientTeam(i) == 2 || GetClientTeam(i) == 3) && g_iMinPlayer <= clientlib_GetPlayerCount())
			{
				pointlib_GivePlayerPoints(i, g_iPoints, true);
			}
		}
	}


	return Plugin_Continue;
}





// Timer to show points
public Action:pointlib_PointShower(Handle:timer)
{
	// Show points to each player
	for (new i = 1; i <= MaxClients; i++) 
	{
		pointlib_ShowPlayerPoints(i, true);
	}

	return Plugin_Continue;
}







// add points to a player
public Action:pointlib_AddPlayerPoints(args)
{
	if (GetCmdArgs() == 2)
	{
		decl String:useridString[64];
		decl String:numberString[25];
		


		// Get userid or steamid and number
		GetCmdArg(1, useridString, sizeof(useridString));
		GetCmdArg(2, numberString, sizeof(numberString));



		// Get number
		new number = StringToInt(numberString);



		// check if it's a userid
		if (StrContains(useridString, "STEAM_", false) < 0)
		{
			new client = GetClientOfUserId(StringToInt(useridString));
			

			// Add points
			if (clientlib_isValidClient(client))
			{
				pointlib_GivePlayerPoints(client, number, false);
			}
			else
			{
				ReplyToCommand(0, "Error. Couldn't find userid %s", useridString);
			}
		}

		// Handle steamid 
		else
		{
			// Replace STEAM_1: to STEAM_0:
			ReplaceString(useridString, sizeof(useridString), "STEAM_1:", "STEAM_0:", false);

			// get client of steamid
			new client = clientlib_IsSteamIDConnected(useridString);



			// Found on server?
			if (client > 0)
			{
				// Give points
				pointlib_GivePlayerPoints(client, number, false);
			}
			else
			{
				// Else update on database
				decl String:query[128];



				Format(query, sizeof(query), g_sUpdateAddPointsSteamidQuery, g_sTableName, number, useridString);



				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
				
				if (g_bDebug) 
				{
					LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Execute %s", query);
				}
			}
		}
	}

	else
	{
		ReplyToCommand(0, "Usage: stamm_add_points <userid|steamid> <points>");
	}


	return Plugin_Handled;
}







// Set Player points
public Action:pointlib_SetPlayerPoints(args)
{
	if (GetCmdArgs() == 2)
	{
		decl String:useridString[64];
		decl String:numberString[25];
		


		GetCmdArg(1, useridString, sizeof(useridString));
		GetCmdArg(2, numberString, sizeof(numberString));



		new number = StringToInt(numberString);



		// Steamid handle
		if (StrContains(useridString, "STEAM_", false) < 0)
		{
			new client = GetClientOfUserId(StringToInt(useridString));
			


			// valid client and number greate or equal zero
			if (clientlib_isValidClient(client) && number >= 0)
			{
				// Diff and add
				new diff = number - g_iPlayerPoints[client];

				pointlib_GivePlayerPoints(client, diff, false);
			}
			else
			{
				ReplyToCommand(0, "Error. Couldn't find userid %s or number is less than zero.", useridString);
			}
		}
		else
		{
			// Check if client is ingame -> when not set on database
			ReplaceString(useridString, sizeof(useridString), "STEAM_1:", "STEAM_0:", false);

			new client = clientlib_IsSteamIDConnected(useridString);



			if (client > 0)
			{
				new diff = number - g_iPlayerPoints[client];

				pointlib_GivePlayerPoints(client, diff, false);
			}
			else
			{
				decl String:query[128];

				Format(query, sizeof(query), g_sUpdateSetPointsQuery, g_sTableName, number, useridString);



				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
				
				if (g_bDebug) 
				{
					LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Execute %s", query);
				}
			}
		}
	}
	else
	{
		ReplyToCommand(0, "Usage: stamm_set_points <userid|steamid> <points>");
	}



	return Plugin_Handled;
}






// And delete points
public Action:pointlib_DelPlayerPoints(args)
{
	if (GetCmdArgs() == 2)
	{
		decl String:useridString[64];
		decl String:numberString[25];
		


		GetCmdArg(1, useridString, sizeof(useridString));
		GetCmdArg(2, numberString, sizeof(numberString));


		new number = StringToInt(numberString) *-1;
		


		// Again steamid handle
		if (StrContains(useridString, "STEAM_", false) < 0)
		{
			new client = GetClientOfUserId(StringToInt(useridString));
			
			if (clientlib_isValidClient(client))
			{
				// delete points
				pointlib_GivePlayerPoints(client, number, false);
			}
			else
			{
				ReplyToCommand(0, "Error. Couldn't find userid %s", useridString);
			}
		}
		else
		{
			// Check if client is ingame -> when not delete on database
			ReplaceString(useridString, sizeof(useridString), "STEAM_1:", "STEAM_0:", false);



			new client = clientlib_IsSteamIDConnected(useridString);



			if (client > 0)
			{
				pointlib_GivePlayerPoints(client, number, false);
			}
			else
			{
				decl String:query[128];



				Format(query, sizeof(query), g_sUpdateAddPointsSteamidQuery, g_sTableName, number, useridString);



				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
				
				if (g_bDebug) 
				{
					LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Execute %s", query);
				}
			}
		}
	}

	else
	{
		ReplyToCommand(0, "Usage: stamm_del_points <userid|steamid> <points>");
	}

	return Plugin_Handled;
}







// Points handler
public Action:pointlib_ShowPoints2(Handle:timer, any:client)
{
	// Show points
	pointlib_ShowPlayerPoints(client, false);
	
	return Plugin_Handled;
}






// Console command to show points
public Action:pointlib_ShowPoints(client, arg)
{
	// Show player points
	if (!g_bUseMenu)
	{
		pointlib_ShowPlayerPoints(client, false);
	}
	else
	{
		SendPanelToClient(panellib_createInfoPanel(client), client, panellib_InfoHandler, 40);
	}
	
	return Plugin_Handled;
}






// Give points to player
public pointlib_GivePlayerPoints(client, number, bool:check)
{
	// Negativ number? and on delete less than zero?
	if (number < 0 && g_iPlayerPoints[client] + number < 0)
	{
		// Delete zo zero
		number = -g_iPlayerPoints[client];
	}



	// Check if a feature stop getting points
	if (check)
	{
		new Action:result;

		// Get result of API
		result = nativelib_PublicPlayerGetPointsPlugin(client, number);
		

		// maybe block?
		if (result != Plugin_Changed && result != Plugin_Continue)
		{
			return;
		}
	}



	// Handle less than zero
	if (number < 0 && g_iPlayerPoints[client] + number < 0)
	{
		g_iPlayerPoints[client] = 0;
	}
	else
	{
		// Finally add points
		g_iPlayerPoints[client] = g_iPlayerPoints[client] + number;
	}



	// Check vip and save him
	clientlib_CheckVip(client);
	clientlib_SavePlayer(client, number);


	// Notice to API
	nativelib_PublicPlayerGetPoints(client, number);
}






// Show points
public pointlib_ShowPlayerPoints(client, bool:only)
{
	if (clientlib_isValidClient(client))
	{
		decl String:name[MAX_NAME_LENGTH+1];
		decl String:vip[32];



		GetClientName(client, name, sizeof(name));
		


		// Get points
		new restpoints = 0;
		new index = g_iPlayerLevel[client];
		new points = g_iPlayerPoints[client];



		// Format VIP String
		Format(vip, sizeof(vip), " %T", "VIP", client);




		
		// If not highest level, calculate rest points
		if (index != g_iLevels && index < g_iLevels) 
		{
			restpoints = g_iLevelPoints[index] - g_iPlayerPoints[client];
		}




		// Show to all or only to client
		if (!g_bSeeText || only)
		{
			// Highest level?
			if (index != g_iLevels && index < g_iLevels) 
			{
				if (!g_bStripTag)
				{
					if (!g_bMoreColors)
					{
						CPrintToChat(client, "%s %t", g_sStammTag, "NoVIPClient", points, restpoints, g_sLevelName[g_iPlayerLevel[client]], vip);
					}
					else
					{
						MCPrintToChat(client, "%s %t", g_sStammTag, "NoVIPClient", points, restpoints, g_sLevelName[g_iPlayerLevel[client]], vip);
					}
				}
				else
				{
					if (!g_bMoreColors)
					{
						CPrintToChat(client, "%s %t", g_sStammTag, "NoVIPClient", points, restpoints, g_sLevelName[g_iPlayerLevel[client]], "");
					}
					else
					{
						MCPrintToChat(client, "%s %t", g_sStammTag, "NoVIPClient", points, restpoints, g_sLevelName[g_iPlayerLevel[client]], "");
					}
				}
			}
			else
			{ 
				if (!g_bStripTag)
				{
					if (!g_bMoreColors)
					{
						CPrintToChat(client, "%s %t", g_sStammTag, "VIPClient", points, g_sLevelName[index-1], vip);
					}
					else
					{
						MCPrintToChat(client, "%s %t", g_sStammTag, "VIPClient", points, g_sLevelName[index-1], vip);
					}
				}
				else
				{
					if (!g_bMoreColors)
					{
						CPrintToChat(client, "%s %t", g_sStammTag, "VIPClient", points, g_sLevelName[index-1], "");
					}
					else
					{
						MCPrintToChat(client, "%s %t", g_sStammTag, "VIPClient", points, g_sLevelName[index-1], "");
					}
				}
			}
		}
		else
		{
			if (index != g_iLevels && index < g_iLevels) 
			{
				if (!g_bStripTag)
				{
					if (!g_bMoreColors)
					{
						CPrintToChatAll("%s %t", g_sStammTag, "NoVIPAll", name, points, restpoints, g_sLevelName[g_iPlayerLevel[client]], vip);
					}
					else
					{
						MCPrintToChatAll("%s %t", g_sStammTag, "NoVIPAll", name, points, restpoints, g_sLevelName[g_iPlayerLevel[client]], vip);
					}
				}
				else
				{
					if (!g_bMoreColors)
					{
						CPrintToChatAll("%s %t", g_sStammTag, "NoVIPAll", name, points, restpoints, g_sLevelName[g_iPlayerLevel[client]], "");
					}
					else
					{
						MCPrintToChatAll("%s %t", g_sStammTag, "NoVIPAll", name, points, restpoints, g_sLevelName[g_iPlayerLevel[client]], "");
					}
				}
			}
			else
			{ 
				if (!g_bStripTag)
				{
					if (!g_bMoreColors)
					{
						CPrintToChatAll("%s %t", g_sStammTag, "VIPAll", name, points, g_sLevelName[index-1], vip);
					}
					else
					{
						MCPrintToChatAll("%s %t", g_sStammTag, "VIPAll", name, points, g_sLevelName[index-1], vip);
					}
				}
				else
				{
					if (!g_bMoreColors)
					{
						CPrintToChatAll("%s %t", g_sStammTag, "VIPAll", name, points, g_sLevelName[index-1], "");
					}
					else
					{
						MCPrintToChatAll("%s %t", g_sStammTag, "VIPAll", name, points, g_sLevelName[index-1], "");
					}
				}
			}
		}
	}
}