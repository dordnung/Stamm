/**
 * -----------------------------------------------------
 * File        stamm_holy.sp
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
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1



new Handle:hear_all;
new hear;

new bool:useNew = false;


public Plugin:myinfo =
{
	name = "Stamm Feature Holy Granade",
	author = "Popoklopsi",
	version = "1.3.2",
	description = "Give VIP's a holy granade",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};



// Auto updater
public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
	}
}



// Add Feature
public OnAllPluginsLoaded()
{
	decl String:description[64];

	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}
	
	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
	{
		SetFailState("Can't Load Feature, not Supported for your game!");
	}
	

	STAMM_LoadTranslation();
		
	Format(description, sizeof(description), "%T", "GetHoly", LANG_SERVER);
	
	STAMM_AddFeature("VIP Holy Grenade", description);
}



// Create Config
public OnPluginStart()
{
	AutoExecConfig_SetFile("holy_grenade", "stamm/features");

	hear_all = AutoExecConfig_CreateConVar("holy_hear", "1", "0=Every one hear Granade, 1=Only Player who throw it");
	
	AutoExecConfig(true, "holy_grenade", "stamm/features");
	AutoExecConfig_CleanFile();
	
	HookEvent("weapon_fire", eventWeaponFire);
	HookEvent("hegrenade_detonate", eventHeDetonate);
}



// Load configs and download and precache files
public OnConfigsExecuted()
{
	hear = GetConVarInt(hear_all);

	// Check new Sound path
	if (FileExists("sound/stamm/throw.mp3"))
	{
		useNew = true;
	}
	

	// Download all files
	if (!useNew)
	{
		AddFileToDownloadsTable("sound/music/stamm/throw.mp3");
		AddFileToDownloadsTable("sound/music/stamm/explode.mp3");
	}
	else
	{
		AddFileToDownloadsTable("sound/stamm/throw.mp3");
		AddFileToDownloadsTable("sound/stamm/explode.mp3");
	}

	AddFileToDownloadsTable("materials/models/stamm/holy_grenade.vtf");
	AddFileToDownloadsTable("models/stamm/holy_grenade.mdl");
	AddFileToDownloadsTable("materials/models/stamm/holy_grenade.vmt");
	AddFileToDownloadsTable("models/stamm/holy_grenade.vvd");
	AddFileToDownloadsTable("models/stamm/holy_grenade.sw.vtx");
	AddFileToDownloadsTable("models/stamm/holy_grenade.phy");
	AddFileToDownloadsTable("models/stamm/holy_grenade.dx80.vtx");
	AddFileToDownloadsTable("models/stamm/holy_grenade.dx90.vtx");
	

	// Precache
	PrecacheModel("models/stamm/holy_grenade.mdl", true);
	PrecacheModel("materials/sprites/splodesprite.vmt", true);

	// Sound Stuff
	if (!useNew)
	{
		if (STAMM_GetGame() == GameCSGO)
		{
			AddToStringTable(FindStringTable("soundprecache"), "music/stamm/throw.mp3");
			AddToStringTable(FindStringTable("soundprecache"), "music/stamm/explode.mp3");
		}
		else
		{
			PrecacheSound("music/stamm/throw.mp3", true);
			PrecacheSound("music/stamm/explode.mp3", true);
		}
	}
	else
	{
		if (STAMM_GetGame() == GameCSGO)
		{
			AddToStringTable(FindStringTable("soundprecache"), "stamm/throw.mp3");
			AddToStringTable(FindStringTable("soundprecache"), "stamm/explode.mp3");
		}
		else
		{
			PrecacheSound("stamm/throw.mp3", true);
			PrecacheSound("stamm/explode.mp3", true);
		}
	}
}



// A weapon fired
public Action:eventWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	decl String:weapon[256];
	

	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if (STAMM_IsClientValid(client))
	{
		// Was it a grenade?
		if (StrEqual(weapon, "hegrenade")) 
		{
			// Client is VIP?
			if (STAMM_HaveClientFeature(client))
			{
				// Play a sound to client or to all?
				if (hear) 
				{
					if (!useNew)
					{
						EmitSoundToClient(client, "music/stamm/throw.mp3");
					}

					else 
					{
						EmitSoundToClient(client, "stamm/throw.mp3");
					}
				}
				else
				{
					if (STAMM_GetGame() != GameCSGO)
					{
						EmitSoundToAll("music/stamm/throw.mp3");
					}

					else
					{
						for (new i=0; i <= MaxClients; i++)
						{
							if (STAMM_IsClientValid(i))
							{
								ClientCommand(i, "play music/stamm/throw.mp3");
							}
						}
					}
				}
				
				// Change model of HE
				CreateTimer(0.25, change, client);
			}
		}
	}
}





// Grenade detonate
public Action:eventHeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new Float:origin[3];
	

	// Dest. location
	origin[0] = float(GetEventInt(event, "x"));
	origin[1] = float(GetEventInt(event, "y"));
	origin[2] = float(GetEventInt(event, "z"));
	

	// Client valid and is VIP?
	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			// Create a shake and a explosion
			new explode = CreateEntityByName("env_explosion");
			new shake = CreateEntityByName("env_shake");
			
			if (explode != -1 && shake != -1)
			{
				// Set up the explode and shake
				DispatchKeyValue(explode, "fireballsprite", "sprites/splodesprite.vmt");
				DispatchKeyValue(explode, "iMagnitude", "20");
				DispatchKeyValue(explode, "iRadiusOverride", "500");
				DispatchKeyValue(explode, "rendermode", "5");
				DispatchKeyValue(explode, "spawnflags", "2");
				
				DispatchKeyValue(shake, "amplitude", "4");
				DispatchKeyValue(shake, "duration", "5");
				DispatchKeyValue(shake, "frequency", "255");
				DispatchKeyValue(shake, "radius", "500");
				DispatchKeyValue(shake, "spawnflags", "0");
				
				// Spawn them
				DispatchSpawn(explode);
				DispatchSpawn(shake);
				
				// Teleport them
				TeleportEntity(explode, origin, NULL_VECTOR, NULL_VECTOR);
				TeleportEntity(shake, origin, NULL_VECTOR, NULL_VECTOR);
				
				// LETS GO!
				AcceptEntityInput(explode, "Explode");
				AcceptEntityInput(shake, "StartShake");
				
			}
			

			// Play sound
			if (hear) 
			{
				if (!useNew)
				{
					EmitSoundToClient(client, "music/stamm/explode.mp3");
				}

				else 
				{
					EmitSoundToClient(client, "stamm/explode.mp3");
				}
			}
			else
			{
				if (!useNew)
				{
					EmitSoundToAll("music/stamm/explode.mp3");
				}

				else
				{
					EmitSoundToAll("stamm/explode.mp3");
				}
			}
		}
	}
}





// Change the model
public Action:change(Handle:timer, any:client)
{
	new ent = -1;
	
	ent = FindEntityByClassname(ent, "hegrenade_projectile");
	
	// Found projectile?
	if (ent > -1)
	{
		new owner = GetEntPropEnt(ent, Prop_Send, "m_hThrower");
		
		// Everything is valid?
		if (IsValidEntity(ent) && owner == client) 
		{
			// Change the model
			SetEntityModel(ent, "models/stamm/holy_grenade.mdl");
		}
	}
}
