
/**
 * -----------------------------------------------------
 * File        stamm_antiflash.sp
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
#include <flashtools>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1



new Handle:g_hAntiTeamFlash;
new Handle:g_hAntiFlash;



public Plugin:myinfo =
{
	name = "Stamm Feature Anti Flash",
	author = "Popoklopsi",
	version = "1.4.0",
	description = "Give VIP's anti flash",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};





// Add the feature
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

	// We need flashtools
	if (GetExtensionFileStatus("flashtools.ext") != 1)
	{
		SetFailState("Can't Load Feature, you need to install flashtools!");
	}


	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP Anti Flash");
}




// Feaure loaded, set textes
public STAMM_OnFeatureLoaded(const String:basename[])
{
	decl String:urlString[256];


	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
	}
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	if (GetConVarBool(g_hAntiFlash)) 
	{
		Format(fmt, sizeof(fmt), "%T", "GetAntiFlash", client);
	}
	else 
	{
		Format(fmt, sizeof(fmt), "%T", "GetTeamFlash", client);
	}
	
	PushArrayString(array, fmt);
}




// Create the config
public OnPluginStart()
{
	AutoExecConfig_SetFile("anti_flash", "stamm/features");
	AutoExecConfig_SetCreateFile(true);


	g_hAntiTeamFlash = AutoExecConfig_CreateConVar("vip_antiteamflash", "1", "1=Team will not be flashed by VIP's flashbang!, 0=Off");
	g_hAntiFlash = AutoExecConfig_CreateConVar("vip_antiflash", "1", "1=VIP can't be flashed by anyone, 0=he can't be flashed by team");
	

	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}




// A player gets flashed
public Action:OnGetPercentageOfFlashForPlayer(client, entity, Float:pos[3], &Float:percent)
{
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	new team = GetClientTeam(client);
	new team2 = GetClientTeam(owner);


	// Anti team flash
	if (STAMM_IsClientValid(client))
	{
		if (STAMM_IsClientValid(owner))
		{
			if (team == team2 && owner != client && GetConVarBool(g_hAntiTeamFlash) && STAMM_HaveClientFeature(owner)) 
			{
				return Plugin_Handled;
			}
		}

		// Anti flash
		if (STAMM_HaveClientFeature(client) && ((GetConVarBool(g_hAntiFlash)) || (team == team2)))
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}