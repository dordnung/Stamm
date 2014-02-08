/**
 * -----------------------------------------------------
 * File        stamm_grenadetrail.sp
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


// Colors for the diffent grenades
#define HEColor {225,0,0,225}
#define FlashColor {255,255,0,225}
#define SmokeColor {0,225,0,225}
#define DecoyColor {139,090,043,225}
#define MoloColor {255,069,0,225}

#pragma semicolon 1


new g_iBeamSprite;




public Plugin:myinfo =
{
	name = "Stamm Feature GrenadeTrail",
	author = "Popoklopsi",
	version = "1.4.0",
	description = "Give VIP's a grenade trail",
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
	
	if (STAMM_GetGame() == GameDOD || STAMM_GetGame() == GameTF2) 
	{
		SetFailState("Can't Load Feature, not Supported for your game!");
	}
		

	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP Grenade Trail");
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetGrenadeTrail", client);
	
	PushArrayString(array, fmt);
}



// Hook weapon fire
public OnPluginStart()
{
	HookEvent("weapon_fire", eventWeaponFire);
}



// Precache trail
public OnMapStart()
{
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}



// a weapon fired
public Action:eventWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:weapon[64];
	
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			// Check for a nade
			if (StrEqual(weapon, "hegrenade"))
			{
				CreateTimer(0.15, SetupHE, client);
			}

			else if (StrEqual(weapon, "flashbang"))
			{
				CreateTimer(0.15, SetupFlash, client);
			}

			else if (StrEqual(weapon, "smokegrenade"))
			{
				CreateTimer(0.15, SetupSmoke, client);
			}
				
			else if (StrEqual(weapon, "decoy"))
			{
				CreateTimer(0.15, SetupDecoy, client);
			}
				
			else if (StrEqual(weapon, "molotov"))
			{
				CreateTimer(0.15, SetupMolo, client);
			}
		}
	}
}



// Setups for different nades, because of differnet
public Action:SetupHE(Handle:timer, any:client)
{
	new ent = FindEntityByClassname(-1, "hegrenade_projectile");
	
	AddTrail(client, ent, HEColor);
}



public Action:SetupFlash(Handle:timer, any:client)
{
	new ent = FindEntityByClassname(-1, "flashbang_projectile");
	
	AddTrail(client, ent, FlashColor);
}


public Action:SetupSmoke(Handle:timer, any:client)
{
	new ent = FindEntityByClassname(-1, "smokegrenade_projectile");
	
	AddTrail(client, ent, SmokeColor);
}


public Action:SetupDecoy(Handle:timer, any:client)
{
	new ent = FindEntityByClassname(-1, "decoy_projectile");
	
	AddTrail(client, ent, DecoyColor);
}


public Action:SetupMolo(Handle:timer, any:client)
{
	new ent = FindEntityByClassname(-1, "molotov_projectile");
	
	AddTrail(client, ent, MoloColor);
}


// Add trail with color
public AddTrail(client, ent, tcolor[4])
{
	if (ent != -1)
	{
		new owner = GetEntPropEnt(ent, Prop_Send, "m_hThrower");
		
		// Could we find the projectile?
		if (IsValidEntity(ent) && owner == client)
		{
			// Create trail
			TE_SetupBeamFollow(ent, g_iBeamSprite,	0, 5.0, 3.0, 3.0, 1, tcolor);
			TE_SendToAll();
		}
	}
}