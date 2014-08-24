/**
 * -----------------------------------------------------
 * File        stamm_lessgravity.sp
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



new Handle:g_hGrav;




// Details
public Plugin:myinfo =
{
	name = "Stamm Feature LessGravity",
	author = "Popoklopsi",
	version = "1.3.1",
	description = "Give VIP's less gravity",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// Add the Feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP Less Gravity");
}




// Create the config
public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);


	AutoExecConfig_SetFile("lessgravity", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hGrav = AutoExecConfig_CreateConVar("gravity_decrease", "5", "Gravity decrease in percent each block!");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}




// Add to auto update and set description
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
	
	Format(fmt, sizeof(fmt), "%T", "GetLessGravity", client, GetConVarInt(g_hGrav) * block);
	
	PushArrayString(array, fmt);
}




// A Player spawned, change his gravity
public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Players spawn without Gravity (not always)
	CreateTimer(0.1, Timer_ChangeGravity, client);
}


public Action:Timer_ChangeGravity(Handle:timer, any:client)
{
	STAMM_OnClientChangedFeature(client, true, false);
}


public STAMM_OnClientBecomeVip(client, oldlevel, newlevel)
{
	STAMM_OnClientChangedFeature(client, true, false);
}



// Also change it, if he changed the state
public STAMM_OnClientChangedFeature(client, bool:mode, bool:isShop)
{
	if (STAMM_IsClientValid(client) && IsPlayerAlive(client))
	{
		new Float:newGrav;
		new clientBlock;

		// Client want it
		if (mode)
		{
			// Get highest client block
			clientBlock = STAMM_GetClientBlock(client);

			// Have the client the block?
			if (clientBlock > 0)
			{
				// Calculate new gravity
				newGrav = 1.0 - float(GetConVarInt(g_hGrav)) / 100.0 * clientBlock;

				if (newGrav < 0.1) 
				{
					newGrav = 0.1;
				}

				SetEntityGravity(client, newGrav);
			}
		}
		else
		{
			// Else reset gravity
			SetEntityGravity(client, 1.0);
		}
	}
}



// When client is on a ladder gravity will go back to normal
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if (STAMM_IsClientValid(client))
	{
		static MoveType:lastMove[MAXPLAYERS + 1] = MOVETYPE_NONE;
		new MoveType:current = GetEntityMoveType(client);

		if (current != MOVETYPE_LADDER && lastMove[client] == MOVETYPE_LADDER)
		{
			STAMM_OnClientChangedFeature(client, true, false);
		}

		lastMove[client] = current;
	}
}
