/**
 * -----------------------------------------------------
 * File        stamm_knife_infect.sp
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




new Handle:g_hDur;
new Handle:g_hMode;
new Handle:g_hlHP;

new g_iTimers[MAXPLAYERS+1];
new bool:g_bInfected[MAXPLAYERS+1];




public Plugin:myinfo =
{
	name = "Stamm Feature KnifeInfect",
	author = "Popoklopsi",
	version = "1.3.0",
	description = "VIP's can infect players with knife",
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

	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
	{
		SetFailState("Can't Load Feature, not Supported for your game!");
	}


	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP KnifeInfect");
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetKnifeInfect", client);
	
	PushArrayString(array, fmt);
}




// Create config and hook events
public OnPluginStart()
{
	HookEvent("player_death", PlayerDeath);
	HookEvent("player_hurt", PlayerHurt);
	HookEvent("player_spawn", PlayerDeath);


	AutoExecConfig_SetFile("knife_infect", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hDur = AutoExecConfig_CreateConVar("infect_duration", "0", "Infect Duration, 0 = Next Spawn, x = Time in Seconds");
	g_hMode = AutoExecConfig_CreateConVar("infect_mode", "2", "Infect Mode, 0 = Enemy lose HP every second, 1 = Enemy have an infected overlay, 2 = Both");
	g_hlHP = AutoExecConfig_CreateConVar("infect_hp", "2", "If mode is 0 or 2: HP lose every Second");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}





public OnMapStart()
{
	if (GetConVarInt(g_hMode) != 1 || GetConVarInt(g_hDur)) 
	{
		CreateTimer(1.0, SecondTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}




// Timer to check for infected Players
public Action:SecondTimer(Handle:timer, any:data)
{
	new mode_infect = GetConVarInt(g_hMode);
	new dur = GetConVarInt(g_hDur);
	new lhp = GetConVarInt(g_hlHP);


	for (new i=1; i <= MaxClients; i++)
	{
		if (STAMM_IsClientValid(i))
		{
			// Client is infected
			if (g_bInfected[i])
			{
				// Only for a specific duration
				if (dur)
				{
					g_iTimers[i]--;
					
					// Time is over
					if (g_iTimers[i] <= 0)
					{
						g_bInfected[i] = false;
						
						if (mode_infect) 
						{
							ClientCommand(i, "r_screenoverlay \"\"");
						}

						continue;
					}
				}
				

				// Player lose health on infect
				if (mode_infect != 1)
				{
					new newhp = GetClientHealth(i) - lhp;
					
					if (newhp <= 0)
					{
						newhp = 0;
						
						ForcePlayerSuicide(i);
					}
					

					SetEntityHealth(i, newhp);
				}
			}
		}
	}
	
	return Plugin_Continue;
}




// Player died, reset infect
public PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	

	if (STAMM_IsClientValid(client) && g_bInfected[client])
	{
		g_bInfected[client] = false;

		if (GetConVarInt(g_hMode)) 
		{
			ClientCommand(client, "r_screenoverlay \"\"");
		}
	}
}




// A Player gets hurted
public PlayerHurt(Handle:event, String:name[], bool:dontBroadcast)
{
	decl String:weapon[64];
	decl String:p_name[128];
	decl String:tag[64];


	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new dur = GetConVarInt(g_hDur);


	GetEventString(event, "weapon", weapon, sizeof(weapon));
	STAMM_GetTag(tag, sizeof(tag));


	// Clients are valid
	if (STAMM_IsClientValid(client) && STAMM_IsClientValid(attacker))
	{
		// Weapon was knife
		if (StrEqual(weapon, "knife") && !g_bInfected[client])
		{
			// Attack was from a VIP
			if (STAMM_HaveClientFeature(attacker))
			{
				g_bInfected[client] = true;
				
				GetClientName(attacker, p_name, sizeof(p_name));
				
				// Infecte the player
				if (GetConVarInt(g_hMode))
				{
					// With a Overlay
					if (STAMM_GetGame() == GameCSS) 
					{
						ClientCommand(client, "r_screenoverlay effects/tp_eyefx/tp_eyefx");
					}
					else
					{
						ClientCommand(client, "r_drawscreenoverlay 1");
						ClientCommand(client, "r_screenoverlay effects/nightvision");
					}
				}
				
				// For specific time
				if (dur)
				{
					g_iTimers[client] = dur;

					STAMM_PrintToChat(client, "%s %t", tag, "YouGotTimeInfected", p_name, dur);
				}
				else 
				{
					STAMM_PrintToChat(client, "%s %t", tag, "YouGotRoundInfected", p_name);
				}
			}
		}
	}
}