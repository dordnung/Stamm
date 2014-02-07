/**
 * -----------------------------------------------------
 * File        stamm_money.sp
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



new Handle:g_hCash;
new Handle:g_hMax;




public Plugin:myinfo =
{
	name = "Stamm Feature Money",
	author = "Popoklopsi",
	version = "1.3.0",
	description = "Give VIP's every Round x Cash",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// Add feature
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


	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP Cash");
}




// Add feature text
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
	
	Format(fmt, sizeof(fmt), "%T", "GetCash", client, GetConVarInt(g_hCash));
	
	PushArrayString(array, fmt);
}





// Create Config
public OnPluginStart()
{
	AutoExecConfig_SetFile("cash", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hCash = AutoExecConfig_CreateConVar("money_amount", "2000", "x = Cash, what a VIP gets, when he spawns");
	g_hMax = AutoExecConfig_CreateConVar("money_max", "1", "1 = Give not more than the max. Money, 0 = Off");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
	

	HookEvent("player_spawn", eventPlayerSpawn);
}




// Player spawned
public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new max = GetConVarInt(g_hMax);

	
	if (STAMM_IsClientValid(client))
	{
		// Valid team
		if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && STAMM_HaveClientFeature(client))
		{
			// Get old money and calc. new one
			new OldMoney = GetEntData(client, FindSendPropOffs("CCSPlayer", "m_iAccount"));
			new NewMoney = GetConVarInt(g_hCash) + OldMoney;
			
			// Max money reached?
			if (STAMM_GetGame() == GameCSS && NewMoney > 16000 && max) 
			{
				NewMoney = 16000;
			}

			if (STAMM_GetGame() == GameCSGO && max)
			{
				new MaxMoney = GetConVarInt(FindConVar("mp_maxmoney"));
				
				if (NewMoney > MaxMoney)
				{
					NewMoney = MaxMoney;
				}
			}
			
			// Set new money
			SetEntData(client, FindSendPropOffs("CCSPlayer", "m_iAccount"), NewMoney);
		}
	}
}