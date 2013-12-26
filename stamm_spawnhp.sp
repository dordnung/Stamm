/**
 * -----------------------------------------------------
 * File        stamm_spawnhp.sp
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
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1




new hp;
new Handle:c_hp;




// Plugin Info
public Plugin:myinfo =
{
	name = "Stamm Feature SpawnHP",
	author = "Popoklopsi",
	version = "1.4.0",
	description = "Give VIP's more HP on spawn",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// Add Feature
public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	STAMM_LoadTranslation();
	STAMM_AddFeature("VIP SpawnHP");
}



// Add to udater and add descriptions
public STAMM_OnFeatureLoaded(const String:basename[])
{
	decl String:urlString[256];


	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
	}


	// Add for each block a description
	for (new i=1; i <= STAMM_GetBlockCount(); i++)
	{
		STAMM_AddBlockDescription(i, "%T", "GetSpawnHP", LANG_SERVER, hp * i);
	}
}




// Create the config
public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);


	AutoExecConfig_SetFile("spawnhp", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	c_hp = AutoExecConfig_CreateConVar("spawnhp_hp", "50", "HP a VIP gets every spawn more per block");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}




// Load Config
public OnConfigsExecuted()
{
	hp = GetConVarInt(c_hp);
}



// Change player health
public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (STAMM_IsClientValid(client))
	{
		// Timer to add points
		if (IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)) 
		{
			CreateTimer(0.5, changeHealth, client);
		}
	}
}




// Change here the health
public Action:changeHealth(Handle:timer, any:client)
{
	// Get highest client block
	new clientBlock = STAMM_GetClientBlock(client);


	// Have client block
	if (clientBlock > 0)
	{
		// Set new HP
		new newHP = GetClientHealth(client) + hp * clientBlock;
		
		// also increate max HP
		SetEntProp(client, Prop_Data, "m_iMaxHealth", newHP);
		SetEntityHealth(client, newHP);
	}
}