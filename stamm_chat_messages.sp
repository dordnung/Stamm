/**
 * -----------------------------------------------------
 * File        stamm_chat_messages.sp
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


// Icnludes
#include <sourcemod>
#include <colors>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1




new welcome;
new leave;



public Plugin:myinfo =
{
	name = "Stamm Feature Chat Messages",
	author = "Popoklopsi",
	version = "1.2.2",
	description = "Give VIP's VIP Chat and Message",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};



// ADd Feature
public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

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
		

	STAMM_LoadTranslation();
		
	STAMM_AddFeature("VIP Chat Messages", "");
}



// Feature loaded
public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:description[64];
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	// Auto updater
	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
	}


	// Get Blocks
	welcome = STAMM_GetBlockOfName("welcome");
	leave = STAMM_GetBlockOfName("leave");


	// Check valid?
	if (welcome != -1)
	{
		Format(description, sizeof(description), "%T", "GetWelcomeMessages", LANG_SERVER);
		STAMM_AddFeatureText(STAMM_GetLevel(welcome), description);
	}

	if (leave != -1)
	{
		Format(description, sizeof(description), "%T", "GetLeaveMessages", LANG_SERVER);
		STAMM_AddFeatureText(STAMM_GetLevel(leave), description);
	}
}



// Client Ready
public STAMM_OnClientReady(client)
{
	decl String:name[MAX_NAME_LENGTH + 1];
	
	GetClientName(client, name, sizeof(name));
	

	// Gets a welcome message?
	if (welcome != -1 && STAMM_IsClientValid(client) && STAMM_HaveClientFeature(client, welcome))
	{
		CPrintToChatAll("{lightgreen}[ {green}Stamm {lightgreen}] %T", "WelcomeMessage", LANG_SERVER, name);
	}
}


// Client Disonnect
public OnClientDisconnect(client)
{
	if (STAMM_IsClientValid(client) && leave != -1)
	{
		decl String:name[MAX_NAME_LENGTH + 1];
		
		GetClientName(client, name, sizeof(name));


		// Gets a leave message?
		if (STAMM_HaveClientFeature(client, leave))
		{
			CPrintToChatAll("{lightgreen}[ {green}Stamm {lightgreen}] %T", "LeaveMessage", LANG_SERVER, name);
		}
	}
}