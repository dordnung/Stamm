/**
 * -----------------------------------------------------
 * File        stamm_hookgrabrope.sp
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



new g_iGrab;
new g_iHook;
new g_iRope;




public Plugin:myinfo =
{
	name = "Stamm Feature Hook Grab Rope",
	author = "Popoklopsi",
	version = "1.1.0",
	description = "Allows VIP's to grab, hook or rope",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// Add feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	// We need plugin hgr	
	if (!LibraryExists("hookgrabrope")) 
	{
		SetFailState("Can't Load Feature, hookgrabrope is not installed!");
	}

	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP HookGrabRope");
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
	g_iGrab = STAMM_GetBlockOfName("grab");
	g_iHook = STAMM_GetBlockOfName("hook");
	g_iRope = STAMM_GetBlockOfName("rope");


	if (g_iGrab == -1 && g_iHook == -1 && g_iRope == -1)
	{
		SetFailState("Found neither block grap nor block hoo nor block rope!");
	}
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	if (block == g_iGrab)
	{
		Format(fmt, sizeof(fmt), "%T", "GetGrab", client);
		PushArrayString(array, fmt);
	}

	if (block == g_iHook)
	{
		Format(fmt, sizeof(fmt), "%T", "GetHook", client);
		PushArrayString(array, fmt);
	}

	if (block == g_iRope)
	{
		Format(fmt, sizeof(fmt), "%T", "GetRope", client);
		PushArrayString(array, fmt);
	}
}




// Client is ready, check three blocks
public STAMM_OnClientReady(client)
{
	if (STAMM_IsClientValid(client))
	{
		if (g_iHook != -1 && STAMM_HaveClientFeature(client, g_iHook))
		{
			HGR_ClientAccess(client, 0, 0);
		}

		else
		{
			HGR_ClientAccess(client, 1, 0);
		}


		if (g_iGrab != -1 && STAMM_HaveClientFeature(client, g_iGrab))
		{
			HGR_ClientAccess(client, 0, 1);
		}

		else
		{
			HGR_ClientAccess(client, 1, 1);
		}


		if (g_iRope != -1 && STAMM_HaveClientFeature(client, g_iRope))
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