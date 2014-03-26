/**
 * -----------------------------------------------------
 * File        stamm_moreammo.sp
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
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1





new Handle:g_hAmmo;
new Handle:g_hTheTimer;

new bool:g_bWeaponEdit[MAXPLAYERS + 1][2024];




public Plugin:myinfo =
{
	name = "Stamm Feature MoreAmmo",
	author = "Popoklopsi",
	version = "1.3.1",
	description = "Give VIP's more ammo",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// Add feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	if (STAMM_GetGame() == GameTF2)
	{
		HookEvent("teamplay_round_start", RoundStart);
		HookEvent("arena_round_start", RoundStart);
	}
	

	if (STAMM_GetGame() == GameDOD)
	{
		HookEvent("dod_round_start", RoundStart);
	}

	else
	{
		HookEvent("round_start", RoundStart);
	}

	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP MoreAmmo");
}





// Create config and hook round start
public OnPluginStart()
{
	HookEvent("player_death", PlayerDeath);


	// Config
	AutoExecConfig_SetFile("moreammo", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hAmmo = AutoExecConfig_CreateConVar("ammo_amount", "20", "Ammo increase in percent each block!");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}





// Feature loaded, add desc. and auto updater
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




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetMoreAmmo", client, GetConVarInt(g_hAmmo) * block);
	
	PushArrayString(array, fmt);
}




// Reset on mapstart
public OnMapStart()
{
	if (g_hTheTimer != INVALID_HANDLE) 
	{
		KillTimer(g_hTheTimer);
	}

	// Create check timer
	g_hTheTimer = CreateTimer(1.0, CheckWeapons, _, TIMER_REPEAT);
}




// Reset on death
public PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	for (new x=0; x < 2024; x++) 
	{
		g_bWeaponEdit[client][x] = false;
	}
}




public RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	// Reset on round start
	for (new x=0; x < 2024; x++)
	{
		for (new i=0; i <= MaxClients; i++) 
		{
			g_bWeaponEdit[i][x] = false;
		}
	}
}




// Check weapons
public Action:CheckWeapons(Handle:timer, any:data)
{
	new ammo = GetConVarInt(g_hAmmo);

	// Client loop
	for (new i = 1; i <= MaxClients; i++)
	{
		new client = i;
		
		// Client valid?
		if (STAMM_IsClientValid(client) && IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3))
		{
			// Get highest client block
			new clientBlock = STAMM_GetClientBlock(client);


			// Client have block?
			if (clientBlock > 0)
			{
				// Weapon loop
				for (new x=0; x < 2; x++)
				{
					// Player carry weapon?
					new weapon = GetPlayerWeaponSlot(client, x);

					if (weapon != -1 && !g_bWeaponEdit[client][weapon])
					{
						// Get ammo index
						new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");

						// Found ammo?
						if (ammotype != -1)
						{
							// Get ammo count
							new cAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
							
							// Found ammo count
							if (cAmmo > 0)
							{
								// Calculate new Ammo
								new newAmmo;
								
								newAmmo = RoundToZero(cAmmo + ((float(cAmmo)/100.0) * (clientBlock * ammo)));
								
								// Set ammo
								SetEntProp(client, Prop_Send, "m_iAmmo", newAmmo, _, ammotype);
								
								g_bWeaponEdit[client][weapon] = true;
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}