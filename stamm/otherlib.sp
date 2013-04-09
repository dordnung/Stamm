/**
 * -----------------------------------------------------
 * File        otherlib.sp
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

new Handle:otherlib_inftimer;


// Download files and precache
public otherlib_PrepareFiles()
{
	// Want a lvl up sound?
	if (!StrEqual(g_lvl_up_sound, "0")) 
	{
		// Download and precache it
		otherlib_DownloadLevel();	
		PrecacheSound(g_lvl_up_sound, true);
	}
}

// Add lvl up spound to downloads table
public otherlib_DownloadLevel()
{
	decl String:downloadfile[PLATFORM_MAX_PATH + 1];
	
	// Add with sound/
	Format(downloadfile, sizeof(downloadfile), "sound/%s", g_lvl_up_sound);
	
	AddFileToDownloadsTable(downloadfile);
}


// return the gameID
public otherlib_getGame()
{
	// We saved it globally
	return g_gameID;
}


// Get the agme
public otherlib_saveGame()
{
	new String:GameName[12];
	g_gameID = 0;
	
	// Get gamefolder name
	GetGameFolderName(GameName, sizeof(GameName));
	
	// Save cstrike, dod, tf or csgo
	if (StrEqual(GameName, "cstrike"))
	{ 
		g_gameID = 1;
	}
	if (StrEqual(GameName, "csgo")) 
	{ 
		g_gameID = 2;
	}
	if (StrEqual(GameName, "tf")) 
	{ 
		g_gameID = 3;
	}
	if (StrEqual(GameName, "dod"))
	{ 
		g_gameID = 4;
	}
}


// Listen for Server commands
public Action:otherlib_commandListener(client, const String:command[], argc)
{
	decl String:arg[128];
	new mode = 0;

	// Listen only for sm commands with 3 arguments and only for server commands 
	if (argc == 3 && client == 0 && StrEqual(command, "sm", false))
	{
		GetCmdArg(1, arg, sizeof(arg));

		// Is first argument plugins?
		if (StrEqual(arg, "plugins", false))
		{
			GetCmdArg(2, arg, sizeof(arg));

			// Second musst be load, unload or reload
			if (StrEqual(arg, "load", false))
			{
				mode = 1;
			}
			if (StrEqual(arg, "unload", false))
			{
				mode = 2;
			}
			if (StrEqual(arg, "reload", false))
			{
				mode = 3;
			}

			// Found a valid mode?
			if (mode != 0)
			{
				// get basename
				GetCmdArg(3, arg, sizeof(arg));

				// Loop through features and find the given basename
				for (new i=0; i < g_features; i++)
				{
					// Check short and real basename
					if (StrEqual(arg, g_FeatureList[i][FEATURE_BASE], false) || StrEqual(arg, g_FeatureList[i][FEATURE_BASEREAL], false))
					{

						if (mode == 1)
						{
							// Load mode
							featurelib_loadFeature(g_FeatureList[i][FEATURE_HANDLE]);
						}

						else if (mode == 2)
						{
							// Unload Mode
							featurelib_UnloadFeature(g_FeatureList[i][FEATURE_HANDLE]);
						}

						else
						{
							// Reload mode
							featurelib_ReloadFeature(g_FeatureList[i][FEATURE_HANDLE]);
						}

						// Announce that we give it to stamm
						PrintToServer("Attention: Found Stamm Feature! Action will transmit also to Stamm");

						// Handled, but we can't stop original command to stop
						return Plugin_Handled;
					}
				}
			}
		}
	}

	return Plugin_Continue;
}




// Info timer updated
public Action:otherlib_PlayerInfoTimer(Handle:timer, any:data)
{
	// Print infos to chat
	CPrintToChatAll("%s %t", g_StammTag, "InfoTyp", g_texttowrite_f);

	if (!g_useMenu)
	{
		CPrintToChatAll("%s %t", g_StammTag, "InfoTypInfo", g_sinfo_f);
	}
	
	// Go on
	return Plugin_Continue;
}




// Client want to start new Happy Hour
public otherlib_MakeHappyHour(client)
{
	// Mark that client want to set
	g_happynumber[client] = 1;
	
	// Notice next step
	CPrintToChat(client, "%s %t", g_StammTag, "WriteHappyTime");
	CPrintToChat(client, "%s %t", g_StammTag, "WriteHappyTimeInfo");
}




// End happy hour
public otherlib_EndHappyHour()
{
	if (g_happyhouron)
	{
		decl String:query[128];

		// Delete out of database
		Format(query, sizeof(query), "DELETE FROM `%s_happy`", g_tablename);
		
		// Announce step
		if (g_debug) 
		{
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		}

		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);


		// Reset
		g_points = 1;
		g_happyhouron = 0;
		
		// Delete old timer
		otherlib_checkTimer(g_HappyTimer);
		
		// Print end
		CPrintToChatAll("%s %t", g_StammTag, "HappyEnded");
	
		// Notice to API
		nativelib_HappyEnd();
		
		// Check players again
		clientlib_CheckPlayers();
	}
}



// Start happy hour
public otherlib_StartHappyHour(time, factor)
{
	decl String:query[128];

	// Insert new happy gour
	Format(query, sizeof(query), "INSERT INTO `%s_happy` (`end`, `factor`) VALUES (%i, %i)", g_tablename, GetTime() + time, factor);
	
	if (g_debug) 
	{
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
	}

	// Query
	SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);


	// Set global Points and mark as happy hour on 
	g_points = factor;
	g_happyhouron = 1;
	
	// Announce happy hour
	CPrintToChatAll("%s %t", g_StammTag, "HappyActive", g_points);
	
	// Check old timer
	otherlib_checkTimer(g_HappyTimer);

	// And start new
	g_HappyTimer = CreateTimer(float(time), otherlib_StopHappyHour);
	

	// Notice to api
	nativelib_HappyStart(time / 60, g_points);
}




// Timer to stop happy hour
public Action:otherlib_StopHappyHour(Handle:timer)
{
	// Give it to other method
	otherlib_EndHappyHour();
}





public Action:otherlib_StartHappy(args)
{
	// Only when it's not running
	if (GetCmdArgs() == 2 && !g_happyhouron)
	{
		decl String:timeString[25];
		decl String:factorString[25];
		
		// Get time and factor
		GetCmdArg(1, timeString, sizeof(timeString));
		GetCmdArg(2, factorString, sizeof(factorString));
		
		// String to int
		new time = StringToInt(timeString);
		new factor = StringToInt(factorString);

		// Valid time and factor?
		if (time > 1 && factor > 1)
		{
			// Start happy
			otherlib_StartHappyHour(time * 60, factor);
		}
		else
		{
			// Announce mistake
			ReplyToCommand(0, "[ STAMM ] Time and Factor have to be greater than 1 !");
		}
	}
	else
	{
		// How to use command
		ReplyToCommand(0, "Usage: stamm_start_happyhour <time> <factor>");
	}
}

// Stops happy hour
public Action:otherlib_StopHappy(args)
{
	// Just give it to another method
	otherlib_EndHappyHour();
}


// Checks a timer, end it when it's running and resetz it
public otherlib_checkTimer(Handle:timer)
{
	// End it
	if (timer != INVALID_HANDLE)
	{
		CloseHandle(timer);
	}

	// Reset Timer
	timer = INVALID_HANDLE;
}