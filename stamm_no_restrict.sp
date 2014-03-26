/**
 * -----------------------------------------------------
 * File        stamm_no_restrict.sp
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

#undef REQUIRE_PLUGIN
#include <stamm>
#include <restrict>
#include <cstrike_weapons>
#include <updater>

#pragma semicolon 1



new bool:g_bWeaponRestrict[WeaponID];



public Plugin:myinfo =
{
	name = "Stamm Feature No Restrict",
	author = "Popoklopsi",
	version = "1.3.1",
	description = "VIP's can use restricted weapons",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// Auto Updater
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
	decl String:path[PLATFORM_MAX_PATH + 1];
	new Handle:kv;


	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	
	// We need plugin weaponrestrict	
	if (!LibraryExists("weaponrestrict")) 
	{
		SetFailState("Can't Load Feature, Weapon Restrict is not installed!");
	}
	
	
	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
	{
		SetFailState("Can't Load Feature, not Supported for your game!");
	}


	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP No Restrict");


	if (STAMM_GetGame() == GameCSGO)
	{
		// Config for CSGO
		Format(path, sizeof(path), "cfg/stamm/features/weapon_restricts_csgo.txt");
	}

	else
	{
		// Config for CSS
	 	Format(path, sizeof(path), "cfg/stamm/features/weapon_restricts_css.txt");
	}


	// File doesn't exists? we cen abort here
	if (!FileExists(path))
	{
		SetFailState("Couldn't find the config %s", path);
	}



	// Read the config
	kv = CreateKeyValues("WeaponRestricts");
	FileToKeyValues(kv, path);
	


	// Parse config
	if (KvGotoFirstSubKey(kv, false))
	{
		decl String:buffer[120];

		do
		{
			// Get Weaponname
			KvGetSectionName(kv, buffer, sizeof(buffer));

			// And go back
			KvGoBack(kv);
			
			//  Get status of weapon
			g_bWeaponRestrict[GetWeaponID(buffer)] = (KvGetNum(kv, buffer) == 1);
			

			KvJumpToKey(kv, buffer);
		} 
		while (KvGotoNextKey(kv, false));

		// Go Back
		KvRewind(kv);
	}

	CloseHandle(kv);
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetNoRestrict", client);
	
	PushArrayString(array, fmt);
}




// Player want to buy somehing
public Action:Restrict_OnCanBuyWeapon(client, team, WeaponID:id, &CanBuyResult:result)
{
	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			// Normally he can't buy it
			if (result != CanBuy_Allow && g_bWeaponRestrict[id])
			{
				// But now he can :)
				result = CanBuy_Allow;
				
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}




// Player picked up a item
public Action:Restrict_OnCanPickupWeapon(client, team, WeaponID:id, &bool:result)
{
	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			// Normally he can't pick it up
			if (result != true && g_bWeaponRestrict[id])
			{
				// Now he can :)
				result = true;
				
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}