/**
 * -----------------------------------------------------
 * File        stamm_instant_defuse.sp
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

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1



public Plugin:myinfo =
{
	name = "Stamm Feature Instant Defuse",
	author = "Popoklopsi",
	version = "1.3.0",
	description = "VIP's can defuse the bomb instantly",
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




// Add Feature
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
	STAMM_AddFastFeature("VIP Instant Defuse", "%T", "GetInstantDefuse", LANG_SERVER);
}




// Hook defuse begin
public OnPluginStart()
{
	HookEvent("bomb_begindefuse", Event_Defuse);
}




// Handle defusing
public Event_Defuse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (STAMM_IsClientValid(client))
	{
		// Set to defuse
		if (STAMM_HaveClientFeature(client)) 
		{
			CreateTimer(0.5, setCountdown, client);
		}
	}
}



// No set countdown to zero
public Action:setCountdown(Handle:timer, any:client)
{
	new bombent = FindEntityByClassname(-1, "planted_c4");
	
	if (bombent) 
	{
		SetEntPropFloat(bombent, Prop_Send, "m_flDefuseCountDown", 0.1);
	}
}