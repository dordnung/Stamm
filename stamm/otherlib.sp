/**
 * -----------------------------------------------------
 * File        otherlib.sp
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


// Use semicolon
#pragma semicolon 1

new Handle:otherlib_inftimer;





// Download files and precache
otherlib_PrepareFiles()
{
	decl String:lvlUpSound[PLATFORM_MAX_PATH + 1];

	// Want a lvl up sound?
	GetConVarString(configlib_LvlUpSound, lvlUpSound, sizeof(lvlUpSound));

	if (!StrEqual(lvlUpSound, "0")) 
	{
		decl String:downloadfile[PLATFORM_MAX_PATH + 1];

		// Download and precache it
		// Add with sound/
		Format(downloadfile, sizeof(downloadfile), "sound/%s", lvlUpSound);
		
		AddFileToDownloadsTable(downloadfile);


		// CSGO Fix
		if (g_iGameID == GAME_CSGO)
		{
			AddToStringTable(FindStringTable("soundprecache"), lvlUpSound);
		}
		else
		{
			PrecacheSound(lvlUpSound);
		}
	}
}




// Get the agme
otherlib_saveGame()
{
	new String:GameName[12];
	g_iGameID = GAME_UNSUPPORTED;
	


	// Get gamefolder name
	GetGameFolderName(GameName, sizeof(GameName));
	


	// Save cstrike, dod, tf or csgo
	if (StrEqual(GameName, "cstrike"))
	{ 
		g_iGameID = GAME_CSS;
	}

	else if (StrEqual(GameName, "csgo")) 
	{ 
		g_iGameID = GAME_CSGO;
	}

	else if (StrEqual(GameName, "tf")) 
	{ 
		g_iGameID = GAME_TF2;
	}

	else if (StrEqual(GameName, "dod"))
	{ 
		g_iGameID = GAME_DOD;
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

			else if (StrEqual(arg, "unload", false))
			{
				mode = 2;
			}

			else if (StrEqual(arg, "reload", false))
			{
				mode = 3;
			}


			// Found a valid mode?
			if (mode != 0)
			{
				// get basename
				GetCmdArg(3, arg, sizeof(arg));


				// Loop through features and find the given basename
				for (new i=0; i < g_iFeatures; i++)
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


	// Go on
	return Plugin_Continue;
}





// Info timer updated
public Action:otherlib_PlayerInfoTimer(Handle:timer, any:data)
{
	// Print infos to chat
	if (!g_bMoreColors)
	{
		CPrintToChatAll("%s %t", g_sStammTag, "InfoTyp", g_sTextToWriteF);
	}
	else
	{
		MCPrintToChatAll("%s %t", g_sStammTag, "InfoTyp", g_sTextToWriteF);
	}




	if (!GetConVarBool(configlib_UseMenu))
	{
		if (!g_bMoreColors)
		{
			CPrintToChatAll("%s %t", g_sStammTag, "InfoTypInfo", g_sInfoF);
		}
		else
		{
			MCPrintToChatAll("%s %t", g_sStammTag, "InfoTypInfo", g_sInfoF);
		}
	}
	

	// Go on
	return Plugin_Continue;
}





// Client want to start new Happy Hour
otherlib_MakeHappyHour(client)
{
	// Mark that client want to set
	g_iHappyNumber[client] = 1;
	

	// Notice next step
	if (!g_bMoreColors)
	{
		CPrintToChat(client, "%s %t", g_sStammTag, "WriteHappyTime");
		CPrintToChat(client, "%s %t", g_sStammTag, "WriteHappyTimeInfo");
	}
	else
	{
		MCPrintToChat(client, "%s %t", g_sStammTag, "WriteHappyTime");
		MCPrintToChat(client, "%s %t", g_sStammTag, "WriteHappyTimeInfo");
	}
}





// End happy hour
otherlib_EndHappyHour()
{
	if (g_bHappyHourON)
	{
		new Handle:tmpFile = otherlib_openTempFile();


		if (tmpFile != INVALID_HANDLE)
		{
			if (KvJumpToKey(tmpFile, "happyhour"))
			{
				KvDeleteKey(tmpFile, "end");
				KvDeleteKey(tmpFile, "factor");
			}

			otherlib_saveTempFile(tmpFile);
		}



		// Reset
		g_iPoints = 1;
		g_bHappyHourON = false;
		

		// Delete old timer
		otherlib_checkTimer(g_hHappyTimer);


		// Print end
		if (!g_bMoreColors)
		{
			CPrintToChatAll("%s %t", g_sStammTag, "HappyEnded");
		}
		else
		{
			MCPrintToChatAll("%s %t", g_sStammTag, "HappyEnded");
		}



		// Notice to API
		nativelib_HappyEnd();
		
		// Check players again
		clientlib_CheckPlayers();
	}
}






// Start happy hour
otherlib_StartHappyHour(time, factor)
{
	new Handle:tmpFile = otherlib_openTempFile();

	if (tmpFile != INVALID_HANDLE)
	{
		if (KvJumpToKey(tmpFile, "happyhour", true))
		{
			KvSetNum(tmpFile, "end", GetTime() + time);
			KvSetNum(tmpFile, "factor", factor);
		}

		otherlib_saveTempFile(tmpFile);
	}



	// Set global Points and mark as happy hour on 
	g_iPoints = factor;
	g_bHappyHourON = true;
	


	// Announce happy hour
	if (!g_bMoreColors)
	{
		CPrintToChatAll("%s %t", g_sStammTag, "HappyActive", g_iPoints);
	}
	else
	{
		MCPrintToChatAll("%s %t", g_sStammTag, "HappyActive", g_iPoints);
	}
	


	// Check old timer
	otherlib_checkTimer(g_hHappyTimer);



	// And start new
	g_hHappyTimer = CreateTimer(float(time), otherlib_StopHappyHour);
	


	// Notice to api
	nativelib_HappyStart(time, g_iPoints);
}








// Timer to stop happy hour
public Action:otherlib_StopHappyHour(Handle:timer)
{
	g_hHappyTimer = INVALID_HANDLE;
	
	// Give it to other method
	otherlib_EndHappyHour();
}






public Action:otherlib_StartHappy(args)
{
	// Only when it's not running
	if (GetCmdArgs() == 2 && !g_bHappyHourON)
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
			otherlib_StartHappyHour(time, factor);
		}
		else
		{
			// Announce mistake
			ReplyToCommand(0, "[ STAMM ] Time and Factor have to be greater than 1 !");
		}
	}
	else if (GetCmdArgs() != 2)
	{
		// How to use command
		ReplyToCommand(0, "Usage: stamm_start_happyhour <time_in_seconds> <factor>");
	}
	else
	{
		ReplyToCommand(0, "Stamm Happy-Hour is already running!");
	}
}





// Stops happy hour
public Action:otherlib_StopHappy(args)
{
	// Just give it to another method
	otherlib_EndHappyHour();
}




// Check for old happy hour
otherlib_checkOldHappy()
{
	new Handle:tmpFile = otherlib_openTempFile();
	new end = -1;
	new factor = -1;

	if (tmpFile != INVALID_HANDLE)
	{
		if (KvJumpToKey(tmpFile, "happyhour", true))
		{
			end = KvGetNum(tmpFile, "end", -1);
			factor = KvGetNum(tmpFile, "factor", -1);
		}

		otherlib_saveTempFile(tmpFile);
	}


	if (factor > 1 && end > -1)
	{
		new time = GetTime();

		// is end in future?
		if (end > time)
		{
			otherlib_StartHappyHour(end-time, factor);
		}
	}
}



// Checks a timer, end it when it's running and reset it
otherlib_checkTimer(&Handle:timer)
{
	// End it
	if (timer != INVALID_HANDLE)
	{
		CloseHandle(timer);
	}


	// Reset Timer
	timer = INVALID_HANDLE;
}



// Logging Stuff
StammLog(bool:useDebug, String:fmt[], any:...)
{
	decl String:format[1024];
	decl String:file[PLATFORM_MAX_PATH + 1];
	decl String:CurrentDate[32];


	// Build Path to the needed folders
	BuildPath(Path_SM, file, sizeof(file), "logs");

	VFormat(format, sizeof(format), fmt, 3);
	FormatTime(CurrentDate, sizeof(CurrentDate), "%d-%m-%y");


	if (useDebug && GetConVarBool(configlib_StammDebug))
	{
		Format(file, sizeof(file), "%s/stamm_debugs_(%s).log", file, CurrentDate);

		LogToFile(file, "[ STAMM DEBUG ] %s", format);
	}
	else if (!useDebug)
	{
		Format(file, sizeof(file), "%s/stamm_errors_(%s).log", file, CurrentDate);

		LogToFile(file, "[ STAMM ] %s", format);
	}
}



Handle:otherlib_openTempFile()
{
	decl String:path[PLATFORM_MAX_PATH + 1];

	Format(path, sizeof(path), "cfg/stamm");

	if (!DirExists(path))
	{
		if (!CreateDirectory(path, 493))
		{
			return INVALID_HANDLE;
		}
	}

	new Handle:kvalue = CreateKeyValues("stamm_tmp");
	Format(path, sizeof(path), "cfg/stamm/tmp.txt");

	if (!FileExists(path))
	{
		if (!KeyValuesToFile(kvalue, path))
		{
			CloseHandle(kvalue);

			return INVALID_HANDLE;
		}
	}
	else
	{
		if (!FileToKeyValues(kvalue, path))
		{
			CloseHandle(kvalue);

			return INVALID_HANDLE;
		}
	}

	return kvalue;
}



otherlib_saveTempFile(Handle:tmpFile)
{
	if (tmpFile != INVALID_HANDLE)
	{
		KvRewind(tmpFile);
		KeyValuesToFile(tmpFile, "cfg/stamm/tmp.txt");

		CloseHandle(tmpFile);
	}
}