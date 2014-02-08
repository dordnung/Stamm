/**
 * -----------------------------------------------------
 * File        stamm_playertrail.sp
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




new String:material[PLATFORM_MAX_PATH + 1];

new Float:lifetime;

new Handle:beamTimer[MAXPLAYERS+1];
new haveBeam[MAXPLAYERS+1];
new modelInd;

new Handle:g_hLifeTime;
new Handle:g_hMaterial;




public Plugin:myinfo =
{
	name = "Stamm Feature PlayerTrail",
	author = "Popoklopsi",
	version = "1.3.0",
	description = "Give VIP's a player trail",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// Add auto update
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
	STAMM_RegisterFeature("VIP PlayerTrail");
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetPlayerTrail", client);
	
	PushArrayString(array, fmt);
}




// Create config
public OnPluginStart()
{
	HookEvent("player_spawn", eventPlayerSpawn);
	HookEvent("player_death", eventPlayerDeath);


	AutoExecConfig_SetFile("playertrail", "stamm/features");
	AutoExecConfig_SetCreateFile(true);
	
	g_hLifeTime = AutoExecConfig_CreateConVar("ptrail_lifetime", "4.0", "Lifetime of each trail element in seconds");
	g_hMaterial = AutoExecConfig_CreateConVar("ptrail_material", "sprites/laserbeam.vmt", "Material to use, start after materials/");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}




// Load config
public OnConfigsExecuted()
{
	decl String:materialPrecache[PLATFORM_MAX_PATH + 1];


	lifetime = GetConVarFloat(g_hLifeTime);

	GetConVarString(g_hMaterial, materialPrecache, sizeof(materialPrecache));

	Format(material, sizeof(material), "materials/%s", materialPrecache);

	modelInd = PrecacheModel(material);



	// Load material
	if (FileExists(material))
	{
		AddFileToDownloadsTable(material);

		strcopy(materialPrecache, sizeof(materialPrecache), material);

		ReplaceString(materialPrecache, sizeof(materialPrecache), ".vmt", ".vtf", false);
		AddFileToDownloadsTable(materialPrecache);
	}
}



// Delete old trails
public OnMapStart()
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		DeleteTrail(i);
	}
}




// Add Trails for VIP's
public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (STAMM_IsClientValid(client))
	{
		// First delete old ones
		DeleteTrail(client);

		if (STAMM_HaveClientFeature(client))
		{
			// Create new one
			if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3)) 
			{
				CreateTimer(2.5, SetupTrail, client);
			}
		}
	}
}




// On disconnect delete trails
public OnClientDisconnect(client)
{	
	DeleteTrail(client);
}




// Also on player death
public Action:eventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	DeleteTrail(client);
}



// Setup trail
public Action:SetupTrail(Handle:timer, any:client)
{
	if (STAMM_IsClientValid(client))
	{
		// Valid team
		if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && IsPlayerAlive(client))
		{
			// Delete before
			DeleteTrail(client);

			// Set new one
			if (STAMM_GetGame() == GameCSGO)
			{
				beamTimer[client] = CreateTimer(0.1, CreateTrail, client, TIMER_REPEAT);
			}
			else
			{
				CreateTrail2(client);
			}
		}
	}
}




// Client doesnt want it anymore
public STAMM_OnClientChangedFeature(client, bool:mode, bool:isShop)
{
	if (!mode) 
	{
		DeleteTrail(client);
	}
}



// Create it for CSGO
public Action:CreateTrail(Handle:timer, any:client)
{
	if (STAMM_IsClientValid(client))
	{
		decl Float:velocity[3];
		new color[4];


		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);		


		// Move?
		if (!(velocity[0] == 0.0 && velocity[1] == 0.0 && velocity[2] == 0.0))
		{
			return Plugin_Continue;
		}


		// Create on weapon high
		new ent = GetPlayerWeaponSlot(client, 2);

		if (ent == -1)
		{
			ent = client;
		}

		// Set to team color
		if (GetClientTeam(client) == 2) 
		{
			color[0] = 255;
		}
		else
		{
			color[2] = 255;
		}


		color[3] = 255;

		// Setup
		TE_SetupBeamFollow(ent, modelInd, 0, lifetime, 3.0, 3.0, 1, color);
		TE_SendToAll();
	}
	else 
	{
		// Client not valid so delete old
		DeleteTrail(client);

		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}




// Create for others than csgo
public CreateTrail2(client)
{
	if (STAMM_IsClientValid(client) && haveBeam[client] == -1)
	{
		// Create spritetrail
		new ent = CreateEntityByName("env_spritetrail");

		// Valid entity
		if (ent != -1 && IsValidEntity(ent))
		{
			new Float:Orig[3];
			decl String:name[MAX_NAME_LENGTH + 1];

			// For parent
			GetClientName(client, name, sizeof(name));

			// Setup the trail
			DispatchKeyValue(client, "targetname", name);
			DispatchKeyValue(ent, "parentname", name);
			DispatchKeyValueFloat(ent, "lifetime", lifetime);
			DispatchKeyValueFloat(ent, "endwidth", 3.0);
			DispatchKeyValueFloat(ent, "startwidth", 3.0);
			DispatchKeyValue(ent, "spritename", material);
			DispatchKeyValue(ent, "renderamt", "255");
			


			if (GetClientTeam(client) == 2) 
			{
				DispatchKeyValue(ent, "rendercolor", "255 0 0 255");
			}	

			if (GetClientTeam(client) == 3) 
			{
				DispatchKeyValue(ent, "rendercolor", "0 0 255 255");
			}


			DispatchKeyValue(ent, "rendermode", "5");
			
			// Spawn it
			DispatchSpawn(ent);


			// Teleport it to the player
			GetClientAbsOrigin(client, Orig);
			
			Orig[2] += 40.0;
			
			TeleportEntity(ent, Orig, NULL_VECTOR, NULL_VECTOR);
			
			// Set player as parent
			SetVariantString(name);
			AcceptEntityInput(ent, "SetParent"); 
			SetEntPropFloat(ent, Prop_Send, "m_flTextureRes", 0.05);

			haveBeam[client] = ent;
		}
	}
}




// Delete the trail
public DeleteTrail(client)
{
	if (beamTimer[client] != INVALID_HANDLE)
	{
		// Stop the timer
		CloseHandle(beamTimer[client]);
	}


	beamTimer[client] = INVALID_HANDLE;



	// Get trail of player
	new ent = haveBeam[client];


	// Player has a trail
	if (ent != -1 && IsValidEntity(ent))
	{
		decl String:class[128];
		
		// Valid trail?
		GetEdictClassname(ent, class, sizeof(class));
		
		if (StrEqual(class, "env_spritetrail")) 
		{
			// Remove
			RemoveEdict(ent);
		}
	}

	haveBeam[client] = -1;
}