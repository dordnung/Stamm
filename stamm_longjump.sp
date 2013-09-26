/**
 * -----------------------------------------------------
 * File        stamm_longjump.sp
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



new bool:bPressed[MAXPLAYERS+1] = false;

new Handle:c_strong;
new strong;



public Plugin:myinfo =
{
	name = "Stamm Feature LongJump",
	author = "Popoklopsi",
	version = "1.0.2",
	description = "VIP's have Long Jump",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};



// Create config
public OnPluginStart()
{
	AutoExecConfig_SetFile("longjump", "stamm/features");

	c_strong = AutoExecConfig_CreateConVar("longjump_strong", "3", "The longjump factor");

	AutoExecConfig(true, "longjump", "stamm/features");
	AutoExecConfig_CleanFile();
}



// Load config
public OnConfigsExecuted()
{
	strong = GetConVarInt(c_strong);
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



// Add feature
public OnAllPluginsLoaded()
{
	decl String:haveDescription[64];

	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}


	STAMM_LoadTranslation();

	Format(haveDescription, sizeof(haveDescription), "%T", "GetLongJump", LANG_SERVER);
	
	STAMM_AddFeature("VIP LongJump", haveDescription);
}




// Check for jumping
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!STAMM_IsClientValid(client))
	{
		return Plugin_Continue;
	}

	if (!STAMM_HaveClientFeature(client) || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}


	// Resetz on Ground
	if (GetEntityFlags(client) & FL_ONGROUND)
	{
		bPressed[client] = false;
	}
	
	else
	{
		// Player jumped
		if (buttons & IN_JUMP)
		{
			// For first time
			if(!bPressed[client])
			{
				new Float:velocity[3];
				new Float:velocity0;
				new Float:velocity1;
				
				// Calculate long jump
				velocity0 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
				velocity1 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
				
				velocity[0] = (float(strong) * velocity0) * (1.0 / 4.1);
				velocity[1] = (float(strong) * velocity1) * (1.0 / 4.1);
				velocity[2] = 0.0;
				
				// Give longjump
				SetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", velocity);
			}

			bPressed[client] = true;
		}
	}

	return Plugin_Continue;
}