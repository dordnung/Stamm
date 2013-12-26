
/**
 * -----------------------------------------------------
 * File        stamm_antiflash.sp
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
#include <flashtools>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1



new Handle:antiteamflash_c;
new Handle:antiflash_c;

new antiteamflash;
new antiflash;




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
	if (!LibraryExists("stamm")) 
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
	STAMM_AddFeature("VIP Anti Flash");
}



// Feaure loaded, set textes
public STAMM_OnFeatureLoaded(const String:basename[])
{
	decl String:team[64];
	decl String:team2[64];
	decl String:urlString[256];



	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
	}



	// Anti team flash translations
	if (antiteamflash) 
	{
		Format(team, sizeof(team), "%T", "GetTeamAntiFlash", LANG_SERVER);
	}
	else 
	{
		Format(team, sizeof(team), "");
	}


	// Antiflash translations
	if (antiflash) 
	{
		Format(team2, sizeof(team2), "%T", "AntiFlash", LANG_SERVER);
	}

	else 
	{

		Format(team2, sizeof(team2), "%T", "AntiTeamFlash", LANG_SERVER);
	}
	

	STAMM_AddBlockDescription(1, "%T", "GetAntiFlash", LANG_SERVER, team, team2);
}



// Create the config
public OnPluginStart()
{
	AutoExecConfig_SetFile("anti_flash", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	antiteamflash_c = AutoExecConfig_CreateConVar("vip_antiteamflash", "1", "1=Team will not be flashed by VIP's flashbang!, 0=Off");
	antiflash_c = AutoExecConfig_CreateConVar("vip_antiflash", "1", "1=VIP can't be flashed by anyone, 0=he can't be flashed by team");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}


// Load the config
public OnConfigsExecuted()
{
	antiteamflash = GetConVarInt(antiteamflash_c);
	antiflash = GetConVarInt(antiflash_c);
}


// A player gets flashed
public Action:OnGetPercentageOfFlashForPlayer(client, entity, Float:pos[3], &Float:percent)
{
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	new team = GetClientTeam(client);
	new team2 = GetClientTeam(owner);


	// Anti team flash	
	if (STAMM_IsClientValid(owner) && STAMM_IsClientValid(client))
	{
		if (team == team2 && owner != client && antiteamflash && STAMM_HaveClientFeature(owner)) 
		{
			return Plugin_Handled;
		}
	}

	// Anti flash
	if (STAMM_HaveClientFeature(client) && ((antiflash) || (team == team2)))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}