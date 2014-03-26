/**
 * -----------------------------------------------------
 * File        stamm_flagpoints.sp
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


// Includes
#include <sourcemod>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1




new Handle:g_hFlagNeed;



public Plugin:myinfo =
{
	name = "Stamm Feature FlagPoints",
	author = "Popoklopsi",
	version = "1.1.1",
	description = "Give only points to players with a specific flag",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};



// Auto updater
public STAMM_OnFeatureLoaded(const String:basename[])
{
	decl String:urlString[256];


	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
		Updater_ForceUpdate();
	}
}



// Create config
public OnPluginStart()
{
	AutoExecConfig_SetFile("flagpoints", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hFlagNeed = AutoExecConfig_CreateConVar("flag_need", "s", "Flag string a player needs to collect points");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}



// Add Feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}


	// Load Translation
	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP FlagPoints");
}





// Stop non VIP's getting points
public Action:STAMM_OnClientGetPoints_PRE(client, &number)
{
	decl String:tag[64];
	decl String:flagNeed[32];


	GetConVarString(g_hFlagNeed, flagNeed, sizeof(flagNeed));


	if ((GetUserFlagBits(client) & ReadFlagString(flagNeed) || GetUserFlagBits(client) & ADMFLAG_ROOT))
	{
		return Plugin_Continue;
	}
	else
	{
		STAMM_GetTag(tag, sizeof(tag));

		STAMM_PrintToChat(client, "%s %t", tag, "NoPoints", flagNeed);
	}

	return Plugin_Handled;
}