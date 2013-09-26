/**
 * -----------------------------------------------------
 * File        stamm_tag.sp
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
#include <cstrike>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1



new Handle:s_tag;
new Handle:s_admin;
new admin_tag;

new String:tag[PLATFORM_MAX_PATH + 1];




// Details of plugin
public Plugin:myinfo =
{
	name = "Stamm Feature VIP Tag",
	author = "Popoklopsi",
	version = "1.4.0",
	description = "Give VIP's a VIP Tag",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// Add Feature for CSGO and CSS
public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
	{
		SetFailState("Can't Load Feature, not Supported for your game!");
	}


	STAMM_LoadTranslation();

	STAMM_AddFeature("VIP Tag", "", true, false);
}



// Create the config
public OnPluginStart()
{
	AutoExecConfig_SetFile("tag", "stamm/features");

	s_tag = AutoExecConfig_CreateConVar("tag_text", "*VIP*", "Stamm Tag");
	s_admin = AutoExecConfig_CreateConVar("tag_admin", "1", "1=Admins get also tag, 0=Off");
	
	AutoExecConfig(true, "tag", "stamm/features");
	AutoExecConfig_CleanFile();
	
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
	}
	

	STAMM_AddBlockDescription(1, "%T", "GetTag", LANG_SERVER, tag);
}



// Load config
public OnConfigsExecuted()
{
	GetConVarString(s_tag, tag, sizeof(tag));
	admin_tag = GetConVarInt(s_admin);
}



// Client is ready, check name
public STAMM_OnClientReady(client)
{
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
	new String:name[MAX_NAME_LENGTH+1];
	
	// Get client Tag
	CS_GetClientClanTag(client, name, sizeof(name));
	
	// Is VIP tag in name?
	if (StrContains(name, tag) != -1)
	{
		// But Player isn't a VIP oO?
		if (!STAMM_IsClientVip(client, STAMM_GetLevel()))
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
			if (admin_tag || (!admin_tag && !STAMM_IsClientAdmin(client))) 
			{
				CS_SetClientClanTag(client, tag);
			}
		}
	}
}