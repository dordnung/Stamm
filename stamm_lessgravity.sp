/**
 * -----------------------------------------------------
 * File        stamm_lessgravity.sp
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



new Handle:g_hGrav;




// Details
public Plugin:myinfo =
{
	name = "Stamm Feature LessGravity",
	author = "Popoklopsi",
	version = "1.3.0",
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
	STAMM_AddFeature("VIP Less Gravity");
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
	new grav = GetConVarInt(g_hGrav);


	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
	}


	// Add dsecription for each feature
	for (new i=1; i <= STAMM_GetBlockCount(); i++)
	{
		STAMM_AddBlockDescription(i, "%T", "GetLessGravity", LANG_SERVER, grav * i);
	}
}




// A Player spawned, change his gravity
public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
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