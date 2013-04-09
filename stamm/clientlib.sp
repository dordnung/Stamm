/**
 * -----------------------------------------------------
 * File        clientlib.sp
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


// semicolon
#pragma semicolon 1

new Handle:clientlib_olddelete;


// Is Client valid, without ready state
public bool:clientlib_isValidClient_PRE(client)
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
					decl String:steamid[32];
					
					clientlib_getSteamid(client, steamid, sizeof(steamid));
					
					// Good steamid format
					if (SimpleRegexMatch(steamid, "^STEAM_[0-1]{1}:[0-1]{1}:[0-9]+$") == 1)
					{
						return true;
					}
				}
			}
		}
	}
	
	return false;
}


// Is valid client
public bool:clientlib_isValidClient(client)
{
	// With ready state
	return (clientlib_isValidClient_PRE(client) && g_ClientReady[client]);
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

			SetHudTextParams(startPos, endPos, 0.6, 255, 255, 0, 255, 0, 0.0, 0.0, 0.0);
			ShowSyncHudText(client, g_hHudSync, "[STAMM] %T: %i", "Points", client, g_playerpoints[client]);
		}
	}

	return Plugin_Continue;
}



// Check a client as ready
public clientlib_ClientReady(client)
{
	if (clientlib_isValidClient_PRE(client))
	{
		// ready state to true
		g_ClientReady[client] = true;
		
		// Check VIP state
		clientlib_CheckVip(client);
		
		// check admin flag
		if (g_giveflagadmin)
		{ 
			clientlib_CheckFlagAdmin(client);
		}

		// Show points	
		if (g_join_show)
		{ 
			CreateTimer(5.0, pointlib_ShowPoints2, client);
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
public clientlib_IsSteamIDConnected(String:steamid[])
{
	decl String:cSteamid[64];

	// Client Loop
	for (new client = 1; client <= MaxClients; client++)
	{
		if (clientlib_isValidClient(client))
		{
			// Get steamid and check if it's equal
			clientlib_getSteamid(client, cSteamid, sizeof(cSteamid));

			if (StrEqual(steamid, cSteamid, false))
			{
				// return client
				return client;
			}
		}
	}

	return 0;
}



// Check if a client is a stamm admin
public bool:clientlib_IsAdmin(client)
{
	if (clientlib_isValidClient_PRE(client))
	{
		new AdminId:adminid = GetUserAdmin(client);
		new AdminFlag:flag;

		// Get AdminFlag of char
		FindFlagByChar(g_adminflag[0], flag);

		return GetAdminFlag(adminid, flag);
	}
	
	return false;
}


// Check if a client is a special VIP
public clientlib_IsSpecialVIP(client)
{
	if (clientlib_isValidClient(client))
	{
		new AdminId:adminid = GetUserAdmin(client);
		new AdminFlag:flag;

		// Private level loop
		for (new i=0; i < g_plevels; i++)
		{		
			// Check all flags, YEAH :D
			FindFlagByChar(g_LevelFlag[i][0], flag);

			if (GetAdminFlag(adminid, flag))
			{
				return i;
			}
		}
	}
	
	return -1;
}

// Give Player fast VIP
public clientlib_CheckFlagAdmin(client)
{
	new AdminId:adminid = GetUserAdmin(client);
	
	// and again, flag checking , oh man...
	if (g_giveflagadmin == 1 && GetAdminFlag(adminid, Admin_Custom1)) clientlib_GiveFastVIP(client);
	if (g_giveflagadmin == 2 && GetAdminFlag(adminid, Admin_Custom2)) clientlib_GiveFastVIP(client);
	if (g_giveflagadmin == 3 && GetAdminFlag(adminid, Admin_Custom3)) clientlib_GiveFastVIP(client);
	if (g_giveflagadmin == 4 && GetAdminFlag(adminid, Admin_Custom4)) clientlib_GiveFastVIP(client);
	if (g_giveflagadmin == 5 && GetAdminFlag(adminid, Admin_Custom5)) clientlib_GiveFastVIP(client);
	if (g_giveflagadmin == 6 && GetAdminFlag(adminid, Admin_Custom6)) clientlib_GiveFastVIP(client);
}




// Set level to highest level
public clientlib_GiveFastVIP(client)
{
	if (g_playerlevel[client] < g_levels)
	{
		pointlib_GivePlayerPoints(client, g_LevelPoints[g_levels-1], false);
	}
}



// Delete old players
public Action:clientlib_deleteOlds(Handle:timer, any:data)
{
	// check last valid entry
	new lastEntry = GetTime() - (g_delete * 24 * 60 * 60);

	decl String:query[128];

	// Delete all players less this line
	Format(query, sizeof(query), "DELETE FROM `%s` WHERE `last_visit` < %i", g_tablename, lastEntry);

	if (g_debug) 
	{
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
	}

	SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
	
	return Plugin_Continue;
}




// Check VIP state
public clientlib_CheckVip(client)
{
	if (sqllib_db != INVALID_HANDLE && clientlib_isValidClient(client))
	{
		decl String:steamid[64];
		new clientpoints = g_playerpoints[client];
		
		clientlib_getSteamid(client, steamid, sizeof(steamid));
		
		// Get level with client points
		new levelstufe = levellib_PointsToID(client, clientpoints);
		

		// is a private vip
		if (levelstufe == -1)
		{ 
			return;
		}

		// Only when level is a new one
		if (levelstufe > 0 && levelstufe != g_playerlevel[client])
		{
			decl String:name[MAX_NAME_LENGTH+1];
			decl String:setquery[256];	

			new bool:isUP = true;

			// new level not higher?
			if (g_playerlevel[client] > levelstufe)
			{
				isUP = false;
			}

			// Set new level
			g_playerlevel[client] = levelstufe;
			
			GetClientName(client, name, sizeof(name));
			

			// Notice to all
			if (!g_stripTag)
			{
				CPrintToChatAll("%s %t", g_StammTag, "LevelNowVIP", name, g_LevelName[levelstufe-1]);
			}
			else
			{
				CPrintToChatAll("%s %t", g_StammTag, "LevelNowLevel", name, g_LevelName[levelstufe-1]);
			}


			if (!g_stripTag)
			{
				// VIP
				CPrintToChat(client, "%s %t", g_StammTag, "JoinVIP");
			}
			else
			{
				// Level
				CPrintToChat(client, "%s %t", g_StammTag, "JoinLevel");
			}
			
			// Play lvl up sound if wanted
			if (!StrEqual(g_lvl_up_sound, "0") && isUP)
			{
				// for non CSGO
				if (otherlib_getGame() != 2) 
				{
					EmitSoundToAll(g_lvl_up_sound);
				}

				// For CSGO
				else
				{
					for (new i=0; i <= MaxClients; i++)
					{
						if (clientlib_isValidClient(i)) 
							ClientCommand(i, "play %s", g_lvl_up_sound);
					}
				}
			}

			// Update client on database
			Format(setquery, sizeof(setquery), "UPDATE `%s` SET `level`=%i WHERE `steamid`='%s'", g_tablename, levelstufe, steamid);
			
			if (g_debug) 
			{
				LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", setquery);
			}

			SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, setquery);


			// Notice to API
			nativelib_PublicPlayerBecomeVip(client);
		}
		else if (levelstufe == 0 && levelstufe != g_playerlevel[client])
		{
			// New level is no level, poor player ):
			decl String:queryback[256];
							
			// set to zero
			g_playerlevel[client] = 0;


			// Update to database
			Format(queryback, sizeof(queryback), "UPDATE `%s` SET `level`=0 WHERE `steamid`='%s'", g_tablename, steamid);
			
			if (g_debug) 
			{
				LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", queryback);
			}

			SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, queryback);
		}
	}
}



// Saves player points and feature states
public clientlib_SavePlayer(client, number)
{
	if (sqllib_db != INVALID_HANDLE && clientlib_isValidClient(client))
	{
		decl String:query[4024];
		decl String:steamid[64];
		
		clientlib_getSteamid(client, steamid, sizeof(steamid));
		
		// Zero points only?
		if (g_playerpoints[client] == 0)
		{
			Format(query, sizeof(query), "UPDATE `%s` SET `points`=0 ", g_tablename);
		}
		else
		{
			// Add new points
			Format(query, sizeof(query), "UPDATE `%s` SET `points`=`points`+(%i) ", g_tablename, number);
		}

		// Add all features to the call
		for (new i=0; i < g_features; i++)
		{
			Format(query, sizeof(query), "%s, `%s`=%i", query, g_FeatureList[i][FEATURE_BASE], g_FeatureList[i][WANT_FEATURE][client]);
		}

		Format(query, sizeof(query), "%s WHERE `steamid`='%s'", query, steamid);
		
		// Execute
		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);
		
		if (g_debug)
		{ 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

		// Notice to API
		nativelib_ClientSave(client);
	}
}



// Get the steamid
public clientlib_getSteamid(client, String:steamid[], size)
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
		if (g_happynumber[client] == 1)
		{
			// get the time
			new timetoset = StringToInt(text);
			
			// valid time?
			if (timetoset > 1)
			{  
				g_happynumber[client] = timetoset;
			}
			else
			{
				// Else abort
				g_happynumber[client] = 0;
				CPrintToChat(client, "%s %t", g_StammTag, "aborted");
				
				return Plugin_Handled;
			}
			
			// Notice next step
			CPrintToChat(client, "%s %t", g_StammTag, "WriteHappyFactor");
			CPrintToChat(client, "%s %t", g_StammTag, "WriteHappyFactorInfo");
			
			// type to factor
			g_happyfactor[client] = 1;
				
			return Plugin_Handled;	
		}
		else if (g_happyfactor[client] == 1)
		{
			// Get factor
			new factortoset = StringToInt(text);
			
			// Valid factor and happy hour not started?
			if (factortoset > 1 && !g_happyhouron) 
			{
				// Reset marke to start happy
				g_happyfactor[client] = 0;

				// Start happy
				otherlib_StartHappyHour(g_happynumber[client]*60, factortoset);
				
				g_happynumber[client] = 0;
			}
			else
			{
				// Abort
				CPrintToChat(client, "%s %t", g_StammTag, "aborted");
				
				g_happynumber[client] = 0;
				g_happyfactor[client] = 0;
			}
				
			return Plugin_Handled;	
		}

		else if (g_pointsnumber[client] > 0)
		{
			// want to add points
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
				

				// Give new points
				pointlib_GivePlayerPoints(choose, pointstoset, false);
				

				// Notice changes
				CPrintToChat(client, "%s %t", g_StammTag, "SetPoints", names, g_playerpoints[choose]);
				CPrintToChat(choose, "%s %t", g_StammTag, "SetPoints2", g_playerpoints[choose]);
			}
			
			g_pointsnumber[client] = 0;
			
			return Plugin_Handled;
		}

		//  Show viplist
		else if (StrEqual(text, g_viplist) && StrContains(g_viplist, "sm_") != 0)
		{
			// Get top ten
			sqllib_GetVipTop(client, 0);
		}

		// Vip Rank
		else if (StrEqual(text, g_viprank) && StrContains(g_viprank, "sm_") != 0)
		{
			// show rank
			sqllib_GetVipRank(client, 0);
		}

		else if (StrEqual(text, g_sinfo) && StrContains(g_sinfo, "sm_") != 0)
		{
			// show info panel
			panellib_CreateUserPanels(client, 3);
		}
		else if (StrEqual(text, g_schange) && StrContains(g_schange, "sm_") != 0)
		{
			// Show change list
			panellib_CreateUserPanels(client, 1);
		}
		else if (StrEqual(text, g_texttowrite) && StrContains(g_texttowrite, "sm_") != 0)
		{
			// Show player points
			if (!g_useMenu)
			{
				pointlib_ShowPlayerPoints(client, false);
			}
			else
			{
				SendPanelToClient(panellib_createInfoPanel(client), client, panellib_InfoHandler, 40);
			}
		}
		else if (StrEqual(text, g_admin_menu) && StrContains(g_admin_menu, "sm_") != 0 && clientlib_IsAdmin(client))
		{
			// Open admin menu
			panellib_CreateUserPanels(client, 4);
		}
	}
	
	return Plugin_Continue;
}




// Check players
public clientlib_CheckPlayers()
{
	new players = clientlib_GetPlayerCount();
	new factor = (MaxClients - players) + 1;

	// update global points	
	if (g_extra_points > 0)
	{
		// Only if happy hour not started
		if (!g_happyhouron)
		{ 
			g_points = factor;
		}
	}
}



// get current clients on server
public clientlib_GetPlayerCount()
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
