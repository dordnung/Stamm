/**
 * -----------------------------------------------------
 * File        stamm_chat_messages.sp
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


// Icnludes
#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1




new g_iWelcome = -1;
new g_iLeave = -1;




public Plugin:myinfo =
{
	name = "Stamm Feature Chat Messages",
	author = "Popoklopsi",
	version = "1.3.2",
	description = "Give VIP's VIP Chat and Message",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// ADd Feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}


	STAMM_LoadTranslation();	
	STAMM_RegisterFeature("VIP Chat Messages");
}




// Feature loaded
public STAMM_OnFeatureLoaded(const String:basename[])
{
	decl String:urlString[256];



	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	// Auto updater
	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
		Updater_ForceUpdate();
	}


	// Get Blocks
	g_iWelcome = STAMM_GetBlockOfName("welcome");
	g_iLeave = STAMM_GetBlockOfName("leave");
	

	if (g_iWelcome == -1 && g_iLeave == -1)
	{
		SetFailState("Found neither block welcome nor block leave!");
	}
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	if (block == g_iWelcome)
	{
		Format(fmt, sizeof(fmt), "%T", "GetWelcomeMessages", client);
		
		PushArrayString(array, fmt);
	}

	if (block == g_iLeave)
	{
		Format(fmt, sizeof(fmt), "%T", "GetLeaveMessages", client);
		
		PushArrayString(array, fmt);
	}
}




// Client Ready
public STAMM_OnClientReady(client)
{
	decl String:name[MAX_NAME_LENGTH + 1];
	decl String:tag[64];


	GetClientName(client, name, sizeof(name));
	STAMM_GetTag(tag, sizeof(tag));


	// Gets a welcome message?
	if (g_iWelcome != -1 && STAMM_IsClientValid(client) && STAMM_HaveClientFeature(client, g_iWelcome))
	{
		STAMM_PrintToChatAll("%s %t", tag, "WelcomeMessage", name);
	}
}


// Client Disonnect
public OnClientDisconnect(client)
{
	if (STAMM_IsClientValid(client) && g_iLeave != -1)
	{
		decl String:name[MAX_NAME_LENGTH + 1];
		decl String:tag[64];


		GetClientName(client, name, sizeof(name));
		STAMM_GetTag(tag, sizeof(tag));


		// Gets a leave message?
		if (STAMM_HaveClientFeature(client, g_iLeave))
		{
			STAMM_PrintToChatAll("%s %t", tag, "LeaveMessage", name);
		}
	}
}