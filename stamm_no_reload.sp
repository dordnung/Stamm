/**
 * -----------------------------------------------------
 * File        stamm_no_reload.sp
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

#undef REQUIRE_EXTENSIONS
#include <tf2>

#pragma semicolon 1




public Plugin:myinfo =
{
	name = "Stamm Feature No Reload",
	author = "Popoklopsi",
	version = "1.3.0",
	description = "VIP's don't have to reload",
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

	if (STAMM_GetGame() == GameDOD) 
	{
		SetFailState("Can't Load Feature, not Supported for your game!");
	}


	// Load Trans.
	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP No Reload");


	// Weapon fire for non TF2 games
	if (STAMM_GetGame() != GameTF2)
	{
		HookEvent("weapon_fire", eventWeaponFire);
	}
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetNoReload", client);
	
	PushArrayString(array, fmt);
}





// Weapon fire (TF2)
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	// Give no reload
	giveNoReload(client, weaponname);

	return Plugin_Continue;
}



// Weapon fire (other than TF2)
public Action:eventWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:weapons[64];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// Get weapon name
	GetEventString(event, "weapon", weapons, sizeof(weapons));

	// Give no reload
	giveNoReload(client, weapons);
}




// Give no reload to a weapon
public giveNoReload(client, String:weapons[])
{
	decl String:Pri[64];
	decl String:Sec[64];

	if (STAMM_IsClientValid(client))
	{
		// Is VIP?
		if (STAMM_HaveClientFeature(client))
		{
			new pri_i = GetPlayerWeaponSlot(client, 0);
			new sec_i = GetPlayerWeaponSlot(client, 1);
			new weapon;


			// Found prim. weapon?
			if (pri_i != -1)
			{
				GetEdictClassname(pri_i, Pri, sizeof(Pri));

				// Strip weapon_ for non tf2
				if (STAMM_GetGame() != GameTF2)
				{
					ReplaceString(Pri, sizeof(Pri), "weapon_", "");
				}
			}

			
			// Found sec. weapon
			if (sec_i != -1)
			{
				GetEdictClassname(sec_i, Sec, sizeof(Sec));

				if (STAMM_GetGame() != GameTF2)
				{
					ReplaceString(Sec, sizeof(Sec), "weapon_", "");
				}
			}


			// Is weapon the prim. weapon?
			if (StrEqual(weapons, Pri))
			{
				weapon = pri_i;
			}

			// Or the sec. weapon?	
			else if (StrEqual(weapons, Sec))
			{
				weapon = sec_i;
			}

			else
			{ 
				// Something went wrong here
				return;
			}



			// Get clip annd ammo
			new clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
			new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
			

			// Clip less than 4?
			if (clip <= 3)
			{		
				// And ammo greater zero?
				if (ammo > 0)
				{
					// Take ammo and set it to the clip
					SetEntProp(weapon, Prop_Send, "m_iClip1", 4);
					
					new newAmmo = ammo-(4-clip);
					
					if (newAmmo <= 0) 
					{
						newAmmo = 0;
					}
					
					SetEntProp(client, Prop_Send, "m_iAmmo", newAmmo, _, ammotype);
				}
			}
		}
	}
}