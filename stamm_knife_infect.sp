/**
 * -----------------------------------------------------
 * File        stamm_knife_infect.sp
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
#include <colors>
#include <morecolors_stamm>
#include <sdktools>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1




new dur;
new mode_infect;
new lhp;
new timers[MAXPLAYERS+1];

new Handle:dur_c;
new Handle:mode_c;
new Handle:lhp_c;

new bool:Infected[MAXPLAYERS+1];




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
	// Colors :)
	if (!CColorAllowed(Color_Lightgreen))
	{
		if (CColorAllowed(Color_Lime))
		{
			CReplaceColor(Color_Lightgreen, Color_Lime);
		}
		else if (CColorAllowed(Color_Olive))
		{
			CReplaceColor(Color_Lightgreen, Color_Olive);
		}
	}


	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
	{
		SetFailState("Can't Load Feature, not Supported for your game!");
	}


	STAMM_LoadTranslation();
	STAMM_AddFastFeature("VIP KnifeInfect", "%T", "GetKnifeInfect", LANG_SERVER);
}




// Create config and hook events
public OnPluginStart()
{
	HookEvent("player_death", PlayerDeath);
	HookEvent("player_hurt", PlayerHurt);
	HookEvent("player_spawn", PlayerDeath);

	AutoExecConfig_SetFile("knife_infect", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	dur_c = AutoExecConfig_CreateConVar("infect_duration", "0", "Infect Duration, 0 = Next Spawn, x = Time in Seconds");
	mode_c = AutoExecConfig_CreateConVar("infect_mode", "2", "Infect Mode, 0 = Enemy lose HP every second, 1 = Enemy have an infected overlay, 2 = Both");
	lhp_c = AutoExecConfig_CreateConVar("infect_hp", "2", "If mode is 0 or 2: HP lose every Second");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}




// Load Config
public OnConfigsExecuted()
{
	dur = GetConVarInt(dur_c);
	mode_infect = GetConVarInt(mode_c);
	lhp = GetConVarInt(lhp_c);
	

	if (mode_infect != 1 || dur) 
	{
		CreateTimer(1.0, SecondTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}



// Timer to check for infected Players
public Action:SecondTimer(Handle:timer, any:data)
{
	for (new i=1; i <= MaxClients; i++)
	{
		if (STAMM_IsClientValid(i))
		{
			// Client is infected
			if (Infected[i])
			{
				// Only for a specific duration
				if (dur)
				{
					timers[i]--;
					
					// Time is over
					if (timers[i] <= 0)
					{
						Infected[i] = false;
						
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
	
	if (STAMM_IsClientValid(client) && Infected[client])
	{
		Infected[client] = false;

		if (mode_infect) 
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
	


	GetEventString(event, "weapon", weapon, sizeof(weapon));
	STAMM_GetTag(tag, sizeof(tag));


	// Clients are valid
	if (STAMM_IsClientValid(client) && STAMM_IsClientValid(attacker))
	{
		// Weapon was knife
		if (StrEqual(weapon, "knife") && !Infected[client])
		{
			// Attack was from a VIP
			if (STAMM_HaveClientFeature(attacker))
			{
				Infected[client] = true;
				
				GetClientName(attacker, p_name, sizeof(p_name));
				
				// Infecte the player
				if (mode_infect)
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
					timers[client] = dur;

					if (STAMM_GetGame() == GameCSGO)
					{
						CPrintToChat(client, "%s %t", tag, "YouGotTimeInfected", p_name, dur);
					}
					else
					{
						MCPrintToChat(client, "%s %t", tag, "YouGotTimeInfected", p_name, dur);
					}
				}
				else 
				{
					if (STAMM_GetGame() == GameCSGO)
					{
						CPrintToChat(client, "%s %t", tag, "YouGotRoundInfected", p_name);
					}
					else
					{
						MCPrintToChat(client, "%s %t", tag, "YouGotRoundInfected", p_name);
					}
				}
			}
		}
	}
}