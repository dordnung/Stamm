/**
 * -----------------------------------------------------
 * File        clientlib.sp
 * Authors     David <popoklopsi> Ordnung
 * License     GPLv3
 * Web         http://popoklopsi.de
 * -----------------------------------------------------
 * 
 * Copyright (C) 2012-2014 David <popoklopsi> Ordnung
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


// semicolon
#pragma semicolon 1

new Handle:clientlib_olddelete;





// Is Client valid, without ready state
bool:clientlib_isValidClient_PRE(client)
{
	if (client > 0 && client <= MaxClients)
	{
		if (IsClientInGame(client))
		{
			if (IsClientAuthorized(client))
			{
				// No fake client
				if (!IsClientSourceTV(client) && !IsClientReplay(client) && !IsFakeClient(client))
				{
					return true;
				}
			}
		}
	}
	
	return false;
}






// Is valid client
bool:clientlib_isValidClient(client)
{
	// With ready state
	return (clientlib_isValidClient_PRE(client) && g_bClientReady[client]);
}






// Insert player after admin check
public OnClientPostAdminCheck(client)
{
	if (clientlib_isValidClient_PRE(client)) 
	{
		sqllib_InsertPlayer(client);
	}
}






// Set the Text for client!
public Action:clientlib_ShowHudText(Handle:timer, any:data)
{
	// Client Loop
	for (new client = 1; client <= MaxClients; client++)
	{
		// Client Valid?
		if (clientlib_isValidClient(client))
		{
			new Float:startPos;
			new Float:endPos;
			

			// Set position of text.
			if (TF2_GetPlayerClass(client) != TFClass_Engineer)
			{
				startPos = 0.01;
				endPos = 0.01;
			}
			else
			{
				startPos = 0.21;
				endPos = 0.02;
			}


			// Show the hud text
			SetHudTextParams(startPos, endPos, 0.6, 255, 255, 0, 255, 0, 0.0, 0.0, 0.0);
			ShowSyncHudText(client, g_hHudSync, "[STAMM] %t: %i", "Points", g_iPlayerPoints[client]);
		}
	}



	return Plugin_Continue;
}







// Check a client as ready
clientlib_ClientReady(client)
{
	if (clientlib_isValidClient_PRE(client))
	{
		// ready state to true
		g_bClientReady[client] = true;
		
		// Check VIP state
		clientlib_CheckVip(client);
		


		// check admin flag
		if (!StrEqual(g_sGiveFlagAdmin, "0") && !StrEqual(g_sGiveFlagAdmin, ""))
		{ 
			clientlib_CheckFlagAdmin(client);
		}

		// Show points	
		if (g_bJoinShow)
		{ 
			CreateTimer(5.0, pointlib_ShowPoints2, GetClientUserId(client));
		}



		// Check Players again
		clientlib_CheckPlayers();

		// Notice ready state to API
		nativelib_ClientReady(client);
	}
}






// A client disconnected
public OnClientDisconnect(client)
{
	// Save Player
	clientlib_SavePlayer(client, 0);

	// Check Players
	clientlib_CheckPlayers();
}






// Checks if a steamid is connected
clientlib_IsSteamIDConnected(String:steamid[])
{
	decl String:cSteamid[64];
	decl String:search[64];


	// Copy to buffer
	strcopy(search, sizeof(search), steamid);

	// Replace STEAM_1: with STEAM_0:
	ReplaceString(search, sizeof(search), "STEAM_1:", "STEAM_0:");


	// Client Loop
	for (new client = 1; client <= MaxClients; client++)
	{
		if (clientlib_isValidClient(client))
		{
			// Get steamid and check if it's equal
			clientlib_getSteamid(client, cSteamid, sizeof(cSteamid));


			if (StrEqual(search, cSteamid, false))
			{
				// return client
				return client;
			}
		}
	}


	return 0;
}






// Check if a client is a stamm admin
bool:clientlib_IsAdmin(client)
{
	if (clientlib_isValidClient_PRE(client))
	{
		return (GetUserFlagBits(client) & ReadFlagString(g_sAdminFlag) || GetUserFlagBits(client) & ADMFLAG_ROOT);
	}
	

	return false;
}







// Check if a client is a special VIP
clientlib_IsSpecialVIP(client)
{
	if (clientlib_isValidClient(client))
	{
		// Private level loop
		for (new i=0; i < g_iPLevels; i++)
		{		
			if ((GetUserFlagBits(client) & ReadFlagString(g_sLevelFlag[i])))
			{
				return i;
			}
		}
	}
	

	// No special
	return -1;
}





// Give Player fast VIP
clientlib_CheckFlagAdmin(client)
{
	// Flag checking
	if (GetUserFlagBits(client) & ReadFlagString(g_sGiveFlagAdmin))
	{
		clientlib_GiveFastVIP(client);
	}
}






// Set level to highest level
clientlib_GiveFastVIP(client)
{
	if (g_iPlayerLevel[client] < g_iLevels)
	{
		// Set points to highest level
		pointlib_GivePlayerPoints(client, g_iLevelPoints[g_iLevels - 1], false);
	}
}






// Delete old players
public Action:clientlib_deleteOlds(Handle:timer, any:data)
{
	decl String:query[128];

	// check last valid entry
	new lastEntry = GetTime() - (g_iDelete * 24 * 60 * 60);



	// Delete all players less this line
	Format(query, sizeof(query), g_sDeleteOldQuery, g_sTableName, lastEntry);



	if (g_bDebug) 
	{
		LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Execute %s", query);
	}



	SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
	
	return Plugin_Continue;
}






// Check VIP state
clientlib_CheckVip(client)
{
	if (sqllib_db != INVALID_HANDLE && clientlib_isValidClient(client) && (g_iLevels + g_iPLevels > 0))
	{
		decl String:steamid[64];
		new clientpoints = g_iPlayerPoints[client];
		new levelstufe;



		clientlib_getSteamid(client, steamid, sizeof(steamid));
		
		// Get level with client points
		levelstufe = levellib_PointsToID(client, clientpoints);
		


		// is a private vip
		if (levelstufe == -1)
		{ 
			return;
		}




		// Only when level is a new one
		if (levelstufe > 0 && levelstufe != g_iPlayerLevel[client])
		{
			decl String:name[MAX_NAME_LENGTH+1];
			decl String:setquery[256];	

			new oldlevel = g_iPlayerLevel[client];
			new bool:isUP = true;



			// new level not higher?
			if (g_iPlayerLevel[client] > levelstufe)
			{
				isUP = false;
			}



			// Set new level
			g_iPlayerLevel[client] = levelstufe;
			
			GetClientName(client, name, sizeof(name));
			




			// Notice to all
			if (!g_bStripTag)
			{
				if (!g_bMoreColors)
				{
					CPrintToChatAll("%s %t", g_sStammTag, "LevelNowVIP", name, g_sLevelName[levelstufe-1]);
				}
				else
				{
					MCPrintToChatAll("%s %t", g_sStammTag, "LevelNowVIP", name, g_sLevelName[levelstufe-1]);
				}
			}
			else
			{
				if (!g_bMoreColors)
				{
					CPrintToChatAll("%s %t", g_sStammTag, "LevelNowLevel", name, g_sLevelName[levelstufe-1]);
				}
				else
				{
					MCPrintToChatAll("%s %t", g_sStammTag, "LevelNowLevel", name, g_sLevelName[levelstufe-1]);
				}
			}





			// Rejoin
			if (!g_bMoreColors)
			{
				CPrintToChat(client, "%s %t", g_sStammTag, "JoinVIP");
			}
			else
			{
				MCPrintToChat(client, "%s %t", g_sStammTag, "JoinVIP");
			}
			


			// Play lvl up sound if wanted
			if (!StrEqual(g_sLvlUpSound, "0") && isUP)
			{
				EmitSoundToAll(g_sLvlUpSound);
			}



			// Update client on database
			Format(setquery, sizeof(setquery), g_sUpdatePlayerQuery, g_sTableName, levelstufe, steamid);
			
			if (g_bDebug) 
			{
				LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Execute %s", setquery);
			}

			SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, setquery);




			// Notice to API
			nativelib_PublicPlayerBecomeVip(client, oldlevel, g_iPlayerLevel[client]);
		}

		else if (levelstufe == 0 && levelstufe != g_iPlayerLevel[client])
		{
			// New level is no level, poor player ):
			decl String:queryback[256];

			// set to zero
			g_iPlayerLevel[client] = 0;


			// Update to database
			Format(queryback, sizeof(queryback), g_sUpdatePlayerQuery, g_sTableName, 0, steamid);
			
			if (g_bDebug) 
			{
				LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Execute %s", queryback);
			}

			SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, queryback);
		}
	}
}








// Saves player points and feature states
clientlib_SavePlayer(client, number)
{
	if (sqllib_db != INVALID_HANDLE && clientlib_isValidClient(client))
	{
		decl String:query[4024];
		decl String:steamid[64];

		clientlib_getSteamid(client, steamid, sizeof(steamid));


		// Zero points only?
		if (g_iPlayerPoints[client] == 0)
		{
			Format(query, sizeof(query), g_sUpdateSetPointsZeroQuery, g_sTableName);
		}
		else
		{
			// Add new points
			Format(query, sizeof(query), g_sUpdateAddPointsQuery, g_sTableName, number);
		}


		// Add all features to the call
		for (new i=0; i < g_iFeatures; i++)
		{
			Format(query, sizeof(query), "%s, `%s`=%i", query, g_FeatureList[i][FEATURE_BASE], g_FeatureList[i][WANT_FEATURE][client]);
		}

		Format(query, sizeof(query), "%s WHERE `steamid`='%s'", query, steamid);


		// Execute
		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
		
		if (g_bDebug)
		{ 
			LogToFile(g_sDebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}


		// Notice to API
		nativelib_ClientSave(client);
	}
}






// Get the steamid
clientlib_getSteamid(client, String:steamid[], size)
{
	GetClientAuthString(client, steamid, size);
	
	// Replace STEAM_1: with STEAM_0:
	ReplaceString(steamid, size, "STEAM_1:", "STEAM_0:");
}






// Command Say filter
public Action:clientlib_CmdSay(client, args)
{
	decl String:text[128];
	decl String:name[MAX_NAME_LENGTH+1];
	
	GetClientName(client, name, sizeof(name));
	GetCmdArgString(text, sizeof(text));
	


	// Parse out "
	ReplaceString(text, sizeof(text), "\"", "");
	


	if (clientlib_isValidClient(client))
	{
		// Want the player start happy hour?
		if (g_iHappyNumber[client] == 1)
		{
			// get the time
			new timetoset = StringToInt(text);
			

			// valid time?
			if (timetoset > 1)
			{  
				g_iHappyNumber[client] = timetoset;
			}
			else
			{
				// Else abort
				g_iHappyNumber[client] = 0;



				if (!g_bMoreColors)
				{
					CPrintToChat(client, "%s %t", g_sStammTag, "aborted");
				}
				else
				{
					MCPrintToChat(client, "%s %t", g_sStammTag, "aborted");
				}
				
				return Plugin_Handled;
			}
			


			// Notice next step
			if (!g_bMoreColors)
			{
				CPrintToChat(client, "%s %t", g_sStammTag, "WriteHappyFactor");
				CPrintToChat(client, "%s %t", g_sStammTag, "WriteHappyFactorInfo");
			}
			else
			{
				MCPrintToChat(client, "%s %t", g_sStammTag, "WriteHappyFactor");
				MCPrintToChat(client, "%s %t", g_sStammTag, "WriteHappyFactorInfo");
			}
			

			// type to factor
			g_iHappyFactor[client] = 1;


			return Plugin_Handled;	
		}

		else if (g_iHappyFactor[client] == 1)
		{
			// Get factor
			new factortoset = StringToInt(text);
			

			// Valid factor and happy hour not started?
			if (factortoset > 1 && !g_bHappyHourON) 
			{
				// Reset marke to start happy
				g_iHappyFactor[client] = 0;

				// Start happy
				otherlib_StartHappyHour(g_iHappyNumber[client]*60, factortoset);
				
				g_iHappyNumber[client] = 0;
			}
			else
			{
				// Abort
				if (!g_bMoreColors)
				{
					CPrintToChat(client, "%s %t", g_sStammTag, "aborted");
				}
				else
				{
					MCPrintToChat(client, "%s %t", g_sStammTag, "aborted");
				}
				


				g_iHappyNumber[client] = 0;
				g_iHappyFactor[client] = 0;
			}
				
			return Plugin_Handled;	
		}

		else if (g_iPointsNumber[client] > 0)
		{
			// want to add points
			if (StrEqual(text, " "))
			{
				g_iPointsNumber[client] = 0;

				if (!g_bMoreColors)
				{
					CPrintToChat(client, "%s %t", g_sStammTag, "aborted");
				}
				else
				{
					MCPrintToChat(client, "%s %t", g_sStammTag, "aborted");
				}
				
				return Plugin_Handled;
			}
			


			new choose = g_iPointsNumber[client];
			new pointstoset = StringToInt(text);
			


			if (clientlib_isValidClient(choose))
			{
				new String:names[MAX_NAME_LENGTH+1];
				
				GetClientName(choose, names, sizeof(names));
				

				// Give new points
				pointlib_GivePlayerPoints(choose, pointstoset, false);
				

				// Notice changes
				if (!g_bMoreColors)
				{
					CPrintToChat(client, "%s %t", g_sStammTag, "SetPoints", names, g_iPlayerPoints[choose]);
					CPrintToChat(choose, "%s %t", g_sStammTag, "SetPoints2", g_iPlayerPoints[choose]);
				}
				else
				{
					MCPrintToChat(client, "%s %t", g_sStammTag, "SetPoints", names, g_iPlayerPoints[choose]);
					MCPrintToChat(choose, "%s %t", g_sStammTag, "SetPoints2", g_iPlayerPoints[choose]);
				}
			}
			


			g_iPointsNumber[client] = 0;
			
			return Plugin_Handled;
		}

		//  Show viplist
		else if (StrEqual(text, g_sVipList) && StrContains(g_sVipList, "sm_") != 0)
		{
			// Get top ten
			sqllib_GetVipTop(client, 0);
		}

		// Vip Rank
		else if (StrEqual(text, g_sVipRank) && StrContains(g_sVipRank, "sm_") != 0)
		{
			// show rank
			sqllib_GetVipRank(client, 0);
		}

		else if (StrEqual(text, g_sInfo) && StrContains(g_sInfo, "sm_") != 0)
		{
			// show info panel
			panellib_CreateUserPanels(client, 3);
		}

		else if (StrEqual(text, g_sChange) && StrContains(g_sChange, "sm_") != 0)
		{
			// Show change list
			panellib_CreateUserPanels(client, 1);
		}

		else if (StrEqual(text, g_sTextToWrite) && StrContains(g_sTextToWrite, "sm_") != 0)
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
		}

		else if (StrEqual(text, g_sAdminMenu) && StrContains(g_sAdminMenu, "sm_") != 0 && clientlib_IsAdmin(client))
		{
			// Open admin menu
			panellib_CreateUserPanels(client, 4);
		}
	}
	


	return Plugin_Continue;
}







// Check players
clientlib_CheckPlayers()
{
	// update global points	
	if (g_bExtraPoints)
	{
		// Only if happy hour not started
		if (!g_bHappyHourON)
		{ 
			new players = clientlib_GetPlayerCount();
			new factor = (MaxClients - players) + 1;
			
			g_iPoints = factor;
		}
	}
}






// get current clients on server
clientlib_GetPlayerCount()
{
	new players = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (clientlib_isValidClient(i))
		{
			// Update player count
			players++;
		}
	}

	return players;
}
