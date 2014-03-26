/**
 * -----------------------------------------------------
 * File        stamm_longjump.sp
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


// Includes
#include <sourcemod>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

#define HORIZONTAL 33
#define VERTICAL 33



new Handle:g_hStrong;




public Plugin:myinfo =
{
	name = "Stamm Feature LongJump",
	author = "Popoklopsi",
	version = "1.1.1",
	description = "VIP's have Long Jump",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// Create config
public OnPluginStart()
{
	HookEvent("player_jump", OnPlayerJump);


	AutoExecConfig_SetFile("longjump", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hStrong = AutoExecConfig_CreateConVar("longjump_strong", "3", "The longjump factor");

	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}





// Auto updater
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




// Add feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}


	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP LongJump");
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetLongJump", client);
	
	PushArrayString(array, fmt);
}




public OnPlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (STAMM_IsClientValid(client) && STAMM_HaveClientFeature(client))
	{
		new team = GetClientTeam(client);
		new strong = GetConVarInt(g_hStrong);


		if (team > 1 && team < 4)
		{
			new Float:fViewVector[3];

			new Float:fAngle0 = GetEntPropFloat(client, Prop_Send, "m_angEyeAngles[0]");
			new Float:fAngle1 = GetEntPropFloat(client, Prop_Send, "m_angEyeAngles[1]");


			fViewVector[0] = Cosine(DegToRad(fAngle1));
			fViewVector[1] = Sine(DegToRad(fAngle1));
			fViewVector[2] = -1 * Sine(DegToRad(fAngle0));

			fViewVector[0] = float(HORIZONTAL) * float(strong) * fViewVector[0];
			fViewVector[1] = float(HORIZONTAL) * float(strong) * fViewVector[1];
			fViewVector[2] = float(VERTICAL) * float(strong);


			SetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", fViewVector);
		}
	}
}