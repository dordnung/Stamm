/**
 * -----------------------------------------------------
 * File        stamm_resizeplayer.sp
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


// Include 
#include <sourcemod>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1




new resize;
new Handle:c_resize;

new Float:clientSize[MAXPLAYERS + 1];



// Plugin ifno
public Plugin:myinfo =
{
	name = "Stamm Feature ResizePlayer",
	author = "Popoklopsi",
	version = "1.1.0",
	description = "Resizes VIP's",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// All Plugins loaded
public OnAllPluginsLoaded()
{
	// Stamm not found
	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	// Not for game CSGO
	if (STAMM_GetGame() == GameCSGO) 
	{
		SetFailState("Can't Load Feature. not Supported for your game!");
	}


	// Load translation and add feaure
	STAMM_LoadTranslation();
	STAMM_AddFeature("VIP Resize Player");
}



// Feature started
public OnPluginStart()
{
	// Hook event player spawn
	HookEvent("player_spawn", PlayerSpawn);

	// Create Config
	AutoExecConfig_SetFile("resizeplayer", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	c_resize = AutoExecConfig_CreateConVar("resize_amount", "10", "Resize amount in(+)/de(-)crease in percent each block!");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}




// Get Config cvar
public OnConfigsExecuted()
{
	resize = GetConVarInt(c_resize);
}



// Feature loaded
public STAMM_OnFeatureLoaded(const String:basename[])
{
	decl String:urlString[256];


	// Add to updater
	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
	}


	// Write level descriptions
	for (new i=1; i <= STAMM_GetBlockCount(); i++)
	{
		STAMM_AddBlockDescription(i, "%T", "GetResize", LANG_SERVER, resize * i);
	}
}




// Client is ready
public STAMM_OnClientReady(client)
{
	// Default size is 1.0
	clientSize[client] = 1.0;

	// For each block
	for (new i=STAMM_GetBlockCount(); i > 0; i--)
	{
		// Client has feature
		if (STAMM_HaveClientFeature(client, i))
		{
			// set new size
			clientSize[client] = 1.0 + float(resize)/100.0 * i;

			if (clientSize[client] < 0.1) 
			{
				clientSize[client] = 0.1;
			}

			// Break here
			break;
		}
	}
}



// Resize player on Spawn
public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	STAMM_OnClientChangedFeature(client, true, false);
}



// Client changed a feature
public STAMM_OnClientChangedFeature(client, bool:mode, bool:isShop)
{
	if (STAMM_IsClientValid(client))
	{
		// Resize is defined in metod OnClientReady
		STAMM_OnClientReady(client);


		// Setz size
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", clientSize[client]);


		if (STAMM_GetGame() == GameTF2)
		{
			// On TF2 setz head size
			SetEntPropFloat(client, Prop_Send, "m_flHeadScale", clientSize[client]);
		}
	}
}



// For TF2 set head size on game frame
public OnGameFrame()
{
	if (STAMM_GetGame() == GameTF2)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (STAMM_IsClientValid(i) && clientSize[i] != 1.0)
			{
				// Set head size
				SetEntPropFloat(i, Prop_Send, "m_flHeadScale", clientSize[i]);
			}
		}
	}
}