/**
 * -----------------------------------------------------
 * File        stamm_weapons.sp
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
#include <sdktools>
#include <colors>
#include <morecolors_stamm>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1



new maximum;
new Usages[MAXPLAYERS + 1];

new Handle:kv;
new Handle:weaponlist;



public Plugin:myinfo =
{
	name = "Stamm Feature Weapons",
	author = "Popoklopsi",
	version = "1.3.0",
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
	}
}



// Add the feature
public OnAllPluginsLoaded()
{
	decl String:description[64];
	decl String:path[PLATFORM_MAX_PATH + 1];


	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
	{
		SetFailState("Can't Load Feature, not Supported for your game!");
	}


	STAMM_LoadTranslation();
		
	Format(description, sizeof(description), "%T", "GetWeapons", LANG_SERVER);
	
	STAMM_AddFeature("VIP Weapons", description);


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
	kv = CreateKeyValues("WeaponSettings");
	FileToKeyValues(kv, path);
	
	// Maxium gives
	maximum = KvGetNum(kv, "maximum");
	
	// Create Menu
	weaponlist = CreateMenu(weaponlist_handler);
	SetMenuTitle(weaponlist, "!sgive <weapon_name>");
	

	// Parse config
	if (KvGotoFirstSubKey(kv, false))
	{
		decl String:buffer[120];
		decl String:buffer2[120];

		do
		{
			// Get Weaponname
			KvGetSectionName(kv, buffer, sizeof(buffer));

			strcopy(buffer2, sizeof(buffer2), buffer);

			// Replace weapon_ tag
			ReplaceString(buffer, sizeof(buffer), "weapon_", "");

			// And go back
			KvGoBack(kv);
			
			//  Get status of weapon
			if (!StrEqual(buffer2, "maximum") && KvGetNum(kv, buffer2) == 1) 
			{
				AddMenuItem(weaponlist, buffer, buffer);
			}


			KvJumpToKey(kv, buffer2);
		} 
		while (KvGotoNextKey(kv, false));

		// Go Back
		KvRewind(kv);
	}
}



// Load the configs
public OnPluginStart()
{
	// Good colors :)
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



	// Register commands
	RegConsoleCmd("sm_sgive", GiveCallback, "Give VIP's Weapons");
	RegConsoleCmd("sm_sweapons", InfoCallback, "show Weaponlist");
	
	HookEvent("round_start", RoundStart);
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
		Usages[x] = 0;
	}
}



// Also reset usages
public STAMM_OnClientReady(client)
{
	Usages[client] = 0;
}




// Open weapon menu
public Action:InfoCallback(client, args)
{
	if (STAMM_IsClientValid(client) && STAMM_HaveClientFeature(client))
	{
		DisplayMenu(weaponlist, client, 30);
	}

	return Plugin_Handled;
}




// Give a weapon
public Action:GiveCallback(client, args)
{
	decl String:tag[64];


	if (GetCmdArgs() == 1)
	{
		if (STAMM_IsClientValid(client))
		{
			if (STAMM_HaveClientFeature(client) && IsPlayerAlive(client))
			{
				// max. usages not reached
				if (Usages[client] < maximum)
				{
					decl String:WeaponName[64];
					
					GetCmdArg(1, WeaponName, sizeof(WeaponName));
					STAMM_GetTag(tag, sizeof(tag));


					// Add weapon tag
					Format(WeaponName, sizeof(WeaponName), "weapon_%s", WeaponName);


					// Enabled?
					if (KvGetNum(kv, WeaponName))
					{
						// Give Item
						GivePlayerItem(client, WeaponName);
						
						Usages[client]++;
					}


					else 
					{
						if (STAMM_GetGame() == GameCSGO)
						{
							CPrintToChat(client, "%s %T", tag, "WeaponFailed");
						}
						else
						{
							MCPrintToChat(client, "%s %T", tag, "WeaponFailed");
						}
					}
				}
				
				else
				{
					if (STAMM_GetGame() == GameCSGO)
					{
						CPrintToChat(client, "%s %T", tag, "MaximumReached");
					}
					else
					{
						MCPrintToChat(client, "%s %T", tag, "MaximumReached");
					}
				}
			}
		}
	}

	return Plugin_Handled;
}