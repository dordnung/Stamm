/**
 * -----------------------------------------------------
 * File        stamm_weapons.sp
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
#include <sdktools>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>
#include <cstrike>

#pragma semicolon 1



new g_iMaximum;
new g_iUsages[MAXPLAYERS + 1];

new Handle:g_hMode = INVALID_HANDLE;

new Handle:g_hKV;
new Handle:g_hWeaponList;




public Plugin:myinfo =
{
	name = "Stamm Feature Weapons",
	author = "Popoklopsi",
	version = "1.3.2",
	description = "Give VIP's weapons",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
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




// Add the feature
public OnAllPluginsLoaded()
{
	decl String:path[PLATFORM_MAX_PATH + 1];


	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
	{
		SetFailState("Can't Load Feature, not Supported for your game!");
	}


	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP Weapons");


	if (STAMM_GetGame() == GameCSGO)
	{
		// Config for CSGO
		Format(path, sizeof(path), "cfg/stamm/features/WeaponSettings_csgo.txt");
	}

	else
	{
		// Config for CSS
	 	Format(path, sizeof(path), "cfg/stamm/features/WeaponSettings_css.txt");
	}



	// File doesn't exists? we cen abort here
	if (!FileExists(path))
	{
		SetFailState("Couldn't find the config %s", path);
	}



	// Read the config
	g_hKV = CreateKeyValues("WeaponSettings");
	FileToKeyValues(g_hKV, path);
	
	// Maxium gives
	g_iMaximum = KvGetNum(g_hKV, "maximum");
	
	// Create Menu
	g_hWeaponList = CreateMenu(weaponlist_handler);
	SetMenuTitle(g_hWeaponList, "!sgive <weapon_name>");
	

	// Parse config
	if (KvGotoFirstSubKey(g_hKV, false))
	{
		decl String:buffer[120];
		decl String:buffer2[120];

		do
		{
			// Get Weaponname
			KvGetSectionName(g_hKV, buffer, sizeof(buffer));

			strcopy(buffer2, sizeof(buffer2), buffer);

			// Replace weapon_ tag
			ReplaceString(buffer, sizeof(buffer), "weapon_", "");

			// And go back
			KvGoBack(g_hKV);
			
			//  Get status of weapon
			if (!StrEqual(buffer2, "maximum") && KvGetNum(g_hKV, buffer2) == 1) 
			{
				AddMenuItem(g_hWeaponList, buffer, buffer);
			}


			KvJumpToKey(g_hKV, buffer2);
		} 
		while (KvGotoNextKey(g_hKV, false));

		// Go Back
		KvRewind(g_hKV);
	}
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];

	if (GetConVarInt(g_hMode) == 1)
	{
		Format(fmt, sizeof(fmt), "%T", "GetWeaponsAsT", client);
	}
	else if (GetConVarInt(g_hMode) == 2)
	{
		Format(fmt, sizeof(fmt), "%T", "GetWeaponsAsCT", client);
	}
	else
	{
		Format(fmt, sizeof(fmt), "%T", "GetWeapons", client);
	}

	PushArrayString(array, fmt);
}




// Load the configs
public OnPluginStart()
{
	// Register commands
	RegConsoleCmd("sm_sgive", GiveCallback, "Give VIP's Weapons");
	RegConsoleCmd("sm_sweapons", InfoCallback, "show Weaponlist");
	
	HookEvent("round_start", RoundStart);

	AutoExecConfig_SetFile("weapons", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hMode = AutoExecConfig_CreateConVar("sm_sweapons_restrict", "0", "0 - Players on both teams can give weapons themselve, 1 - Only terrorists can give weapons themselves, 2 - Only counter-terrorists can give weapons themselves");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}


// Add Command for weapons
public STAMM_OnClientRequestCommands(client)
{
	if (STAMM_HaveClientFeature(client))
	{
		STAMM_AddCommand("!sweapons", "%T", "GetWeapons", client);
	}
}


// Menu handler 
public weaponlist_handler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (STAMM_IsClientValid(param1))
		{
			decl String:choose[64];
				
			GetMenuItem(menu, param2, choose, sizeof(choose));
			
			// Fake command client, explicit to show
			FakeClientCommandEx(param1, "sm_sgive %s", choose);
		}
	}
}




// Resetz uses
public RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	for (new x=0; x <= MaxClients; x++)
	{ 
		g_iUsages[x] = 0;
	}
}





// Also reset usages
public STAMM_OnClientReady(client)
{
	g_iUsages[client] = 0;
}




// Open weapon menu
public Action:InfoCallback(client, args)
{
	decl String:tag[64];
	
	if (STAMM_IsClientValid(client) && STAMM_HaveClientFeature(client))
	{
		STAMM_GetTag(tag, sizeof(tag));

		if (GetConVarInt(g_hMode) == 1)
		{
			if (GetClientTeam(client) == CS_TEAM_T)
			{
				DisplayMenu(g_hWeaponList, client, 40);
			}
			else
			{
				STAMM_PrintToChat(client, "%s %t", tag, "CTCanNotGive");
			}
		}

		else if (GetConVarInt(g_hMode) == 2)
		{
			if (GetClientTeam(client) == CS_TEAM_CT)
			{
				DisplayMenu(g_hWeaponList, client, 40);
			}
			else
			{
				STAMM_PrintToChat(client, "%s %t", tag, "TCanNotGive");
			}
		}
		
		else
		{
			DisplayMenu(g_hWeaponList, client, 40);
		}
	}

	return Plugin_Handled;
}




// Give a weapon
public Action:GiveCallback(client, args)
{
	decl String:tag[64];

	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client) && IsPlayerAlive(client))
		{
			STAMM_GetTag(tag, sizeof(tag));

			if (GetCmdArgs() == 1)
			{
				if (GetConVarInt(g_hMode) == 1)
				{
					if (GetClientTeam(client) == CS_TEAM_CT)
					{
						STAMM_PrintToChat(client, "%s %t", tag, "CTCanNotGive");

						return Plugin_Handled;
					}
				}
				else if (GetConVarInt(g_hMode) == 2)
				{
					if (GetClientTeam(client) == CS_TEAM_T)
					{
						STAMM_PrintToChat(client, "%s %t", tag, "TCanNotGive");

						return Plugin_Handled;
					}
				}

				// max. usages not reached
				if (g_iUsages[client] < g_iMaximum)
				{
					decl String:WeaponName[64];
					
					GetCmdArg(1, WeaponName, sizeof(WeaponName));

					// Add weapon tag
					Format(WeaponName, sizeof(WeaponName), "weapon_%s", WeaponName);


					// Enabled?
					if (KvGetNum(g_hKV, WeaponName))
					{
						// Give Item
						GivePlayerItem(client, WeaponName);
						
						g_iUsages[client]++;
					}
					else 
					{
						STAMM_PrintToChat(client, "%s %t", tag, "WeaponFailed");
					}
				}
				else
				{
					STAMM_PrintToChat(client, "%s %t", tag, "MaximumReached");
				}
			}
			else 
			{
				STAMM_PrintToChat(client, "%s %t", tag, "WeaponFailed");
			}
		}
	}

	return Plugin_Handled;
}