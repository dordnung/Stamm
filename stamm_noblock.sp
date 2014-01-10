/**
 * -----------------------------------------------------
 * File        stamm_noblock.sp
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
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1


new coll_offset;


public Plugin:myinfo =
{
	name = "Stamm Feature NoBlock",
	author = "Popoklopsi",
	version = "1.2.0",
	description = "Non VIP's cant' walk through VIP's",
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
	}
}



// Add feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}


	STAMM_LoadTranslation();
	STAMM_AddFastFeature("VIP NoBlock", "%T", "GetNoBlock", LANG_SERVER);
	

	// Get Noblock offset
	coll_offset = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	
	// Found?
	if (coll_offset == -1)
	{ 
		SetFailState("Can't Load Feature, failed to find CBaseEntity::m_CollisionGroup");
	}
}




// Hook spawn
public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
}




// Playe spawned
public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Valid client?
	if (STAMM_IsClientValid(client))
	{
		if (!STAMM_HaveClientFeature(client))
		{
			// Non VIP's are in no blocking mode
			SetEntData(client, coll_offset, 2, 4, true);
		}
	}
	else
	{
		// Set noblock
		SetEntData(client, coll_offset, 2, 4, true);
	}
}