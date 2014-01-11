/**
 * -----------------------------------------------------
 * File        stamm_froggyjump.sp
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


// Include
#include <sourcemod>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

// For TF2
#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>



#pragma semicolon 1



new g_iFroggyJumped[MAXPLAYERS + 1];

new Handle:g_hStrong;




public Plugin:myinfo =
{
	name = "Stamm Feature FroggyJump",
	author = "Popoklopsi",
	version = "1.1.0",
	description = "VIP's have Froggy Jump",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




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




// Create config
public OnPluginStart()
{
	AutoExecConfig_SetFile("froggyjump", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hStrong = AutoExecConfig_CreateConVar("froggyjump_strong", "200", "The push up strong");

	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}





// Add the feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}


	STAMM_LoadTranslation();
	STAMM_AddFastFeature("VIP FroggyJump", "%T", "GetFroggyJump", LANG_SERVER);
}



// Allow double jump
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!STAMM_IsClientValid(client))
	{
		return Plugin_Continue;
	}


	// VIP?
	if (!STAMM_HaveClientFeature(client) || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}


	// In TF2, not for Scout
	if (STAMM_GetGame() == GameTF2)
	{
		if (TF2_GetPlayerClass(client) == TFClass_Scout)
		{
			return Plugin_Continue;
		}
	}


	// Last button
	static bool:bPressed[MAXPLAYERS+1] = false;
	

	// Reset when on Ground
	if (GetEntityFlags(client) & FL_ONGROUND)
	{
		g_iFroggyJumped[client] = 0;
		bPressed[client] = false;
	}
	else
	{
		// Player pressed jump button?
		if (buttons & IN_JUMP)
		{

			// For second time?
			if (!bPressed[client] && g_iFroggyJumped[client]++ == 1)
			{
				new Float:velocity[3];
				new Float:velocity0;
				new Float:velocity1;
				new Float:velocity2;
				new Float:velocity2_new;

				// Get player velocity
				velocity0 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
				velocity1 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
				velocity2 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");

				velocity2_new = float(GetConVarInt(g_hStrong));



				// calculate new velocity^^
				if (velocity2 < 150.0)
				{
					velocity2_new = velocity2_new + 20.0;
				}
				if (velocity2 < 100.0) 
				{
					velocity2_new = velocity2_new + 30.0;
				}
				if (velocity2 < 50.0) 
				{
					velocity2_new = velocity2_new + 40.0;
				}
				if (velocity2 < 0.0) 
				{
					velocity2_new = velocity2_new + 50.0;
				}
				if (velocity2 < -50.0) 
				{
					velocity2_new = velocity2_new + 60.0;
				}
				if (velocity2 < -100.0) 
				{
					velocity2_new = velocity2_new + 70.0;
				}
				if (velocity2 < -150.0) 
				{
					velocity2_new = velocity2_new + 80.0;
				}
				if (velocity2 < -200.0) 
				{
					velocity2_new = velocity2_new + 90.0;
				}



				// Set new velocity
				velocity[0] = velocity0 * 0.1;
				velocity[1] = velocity1 * 0.1;
				velocity[2] = velocity2_new;
				
				// Double Jump
				SetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", velocity);
			}

			bPressed[client] = true;
		}
		else
		{
			bPressed[client] = false;
		}
	}

	return Plugin_Continue;
}