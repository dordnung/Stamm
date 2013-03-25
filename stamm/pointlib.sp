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
	Format(g_texttowrite_f, sizeof(g_texttowrite_f), g_texttowrite);
	
	// Register commands for add, del and set points
	RegServerCmd("stamm_add_points", pointlib_AddPlayerPoints, "Add Points of a Player: stamm_add_points <userid|steamid> <points>");
	RegServerCmd("stamm_del_points", pointlib_DelPlayerPoints, "Del Points of a Player: stamm_del_points <userid|steamid> <points>");
	RegServerCmd("stamm_set_points", pointlib_SetPlayerPoints, "Set Points of a Player: stamm_set_points <userid|steamid> <points>");


	// Register main stamm command and strip "sm_"
	if (!StrContains(g_texttowrite, "sm_"))
	{
		RegConsoleCmd(g_texttowrite, pointlib_ShowPoints);
		
		ReplaceString(g_texttowrite_f, sizeof(g_texttowrite_f), "sm_", "!");
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
			if ((GetClientTeam(i) == 2 || GetClientTeam(i) == 3) && g_min_player <= clientlib_GetPlayerCount())
			{
				pointlib_GivePlayerPoints(i, g_points, true);
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
		pointlib_ShowPlayerPoints(i);
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

				Format(query, sizeof(query), "UPDATE `%s` SET `points`=`points`+(%i) WHERE `steamid`='%s'", g_tablename, number, useridString);

				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
				
				if (g_debug) 
				{
					LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
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
				new diff = number - g_playerpoints[client];

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
				new diff = number - g_playerpoints[client];

				pointlib_GivePlayerPoints(client, diff, false);
			}
			else
			{
				decl String:query[128];

				Format(query, sizeof(query), "UPDATE `%s` SET `points`=%i WHERE `steamid`='%s'", g_tablename, number, useridString);

				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
				
				if (g_debug) 
				{
					LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
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

				Format(query, sizeof(query), "UPDATE `%s` SET `points`=`points`+(%i) WHERE `steamid`='%s'", g_tablename, number, useridString);

				SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
				
				if (g_debug) 
				{
					LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
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
	pointlib_ShowPlayerPoints(client);
	
	return Plugin_Handled;
}

// Console command to show points
public Action:pointlib_ShowPoints(client, arg)
{
	// Show points
	pointlib_ShowPlayerPoints(client);
	
	return Plugin_Handled;
}

// Give points to player
public pointlib_GivePlayerPoints(client, number, bool:check)
{
	// Negativ number? and on delete less than zero?
	if (number < 0 && g_playerpoints[client] + number < 0)
	{
		// Delete zo zero
		number = -g_playerpoints[client];
	}

	// Check if a feature stop getting points
	if (check)
	{
		new Action:result;

		// Feature loop
		for (new i=0; i < g_features; i++)
		{
			// Only enabled feature
			if (g_FeatureList[i][FEATURE_ENABLE] == 1)
			{
				// Get result of API
				result = nativelib_PublicPlayerGetPointsPlugin(g_FeatureList[i][FEATURE_HANDLE], client, number);
				
				// maybe block?
				if (result != Plugin_Changed && result != Plugin_Continue)
				{
					return;
				}
			}
		}
	}

	// Handle less than zero
	if (number < 0 && g_playerpoints[client] + number < 0)
	{
		g_playerpoints[client] = 0;
	}
	else
	{
		// Finally add points
		g_playerpoints[client] = g_playerpoints[client] + number;
	}

	// Check vip and save him
	clientlib_CheckVip(client);
	clientlib_SavePlayer(client, number);

	// Notice to API
	nativelib_PublicPlayerGetPoints(client, number);
}


// Show points
public pointlib_ShowPlayerPoints(client)
{
	if (clientlib_isValidClient(client))
	{
		decl String:name[MAX_NAME_LENGTH+1];
		
		GetClientName(client, name, sizeof(name));
		
		// Get points
		new restpoints = 0;
		new index = g_playerlevel[client];
		new points = g_playerpoints[client];
		
		// If not highest level, calculate rest points
		if (index != g_levels && index < g_levels) 
		{
			restpoints = g_LevelPoints[index] - g_playerpoints[client];
		}

		// Show to all or only to client
		if (!g_see_text)
		{
			// Highest level?
			if (index != g_levels && index < g_levels) 
			{
				CPrintToChat(client, "%s %t", g_StammTag, "NoVIPClient", points, restpoints, g_LevelName[g_playerlevel[client]]);
			}
			else
			{ 
				CPrintToChat(client, "%s %t", g_StammTag, "VIPClient", points, g_LevelName[index-1]);
			}
		}
		else
		{
			if (index != g_levels && index < g_levels) 
			{
				CPrintToChatAll("%s %t", g_StammTag, "NoVIPAll", name, points, restpoints, g_LevelName[g_playerlevel[client]]);
			}
			else
			{ 
				CPrintToChatAll("%s %t", g_StammTag, "VIPAll", name, points, g_LevelName[index-1]);
			}
		}
	}
}