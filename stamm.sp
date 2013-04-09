/**
 * -----------------------------------------------------
 * File        stamm.sp
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


// Include Sourcemod API's
#include <sourcemod>
#include <sdktools>
#include <colors>
#include <autoexecconfig>
#include <regex>

// Tf2
#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>

// Max Features and Max Levels
#define MAXFEATURES 100
#define MAXLEVELS 100


// Stamm Includes
#include "stamm/globals.sp"
#include "stamm/configlib.sp"
#include "stamm/levellib.sp"
#include "stamm/sqllib.sp"
#include "stamm/sqlback.sp"
#include "stamm/pointlib.sp"
#include "stamm/clientlib.sp"
#include "stamm/nativelib.sp"
#include "stamm/panellib.sp"
#include "stamm/eventlib.sp"
#include "stamm/featurelib.sp"
#include "stamm/otherlib.sp"


// Maybe include the updater if exists
#undef REQUIRE_PLUGIN
#include <updater>


// Use Semicolon
#pragma semicolon 1



// Plugin Information
public Plugin:myinfo =
{
	name = "Stamm",
	author = "Popoklopsi",
	version = g_Plugin_Version2,
	description = "A powerful VIP Addon with a lot of features",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};


// Add Natives and handle late load
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	nativelib_Start();
	
	g_isLate = late;
	
	return APLRes_Success;
}


// Finally it's loaded
public OnPluginStart()
{

	// Check the folders we need
	CheckStammFolders();


	// Fix color when Lightgreen isn't available
	if (!CColorAllowed(Color_Lightgreen))
	{
		if (CColorAllowed(Color_Lime))
		{
			CReplaceColor(Color_Lightgreen, Color_Lime);
		}
		else if (CColorAllowed(Color_Olive))
		{
			CReplaceColor(Color_Lightgreen, Color_Olive);
		}
	}


	// Load stamm Translation 
	LoadTranslations("stamm.phrases");


	// Add start default point settings
	g_points = 1;
	g_happyhouron = 0;
	

	// Stamm Tag for general use
	Format(g_StammTag, sizeof(g_StammTag), "{lightgreen}[ {green}Stamm {lightgreen}]");
	


	// Register Say Filter
	RegConsoleCmd("say", clientlib_CmdSay);



	// Register the Server Commands
	RegServerCmd("stamm_start_happyhour", otherlib_StartHappy, "Starts happy hour: stamm_start_happyhour <time> <factor>");
	RegServerCmd("stamm_stop_happyhour", otherlib_StopHappy, "Stops happy hour");

	RegServerCmd("stamm_feature_load", featurelib_Load, "Loads a feature: stamm_feature_load <basename>");
	RegServerCmd("stamm_feature_unload", featurelib_UnLoad, "Unloads a feature: stamm_feature_unload <basename>");
	RegServerCmd("stamm_feature_reload", featurelib_ReLoad, "Reloads a feature: stamm_feature_reload <basename>");

	RegServerCmd("stamm_feature_list", featurelib_List, "List all features.");

	RegServerCmd("stamm_convert_db", sqllib_convertDB, "Converts the stamm database to a file. stamm_convert_db <mysql>");



	// Command listener for load, reload and unload commands
	AddCommandListener(otherlib_commandListener);
	

	// Init. Stamm Components
	otherlib_saveGame();
	levellib_LoadLevels();
	configlib_CreateConfig();
	eventlib_Start();
	

	// Create Hud Sync
	g_hHudSync = CreateHudSynchronizer();

	// No, it's not started, yet
	g_pluginStarted = false;
}




// Handle Plugin End and Unload all features
public OnPluginEnd()
{
	for (new i=0; i < g_features; i++)
	{
		if (g_FeatureList[i][FEATURE_ENABLE] == 1)
		{
			// Unload all Features
			featurelib_UnloadFeature(g_FeatureList[i][FEATURE_HANDLE]);
		}
	}
}



// Also handle pause to avoid errors
public OnPluginPauseChange(bool:pause)
{
	if (pause)
	{
		// On Pause End Plugin
		OnPluginEnd();
	}
	else
	{
		// On unpause load all features again
		for (new i=0; i < g_features; i++)
		{
			if (g_FeatureList[i][FEATURE_ENABLE] == 1)
			{
				featurelib_loadFeature(g_FeatureList[i][FEATURE_HANDLE]);
			}
		}
	}
}


// Check the folders we need
public CheckStammFolders()
{
	// Strings
	decl String:LogFolder[PLATFORM_MAX_PATH +1];
	decl String:LevelFolder[PLATFORM_MAX_PATH +1];
	decl String:CurrentDate[20];
	

	// Current time
	FormatTime(CurrentDate, sizeof(CurrentDate), "%d-%m-%y");
	

	// Build Path to the needed folders
	BuildPath(Path_SM, g_StammFolder, sizeof(g_StammFolder), "Stamm");
	BuildPath(Path_SM, g_LogFile, sizeof(g_LogFile), "Stamm/logs/Stamm_Logs (%s).log", CurrentDate);
	BuildPath(Path_SM, g_DebugFile, sizeof(g_DebugFile), "Stamm/logs/Stamm_Debugs (%s).log", CurrentDate);
	

	// Format logs and levels folders
	Format(LogFolder, sizeof(LogFolder), "%s/logs", g_StammFolder);
	Format(LevelFolder, sizeof(LevelFolder), "%s/levels", g_StammFolder);
	
	
	// Check if main stamm folder exists
	if (DirExists(g_StammFolder))
	{
		// Check log folder
		if (!DirExists(LogFolder)) 
		{
			CreateDirectory(LogFolder, 511);
		}
			

		// Check level folder
		if (!DirExists(LevelFolder)) 
		{
			CreateDirectory(LevelFolder, 511);
		}
	}
	else
	{
		// If not create all
		CreateDirectory(g_StammFolder, 511);
		CreateDirectory(LogFolder, 511);
		CreateDirectory(LevelFolder, 511);
	}
}


// Configs are ready to use
public OnConfigsExecuted()
{
	// Load the Configs
	configlib_LoadConfig();


	// Add Auto Updater if exit and want
	if (LibraryExists("updater") && autoUpdate)
	{
		Updater_AddPlugin("http://popoklopsi.de/stamm/updater/update.php?plugin=stamm");
	}
	

	// No mapchange? Real load
	if (!g_pluginStarted)
	{	
		// Start rest of stamm componants
		// They need the config
		sqllib_Start();
		pointlib_Start();
		sqllib_LoadDB();
	
		panellib_Start();
		
		// Get the database version
		sqlback_getDatabaseVersion();
	}
	

	// Delete old Timers
	otherlib_checkTimer(pointlib_timetimer);
	otherlib_checkTimer(pointlib_showpointer);
	otherlib_checkTimer(otherlib_inftimer);
	otherlib_checkTimer(clientlib_olddelete);
	

	// get Time points? start timer
	if (g_vip_type == 3 || g_vip_type == 5 || g_vip_type == 6 ||  g_vip_type == 7)
	{
		pointlib_timetimer = CreateTimer((60.0*g_time_point), pointlib_PlayerTime, _, TIMER_REPEAT);
	}
		
	// Show points some times
	if (g_showpoints) 
	{
		pointlib_showpointer = CreateTimer(float(g_showpoints), pointlib_PointShower, _, TIMER_REPEAT);
	}
	
	// Show information about stamm	
	if (g_infotime > 0.0) 
	{
		otherlib_inftimer = CreateTimer(g_infotime, otherlib_PlayerInfoTimer, _, TIMER_REPEAT);
	}

	// Delete old players
	if (g_delete) 
	{
		clientlib_olddelete = CreateTimer(36000.0, clientlib_deleteOlds, _, TIMER_REPEAT);
	}

	// Hud Text?
	if (otherlib_getGame() == 3 && g_hudText == 1)
	{
		CreateTimer(0.5, clientlib_ShowHudText, _, TIMER_REPEAT);
	}
	

	// Download files and load them
	otherlib_PrepareFiles();
}



// Finally ready to start off
public stammStarted()
{	

	// no late load -> load all features added
	if (!g_isLate)
	{
		CreateTimer(0.5, featurelib_loadFeatures, -1);
	}
	else 
	{
		// Late loaded
		decl String:pathdir[PLATFORM_MAX_PATH + 1];
		decl String:buffer[PLATFORM_MAX_PATH + 1];

		new FileType:typs;

		// Path to the stamm plugins
		BuildPath(Path_SM, pathdir, sizeof(pathdir), "plugins/stamm");

		// Open the dir
		new Handle:dir = OpenDirectory(pathdir);

		// Valid dir?
		if (dir != INVALID_HANDLE)
		{
			// Read all files
			while (ReadDirEntry(dir, buffer, sizeof(buffer), typs))
			{
				// is it a file?
				if (typs == FileType_File)
				{
					// is it a .smx file?
					if (StrContains(buffer, ".smx", false) > 0)
					{
						// Load the feature
						ReplaceString(buffer, sizeof(buffer), ".smx", "", false);

						ServerCommand("sm plugins load stamm/%s", buffer);
					}
				}
			}

			// Close dir
			CloseHandle(dir);
		}

		// Load all features
		CreateTimer(2.0, featurelib_loadFeatures, -1);
	}

	// If debug, notice stamm started
	if (g_debug)
	{
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Stamm successfully loaded");
	}
}