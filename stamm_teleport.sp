/**
 * -----------------------------------------------------
 * File        stamm_teleport.sp
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
#include <colors>
#include <morecolors_stamm>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1




// The teleport list of clients
new Float:TeleportList[MAXPLAYERS + 1][3][3];

// The teleports
new Teleports[MAXPLAYERS + 1][3];

// timer to teleport
new timer[MAXPLAYERS + 1];




public Plugin:myinfo =
{
	name = "Stamm Feature Teleport",
	author = "Popoklopsi",
	version = "1.2.0",
	description = "VIP's can create Teleport Points",
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
	}
}




// Add the feature to stamm
public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}


	STAMM_LoadTranslation();
	STAMM_AddFastFeature("VIP Teleport", "%T", "GetTeleport", LANG_SERVER);
}




// Plugin started
public OnPluginStart()
{
	// Replace lightgreen if not exists
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


	// Register console cmds
	RegConsoleCmd("sm_sadd", AddTele, "Adds a new Teleporter");
	RegConsoleCmd("sm_stele", Tele, "Teleports an Player");
	
	HookEvent("player_spawn", eventPlayerSpawn);
	HookEvent("player_death", eventPlayerSpawn);
}



// Precache model
public OnMapStart()
{
	PrecacheModel("materials/sprites/strider_blackball.vmt", true); 
	
	// Reset stuff
	for (new i=0; i <= MaxClients; i++)
	{
		Teleports[i][0] = 0;
		timer[i] = 0;
	}
}




// Add a new Teleport to the list
public Action:AddTele(client, args)
{
	decl String:tag[64];


	if (STAMM_IsClientValid(client))
	{
		// Only if client is valid
		if (STAMM_HaveClientFeature(client) && IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3))
		{
			// Get clients location
			GetClientAbsAngles(client, TeleportList[client][1]);
			GetClientAbsOrigin(client, TeleportList[client][0]);


			// Get Stamm tag
			STAMM_GetTag(tag, sizeof(tag));

			
			// Add
			Teleports[client][0] = 1;
			
			// Notice that added
			if (STAMM_GetGame() == GameCSGO)
			{
				CPrintToChat(client, "%s %t", "TeleportAdded");
			}
			else
			{
				MCPrintToChat(client, "%s %t", "TeleportAdded");
			}
		}
	}
	
	return Plugin_Handled;
}




// Teleports the client
public Action:Tele(client, args)
{
	if (STAMM_IsClientValid(client))
	{
		// Only if client is valid and have a valid teleport points
		if (STAMM_HaveClientFeature(client) && Teleports[client][0] && !timer[client] && IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3))
		{
			// Create the teleporter
			Teleports[client][2] = 1;
			Teleports[client][1] = createEnt(client);
		}
	}
	
	return Plugin_Handled;
}




// The client can't leave the Teleporter hehe
public OnGameFrame()
{
	for (new i=1; i <= MaxClients; i++)
	{
		// Check for running teleports
		if (timer[i] > 0)
		{
			if (STAMM_IsClientValid(i))
			{
				timer[i]--;
				

				// Now we can teleport
				if (timer[i] <= 0)
				{
					if (IsValidEntity(Teleports[i][1])) 
					{
						// Remove teleporter
						RemoveEdict(Teleports[i][1]);
					}

					// Teleport the client if teleport valid
					if (Teleports[i][2] == 1) 
					{
						TeleportEntity(i, TeleportList[i][0], TeleportList[i][1], NULL_VECTOR);
						
						Teleports[i][2] = 2;

						// Create end teleport
						Teleports[i][1] = createEnt(i);
					}
				}
				else 
				{
					// Back to teleporter
					TeleportEntity(i, TeleportList[i][2], NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
	}
}




// Create the teleporter
public createEnt(client)
{
	// It's a env_smokestack
	new ent = CreateEntityByName("env_smokestack");
	
	GetClientAbsOrigin(client, TeleportList[client][2]);
	

	
	// Could we create it?
	if (ent != -1)
	{
		// This is a nice design :)
		DispatchKeyValue(ent, "WindSpeed", "0");
		DispatchKeyValue(ent, "WindAngle", "0");
		DispatchKeyValue(ent, "BaseSpread", "40");
		DispatchKeyValue(ent, "EndSize", "15");
		DispatchKeyValue(ent, "twist", "0");
		DispatchKeyValue(ent, "JetLength", "110");
		DispatchKeyValue(ent, "roll", "0");
		DispatchKeyValue(ent, "StartSize", "15");
		DispatchKeyValue(ent, "Rate", "250");
		DispatchKeyValue(ent, "SpreadSpeed", "15");
		DispatchKeyValue(ent, "renderamt", "255");
		DispatchKeyValue(ent, "Speed", "150");
		
		// Set color to team color
		if (GetClientTeam(client) == 2) 
		{
			DispatchKeyValue(ent, "rendercolor", "255 0 0");
		}
		else 
		{
			DispatchKeyValue(ent, "rendercolor", "0 0 255");
		}

		// And more values
		DispatchKeyValue(ent, "InitialState", "1");
		DispatchKeyValue(ent, "angles", "0 0 0");
		DispatchKeyValue(ent, "SmokeMaterial", "sprites/strider_blackball.vmt");

		// Spawn the teleporter
		DispatchSpawn(ent);

		// And teleport it
		TeleportEntity(ent, TeleportList[client][2], NULL_VECTOR, NULL_VECTOR);
		
		timer[client] = 180;
	}
	
	return ent;
}




// Reset the client on Spawn
public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	timer[client] = 0;
}