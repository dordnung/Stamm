/**
 * -----------------------------------------------------
 * File        stamm_joinsound.sp
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


// Includes
#include <sourcemod>
#include <sdktools>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1



new Handle:j_path;
new bool:MapTimer = true;
new String:path[PLATFORM_MAX_PATH + 1];



public Plugin:myinfo =
{
	name = "Stamm Feature Joinsound",
	author = "Popoklopsi",
	version = "1.3.1",
	description = "Give VIP's a Joinsound",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};



// Auto updater
public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
	}
}



// Add feature
public OnAllPluginsLoaded()
{
	decl String:description[64];

	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}


	STAMM_LoadTranslation();
		
	Format(description, sizeof(description), "%T", "GetJoinsound", LANG_SERVER);
	
	STAMM_AddFeature("VIP Joinsound", description);
}



// Create Config
public OnPluginStart()
{
	AutoExecConfig_SetFile("joinsound", "stamm/features");

	j_path = AutoExecConfig_CreateConVar("joinsound_path", "music/stamm/vip_sound.mp3", "Path to joinsound, after sound/");
	
	AutoExecConfig(true, "joinsound", "stamm/features");
	AutoExecConfig_CleanFile();
}



// Load config and precache sound
public OnConfigsExecuted()
{
	new String:downloadfile[PLATFORM_MAX_PATH + 1];
	
	GetConVarString(j_path, path, sizeof(path));
	
	PrecacheSound(path, true);
	
	Format(downloadfile, sizeof(downloadfile), "sound/%s", path);
	AddFileToDownloadsTable(downloadfile);
}



// Client ready, start sound
public STAMM_OnClientReady(client)
{
	if (STAMM_HaveClientFeature(client) && MapTimer) 
	{
		CreateTimer(4.0, StartSound);
	}
}



// Mapchange protect
public OnMapStart()
{
	MapTimer = false;
	
	CreateTimer(60.0, MapTimer_Change);
}

public Action:MapTimer_Change(Handle:timer)
{
	MapTimer = true;
}



// Emit the sound
public Action:StartSound(Handle:timer)
{
	if (STAMM_GetGame() != GameCSGO) 
	{
		EmitSoundToAll(path);
	}
	else
	{
		for (new i=0; i <= MaxClients; i++)
		{
			if (STAMM_IsClientValid(i)) 
			{
				ClientCommand(i, "play %s", path);
			}
		}
	}
}