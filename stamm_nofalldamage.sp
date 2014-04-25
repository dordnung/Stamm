/**
 * -----------------------------------------------------
 * File        stamm_nofalldamage.sp
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
#include <sdkhooks>

#undef REQUIRE_PLUGIN 
#include <stamm>
#include <updater>

#pragma semicolon 1





public Plugin:myinfo =
{
	name = "Stamm Feature No Fall Damage",
	author = "Popoklopsi",
	version = "1.2.1",
	description = "Give VIP's No Fall Damage",
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




// Add feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	if (!LibraryExists("sdkhooks")) 
	{
		SetFailState("Can't Load Feature, SDKHooks is not installed!");
	}


	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP No Fall Damage");
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetNoFallDamage", client);
	
	PushArrayString(array, fmt);
}





// Client is ready hook him
public STAMM_OnClientReady(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}




// Client toke damage
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			// Just was fall damage??
			if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && IsPlayerAlive(client))
			{
				if (damagetype & DMG_FALL)
				{
					// Do no damage
					return Plugin_Handled;
				}
			}
		}
	}
	
	return Plugin_Continue;
}
