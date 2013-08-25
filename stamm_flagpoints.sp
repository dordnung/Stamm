/**
 * -----------------------------------------------------
 * File        stamm_flagpoints.sp
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

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1




new Handle:flagneed_c;
new String:flagneed[12];



public Plugin:myinfo =
{
	name = "Stamm Feature FlagPoints",
	author = "Popoklopsi",
	version = "1.0.3",
	description = "Give only points to players with a specific flag",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};



// Auto updater
public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
	}
}



// Create config
public OnPluginStart()
{
	AutoExecConfig_SetFile("flagpoints", "stamm/features");

	flagneed_c = AutoExecConfig_CreateConVar("flag_need", "s", "Flag a player needs to collect points");
	
	AutoExecConfig(true, "flagpoints", "stamm/features");
	AutoExecConfig_CleanFile();
}



// Add Feature
public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	// Good colors
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

	// Load Translation
	STAMM_LoadTranslation();
		
	STAMM_AddFeature("VIP FlagPoints", "");
}



// Load Config
public OnConfigsExecuted()
{
	GetConVarString(flagneed_c, flagneed, sizeof(flagneed));
}



// Stop non VIP's getting points
public Action:STAMM_OnClientGetPoints_PRE(client, &number)
{
	if (clientAllowed(client))
	{
		return Plugin_Continue;
	}
	else
	{
		CPrintToChat(client, "{lightgreen}[ {green}Stamm {lightgreen}] %t", "NoPoints", flagneed);
	}

	return Plugin_Handled;
}



// Check client flags
// Hugh stuff oO
public bool:clientAllowed(client)
{
	if (STAMM_IsClientValid(client))
	{
		new AdminId:adminid = GetUserAdmin(client);
		new AdminFlag:flag;

		FindFlagByChar(flagneed[0], flag);

		return GetAdminFlag(adminid, flag);
	}
	
	return false;
}