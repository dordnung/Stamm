/**
 * -----------------------------------------------------
 * File        stamm_high_firingrate.sp
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
#include <tf2items>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1




new firerate;
new Handle:c_firerate;




public Plugin:myinfo =
{
	name = "Stamm Feature Higher Firing Rate",
	author = "Popoklopsi",
	version = "1.0.2",
	description = "Give VIP's higher firing Rate",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};



// Add feature
public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	if (STAMM_GetGame() != GameTF2) 
	{
		SetFailState("Can't Load Feature, not Supported for your game!");
	}


	// We need tf2items
	if (GetExtensionFileStatus("tf2items.ext") != 1)
	{
		SetFailState("Can't Load Feature, you need to install tf2items!");
	}



	STAMM_LoadTranslation();
	STAMM_AddFeature("VIP Higher Firing Rate", "");
}




// Create config
public OnPluginStart()
{
	AutoExecConfig_SetFile("higher_firingrate", "stamm/features");
	
	c_firerate = AutoExecConfig_CreateConVar("firing_rate", "10", "Firing rate increase in percent each block!");
	
	AutoExecConfig(true, "higher_firingrate", "stamm/features");
	AutoExecConfig_CleanFile();
}



// Load config
public OnConfigsExecuted()
{
	firerate = GetConVarInt(c_firerate);
}



// Add to auto updater and set description
public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:haveDescription[64];
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
	}


	// Description for each block	
	for (new i=1; i <= STAMM_GetBlockCount(); i++)
	{
		Format(haveDescription, sizeof(haveDescription), "%T", "GetHigherFiringRate", LANG_SERVER, firerate * i);
		
		STAMM_AddFeatureText(STAMM_GetLevel(i), haveDescription);
	}
}




// A Item gived to player
public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	new bool:change = false;
	
	if (STAMM_IsClientValid(client) && IsPlayerAlive(client))
	{
		// Get highest client block
		new clientBlock = STAMM_GetClientBlock(client);


		// Have client block
		if (clientBlock > 0)
		{
			// Create new item
			hItem = TF2Items_CreateItem(OVERRIDE_ALL);
			
			TF2Items_SetItemIndex(hItem, -1);

			new Float:newFire = 1.0 - float(firerate)/100.0 * clientBlock;


			if (newFire < 0.1)
			{
				newFire = 0.1;
			}


			// Set new firing rate of item
			TF2Items_SetAttribute(hItem, 0, 6, newFire);
				
			// Override old
			TF2Items_SetNumAttributes(hItem, 1);
			TF2Items_SetFlags(hItem, OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES);
			
			change = true;
		}
	}
	
	if (change)
	{
		return Plugin_Changed;
	}
		
	return Plugin_Continue;
}