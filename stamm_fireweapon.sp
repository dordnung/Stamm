/**
 * -----------------------------------------------------
 * File        stamm_fireweapon.sp
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
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1




public Plugin:myinfo =
{
	name = "Stamm Feature FireWeapon",
	author = "Popoklopsi",
	version = "1.1.1",
	description = "VIP's can ignite players with there weapon",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// Add to auto updater
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




// Add feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}


	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP FireWeapon");
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetFireWeapon", client);
	
	PushArrayString(array, fmt);
}




// Hook player hurt
public OnPluginStart()
{
	HookEvent("player_hurt", PlayerHurt);
}




public PlayerHurt(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (STAMM_IsClientValid(attacker) && client > 0 && client != attacker)
	{
		// Ignite on hit hehe
		if (STAMM_HaveClientFeature(attacker) && IsClientInGame(client) && IsPlayerAlive(client) && (GetClientTeam(client) != GetClientTeam(attacker)))
		{
			IgniteEntity(client, 2.0);
		}
	}
}