/**
 * -----------------------------------------------------
 * File        stamm_tag.sp
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
#include <cstrike>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1



new Handle:g_hTag;
new Handle:g_hAdmin;




// Details of plugin
public Plugin:myinfo =
{
	name = "Stamm Feature VIP Tag",
	author = "Popoklopsi",
	version = "1.4.1",
	description = "Give VIP's a VIP Tag",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// Add Feature for CSGO and CSS
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
	{
		SetFailState("Can't Load Feature, not Supported for your game!");
	}


	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP Tag", true, false);
}



// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	GetConVarString(g_hTag, fmt, sizeof(fmt));
	Format(fmt, sizeof(fmt), "%T", "GetTag", client, fmt);
	
	PushArrayString(array, fmt);
}



// Create the config
public OnPluginStart()
{
	AutoExecConfig_SetFile("clantag", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hTag = AutoExecConfig_CreateConVar("tag_text", "*VIP*", "Stamm Tag");
	g_hAdmin = AutoExecConfig_CreateConVar("tag_admin", "1", "1=Admins get also tag, 0=Off");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
	
	
	HookEvent("player_spawn", eventPlayerSpawn);
}




// Add auto updater
public STAMM_OnFeatureLoaded(const String:basename[])
{
	decl String:urlString[256];


	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	// Add to auto updater
	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
		Updater_ForceUpdate();
	}
}




// Client is ready, check name
public STAMM_OnClientReady(client)
{
	NameCheck(client);
}



public STAMM_OnClientBecomeVip(client, oldlevel, newlevel)
{
	// Name Check
	NameCheck(client);
}



// Client spawned, check also name
public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (STAMM_IsClientValid(client)) 
	{
		// Name Check
		NameCheck(client);
	}
}




// Check the name here
public NameCheck(client)
{
	decl String:name[MAX_NAME_LENGTH+1];
	decl String:tag[PLATFORM_MAX_PATH + 1];


	// Get client Tag
	CS_GetClientClanTag(client, name, sizeof(name));
	GetConVarString(g_hTag, tag, sizeof(tag));

	
	// Is VIP tag in name?
	if (StrContains(name, tag) != -1)
	{
		// But Player isn't a VIP oO?
		if (STAMM_GetClientLevel(client) < STAMM_GetBlockLevel(1))
		{
			// Strip the tage out
			ReplaceString(name, sizeof(name), tag, "");
			CS_SetClientClanTag(client, name);
		}
	}
	else
	{
		// Tag is not in name
		if (STAMM_HaveClientFeature(client)) 
		{
			// Add the tag if the player wants it
			if (GetConVarInt(g_hAdmin) || (!GetConVarInt(g_hAdmin) && !STAMM_IsClientAdmin(client))) 
			{
				CS_SetClientClanTag(client, tag);
			}
		}
	}
}