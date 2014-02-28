/**
 * -----------------------------------------------------
 * File        stamm_regenerate.sp
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
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1




new Handle:g_hHP;
new Handle:g_hTime;
new Handle:g_hClientTimers[MAXPLAYERS + 1];




// Plugin Info
public Plugin:myinfo =
{
	name = "Stamm Feature RegenerateHP",
	author = "Popoklopsi",
	version = "1.3.0",
	description = "Regenerate HP of VIP's",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// Add feature to stamm
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP HP Regenerate");
}





// Add to updater
public STAMM_OnFeatureLoaded(const String:basename[])
{
	decl String:urlString[256];


	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
	}
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetRegenerate", client, GetConVarInt(g_hHP) * block, GetConVarInt(g_hTime));
	
	PushArrayString(array, fmt);
}




// Create Config
public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);


	AutoExecConfig_SetFile("regenerate", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hHP = AutoExecConfig_CreateConVar("regenerate_hp", "2", "HP regeneration of a VIP, every x seconds per block");
	g_hTime = AutoExecConfig_CreateConVar("regenerate_time", "1", "Time interval to regenerate (in Seconds)");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}



public OnClientDisconnect(client)
{
	if (STAMM_IsClientValid(client))
	{
		if (g_hClientTimers[client] != INVALID_HANDLE) 
		{
			KillTimer(g_hClientTimers[client]);
			g_hClientTimers[client] = INVALID_HANDLE;
		}
	}
}


// a Player spawned
public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Does the client have this feature?
	if (STAMM_IsClientValid(client) && IsPlayerAlive(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			// Reset timer if available
			if (g_hClientTimers[client] != INVALID_HANDLE) 
			{
				KillTimer(g_hClientTimers[client]);
			}

			// Start timer to add health
			g_hClientTimers[client] = CreateTimer(float(GetConVarInt(g_hTime)), GiveHealth, GetClientUserId(client), TIMER_REPEAT);
		}
	}
}



public STAMM_OnClientBecomeVip(client, oldlevel, newlevel)
{
	if (IsPlayerAlive(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			// Reset timer if available
			if (g_hClientTimers[client] != INVALID_HANDLE) 
			{
				KillTimer(g_hClientTimers[client]);
			}

			// Start timer to add health
			g_hClientTimers[client] = CreateTimer(float(GetConVarInt(g_hTime)), GiveHealth, GetClientUserId(client), TIMER_REPEAT);
		}
	}
}



// Regenerate Timer
public Action:GiveHealth(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);


	// Is client valid?
	if (STAMM_IsClientValid(client))
	{
		// Get highest client block
		new clientBlock = STAMM_GetClientBlock(client);


		// Have client block and is player alive and in right team?
		if (clientBlock > 0 && IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3))
		{
			// Get max Health and add regenerate HP
			new maxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");

			new oldHP = GetClientHealth(client);
			new newHP = oldHP + GetConVarInt(g_hHP) * clientBlock;
			
			// Only if not higher than max Health
			if (newHP > maxHealth)
			{
				if (oldHP < maxHealth) 
				{
					newHP = maxHealth;
				}
				else 
				{
					return Plugin_Continue;
				}
			}
			
			SetEntityHealth(client, newHP);
			
			return Plugin_Continue;
		}
		
		g_hClientTimers[client] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}