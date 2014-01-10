/**
 * -----------------------------------------------------
 * File        stamm_hookgraperope.sp
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

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>
#include <hgr>

#pragma semicolon 1



new grap;
new hook;
new rope;



public Plugin:myinfo =
{
	name = "Stamm Feature Hook Grape Rope",
	author = "Popoklopsi",
	version = "1.1.0",
	description = "Allows VIP's to grap, hook or rope",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};



// Add feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	STAMM_LoadTranslation();
	STAMM_AddFeature("VIP HookGrapeRope");
}



// auto updater and load description
public STAMM_OnFeatureLoaded(const String:basename[])
{
	decl String:urlString[256];



	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
	}


	// Load Descriptions for each block
	grap = STAMM_GetBlockOfName("grap");
	hook = STAMM_GetBlockOfName("hook");
	rope = STAMM_GetBlockOfName("rope");



	if (grap != -1)
	{
		STAMM_AddBlockDescription(grap, "%T", "GetGrap", LANG_SERVER);
	}

	if (hook != -1)
	{
		STAMM_AddBlockDescription(hook, "%T", "GetHook", LANG_SERVER);
	}

	if (rope != -1)
	{
		STAMM_AddBlockDescription(rope, "%T", "GetRope", LANG_SERVER);
	}
}




// Client is ready, check three blocks
public STAMM_OnClientReady(client)
{
	if (STAMM_IsClientValid(client))
	{
		if (hook != -1 && STAMM_HaveClientFeature(client, hook))
		{
			HGR_ClientAccess(client, 0, 0);
		}

		else
		{
			HGR_ClientAccess(client, 1, 0);
		}


		if (grap != -1 && STAMM_HaveClientFeature(client, grap))
		{
			HGR_ClientAccess(client, 0, 1);
		}

		else
		{
			HGR_ClientAccess(client, 1, 1);
		}


		if (rope != -1 && STAMM_HaveClientFeature(client, rope))
		{
			HGR_ClientAccess(client, 0, 2);
		}

		else
		{
			HGR_ClientAccess(client, 1, 2);
		}
	}
	
	else
	{
		// No vips, no features :D
		HGR_ClientAccess(client, 1, 0);
		HGR_ClientAccess(client, 1, 1);
		HGR_ClientAccess(client, 1, 2);
	}
}