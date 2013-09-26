/**
 * -----------------------------------------------------
 * File        stamm_losepoints.sp
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
#include <colors>
#include <morecolors_stamm>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1




new deathCounter[MAXPLAYERS + 1];

new Handle:deathcount_c;
new Handle:pointscount_c;

new deathcount;
new pointscount;



public Plugin:myinfo =
{
	name = "Stamm Feature LosePoints",
	author = "Popoklopsi",
	version = "1.1.0",
	description = "Non VIP's lose until a specific level points on death",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};



// Add feature
public OnAllPluginsLoaded()
{
	decl String:haveDescription[64];

	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}


	STAMM_LoadTranslation();

	Format(haveDescription, sizeof(haveDescription), "%T", "NoLosePoints", LANG_SERVER);
	
	STAMM_AddFeature("VIP LosePoints", haveDescription, false);
}




// Auto updater
public STAMM_OnFeatureLoaded(const String:basename[])
{
	decl String:urlString[256];


	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
	}
}



// Create Config
public OnPluginStart()
{
	// Colors :)
	if (!CColorAllowed(Color_Lightgreen))
	{
		if (CColorAllowed(Color_Lime))
		{
			CReplaceColor(Color_Lightgreen, Color_Lime);
		}
		else if (CColorAllowed(Color_Olive))
		{
			CReplaceColor(Color_Lightgreen, Color_Olive);
		}
	}
	


	HookEvent("player_death", PlayerDeath);



	AutoExecConfig_SetFile("losepoints", "stamm/features");

	deathcount_c = AutoExecConfig_CreateConVar("death_count", "2", "How much deaths a player needs to lose points");
	pointscount_c = AutoExecConfig_CreateConVar("points_count", "2", "How much points a player loses after <death_count> deaths");

	AutoExecConfig(true, "losepoints", "stamm/features");
	AutoExecConfig_CleanFile();
}



// Load config
public OnConfigsExecuted()
{
	deathcount = GetConVarInt(deathcount_c);
	pointscount = GetConVarInt(pointscount_c);
}



// Death counter -> zero
public OnClientAuthorized(client, const String:auth[])
{
	deathCounter[client] = 0;
}




// A Player died
public PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	decl String:tag[64];

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	

	if (STAMM_IsClientValid(client) && attacker > 0 && client != attacker)
	{
		// Client doesn't have the feature
		if (!STAMM_HaveClientFeature(client) && IsClientInGame(attacker) && (GetClientTeam(client) != GetClientTeam(attacker)))
		{
			// check death count
			if (++deathCounter[client] == deathcount)
			{				
				// Delete points ):
				STAMM_DelClientPoints(client, pointscount);


				if (STAMM_GetGame() == GameCSGO)
				{
					CPrintToChat(client, "%s %t", tag, "LosePoints", pointscount, deathcount);
				}
				else
				{
					MCPrintToChat(client, "%s %t", tag, "LosePoints", pointscount, deathcount);
				}


				deathCounter[client] = 0;
			}
		}
	}
}