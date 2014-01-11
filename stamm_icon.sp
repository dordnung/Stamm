/**
 * -----------------------------------------------------
 * File        stamm_icon.sp
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

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>


#pragma semicolon 1


new g_iStammView[MAXPLAYERS + 1];




public Plugin:myinfo =
{
	name = "Stamm Feature Icon",
	author = "Popoklopsi",
	version = "1.3.0",
	description = "Adds an Stamm Icon on top of a player",
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


	STAMM_LoadTranslation();
	STAMM_AddFastFeature("VIP Icon", "%T", "GetIcon", LANG_SERVER);
}




// Reset icons
public OnPluginStart()
{
	HookEvent("player_spawn", eventPlayerSpawn);
	HookEvent("player_death", eventPlayerDeath);
	

	for (new i=0; i <= MaxClients; i++) 
	{
		g_iStammView[i] = 0;
	}
}




// Client changed feature state
public STAMM_OnClientChangedFeature(client, bool:mode, bool:isShop)
{
	if (STAMM_IsClientValid(client))
	{
		// Disabled it
		if (!mode)
		{
			if (g_iStammView[client] != 0) 
			{
				// Delete old ICON
				if (IsValidEntity(g_iStammView[client]))
				{
					decl String:class[128];
					
					GetEdictClassname(g_iStammView[client], class, sizeof(class));
					

					if (StrEqual(class, "prop_dynamic")) 
					{
						RemoveEdict(g_iStammView[client]);
					}
				}
				
				g_iStammView[client] = 0;
			}
		}
		else if (STAMM_HaveClientFeature(client))
		{
			// Create an icon
			CreateTimer(2.5, CreateStamm, GetClientUserId(client));
		}
	}
}





// Download Icon and preache it
public OnMapStart()
{
	PrecacheModel("models/stamm/stammview.mdl");
	
	AddFileToDownloadsTable("materials/models/stamm/stammview.vtf");
	AddFileToDownloadsTable("models/stamm/stammview.mdl");
	AddFileToDownloadsTable("materials/models/stamm/stammview.vmt");
	AddFileToDownloadsTable("models/stamm/stammview.vvd");
	AddFileToDownloadsTable("models/stamm/stammview.sw.vtx");
	AddFileToDownloadsTable("models/stamm/stammview.phy");
	AddFileToDownloadsTable("models/stamm/stammview.dx80.vtx");
	AddFileToDownloadsTable("models/stamm/stammview.dx90.vtx");
}




// Create icons for vips on spawn
public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	

	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && IsPlayerAlive(client)) 
			{
				// Create timer
				CreateTimer(2.5, CreateStamm, GetClientUserId(client));
			}
		}
	}
}




// Delete icon on death
public Action:eventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Client have an icon
	if (g_iStammView[client] != 0) 
	{
		if (IsValidEntity(g_iStammView[client]))
		{
			decl String:class[128];
			
			GetEdictClassname(g_iStammView[client], class, sizeof(class));
			
			// Delete
			if (StrEqual(class, "prop_dynamic")) 
			{
				RemoveEdict(g_iStammView[client]);
			}
		}
		
		g_iStammView[client] = 0;
	}
}




// Create the icon
public Action:CreateStamm(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);


	if (STAMM_IsClientValid(client))
	{
		// Valid team
		if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && IsPlayerAlive(client))
		{
			// First delete old one
			if (g_iStammView[client] != 0) 
			{
				if (IsValidEntity(g_iStammView[client]))
				{
					decl String:class[128];
					
					
					GetEdictClassname(g_iStammView[client], class, sizeof(class));
					
					if (StrEqual(class, "prop_dynamic")) 
					{
						RemoveEdict(g_iStammView[client]);
					}
				}
			}
			
			
			// Create the new one
			new view = CreateEntityByName("prop_dynamic");
			
			if (view != -1)
			{
				// Set up the entity
				DispatchKeyValue(view, "DefaultAnim", "rotate");
				DispatchKeyValue(view, "spawnflags", "256");
				DispatchKeyValue(view, "model", "models/stamm/stammview.mdl");
				DispatchKeyValue(view, "solid", "6");
				
				// Spawn it
				if (DispatchSpawn(view))
				{
					decl Float:origin[3];
					decl String:steamid[20];
					
					// Valid?
					if (IsValidEntity(view))
					{
						// Mark players entity and spawn it to him
						g_iStammView[client] = view;
						
						GetClientAbsOrigin(client, origin);
						
						origin[2] = origin[2] + 90.0;
						
						TeleportEntity(view, origin, NULL_VECTOR, NULL_VECTOR);
						
						GetClientAuthString(client, steamid, sizeof(steamid));
						DispatchKeyValue(client, "targetname", steamid);
						
						SetVariantString(steamid);
						AcceptEntityInput(view, "SetParent", -1, -1, 0);
					}
				}
			}
		}
	}
}