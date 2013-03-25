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

new Handle:c_cash;
new Handle:c_max;

new cash;
new maxm;

public Plugin:myinfo =
{
	name = "Stamm Feature Money",
	author = "Popoklopsi",
	version = "1.2.1",
	description = "Give VIP's every Round x Cash",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};



// Add feature
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

	STAMM_LoadTranslation();
		
	STAMM_AddFeature("VIP Cash", "");
}



// Add feature text
public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:description[64];
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
	}

	Format(description, sizeof(description), "%T", "GetCash", LANG_SERVER, cash);
	
	STAMM_AddFeatureText(STAMM_GetLevel(), description);
}



// Create Config
public OnPluginStart()
{
	AutoExecConfig_SetFile("cash", "stamm/features");

	c_cash = AutoExecConfig_CreateConVar("money_amount", "2000", "x = Cash, what a VIP gets, when he spawns");
	c_max = AutoExecConfig_CreateConVar("money_max", "1", "1 = Give not more than the max. Money, 0 = Off");
	
	AutoExecConfig(true, "cash", "stamm/features");
	AutoExecConfig_CleanFile();
	
	HookEvent("player_spawn", eventPlayerSpawn);
}



// Load Config
public OnConfigsExecuted()
{
	cash = GetConVarInt(c_cash);
	maxm = GetConVarInt(c_max);
}



// Player spawned
public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (STAMM_IsClientValid(client))
	{
		// Valid team
		if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && STAMM_HaveClientFeature(client))
		{
			// Get old money and calc. new one
			new OldMoney = GetEntData(client, FindSendPropOffs("CCSPlayer", "m_iAccount"));
			new NewMoney = cash + OldMoney;
			
			// Max money reached?
			if (STAMM_GetGame() == GameCSS && NewMoney > 16000 && maxm) 
			{
				NewMoney = 16000;
			}

			if (STAMM_GetGame() == GameCSGO && maxm)
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