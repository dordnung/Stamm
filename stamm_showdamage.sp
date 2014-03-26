/**
 * -----------------------------------------------------
 * File        stamm_showdamage.sp
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



new Handle:g_hDamageArea;




public Plugin:myinfo =
{
	name = "Stamm Feature Show Damage",
	author = "Popoklopsi",
	version = "1.3.1",
	description = "VIP's can see the damage they done",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};





// Add to updater on feature loaded
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




// Add Feature when all plugins are loaded
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}


	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP Show Damage");
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	Format(fmt, sizeof(fmt), "%T", "GetShowDamage", client);
	
	PushArrayString(array, fmt);
}




// Load config when plugin started
public OnPluginStart()
{
	AutoExecConfig_SetFile("show_damage", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hDamageArea = AutoExecConfig_CreateConVar("damage_area", "1", "Textarea where to show message, 1=Center Text, 2=Hint Text, 3=Chat");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
	
	HookEvent("player_hurt", eventPlayerHurt);
}





// A player hurts
public Action:eventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));

	// Is client valid and want feature?
	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			// Get damage done, the games have different event types oO
			new damage;
			
			if (STAMM_GetGame() == GameTF2) 
			{
				damage = GetEventInt(event, "damageamount");
			}

			else if (STAMM_GetGame() == GameDOD)
			{
				damage = GetEventInt(event, "damage");
			}

			else 
			{
				damage = GetEventInt(event, "dmg_health");
			}

			// Switch the area to show to and show it
			switch(GetConVarInt(g_hDamageArea))
			{
				case 1:
				{
					PrintCenterText(client, "- %i HP", damage);
				}

				case 2:
				{
					PrintHintText(client, "- %i HP", damage);
				}
				
				case 3:
				{
					STAMM_PrintToChat(client, "{green}- %i HP", damage);
				}
			}
		}
	}
}