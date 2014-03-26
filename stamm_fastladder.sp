/**
 * -----------------------------------------------------
 * File        stamm_fastladder.sp
 * Authors     Bara
 * License     GPLv3
 * Web         http://bara.in
 * -----------------------------------------------------
 * 
 * Copyright (C) 2012-2014 Bara
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

#pragma semicolon 1




public Plugin:myinfo = 
{
	name = "FastLadder",
	author = "Bara",
	description = "Prohibit non VIP's the fast go up on ladders",
	version = "1.1.1",
	url = "www.bara.in"
};




// Add to auto updater
public STAMM_OnFeatureLoaded(const String:basename[])
{
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
		Updater_ForceUpdate();
	}
}



// Add feature for CSS and CSGO
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
	STAMM_RegisterFeature("VIP FastLadder");
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetFastLadder", client);
	
	PushArrayString(array, fmt);
}




// Player climb on ladder?
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (STAMM_IsClientValid(client) && !STAMM_HaveClientFeature(client))
	{
		// Is it on a ladder?
		if (GetEntityMoveType(client) == MOVETYPE_LADDER)
		{
			// Change button if he is not a VIP
			if (buttons & IN_FORWARD || buttons & IN_BACK)
			{
				if (buttons & IN_MOVELEFT)
				{
					buttons &= ~IN_MOVELEFT;
				}

				if (buttons & IN_MOVERIGHT)
				{
					buttons &= ~IN_MOVERIGHT;
				}
			}
		}
	}
}