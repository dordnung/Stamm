/**
 * -----------------------------------------------------
 * File        stamm_tf2_items.sp
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

#undef REQUIRE_EXTENSIONS
#include <tf2items>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>
#include <tf2itemsinfo>

#pragma semicolon 1






public Plugin:myinfo =
{
	name = "Stamm Feature TF2 Items",
	author = "Popoklopsi",
	version = "1.0.1",
	description = "Give VIP's Attributes on Items",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




enum ItemInfos
{
	ITEM_BLOCK,
	ITEM_ATTRIBUTE,
	Float:ITEM_VALUE,
	String:ITEM_DESC[128],
	Handle:ITEM_CLASS,
	Handle:ITEM_ID,
	Handle:ITEM_SLOT
}



new g_Items[STAMM_MAX_LEVELS][ItemInfos];
new g_iItemCount;




// Add feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
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


	// We need tf2itemsinfo
	if (!LibraryExists("tf2itemsinfo"))
	{
		SetFailState("Can't Load Feature, you need to install tf2itemsinfo!");
	}


	STAMM_RegisterFeature("VIP TF2 Items");
	LoadItems();
}






LoadItems()
{
	g_iItemCount = 0;

	if (!FileExists("cfg/stamm/features/items_tf2.txt"))
	{
		SetFailState("Couldn't load TF2 Items. items_tf2.txt missing.");
	}

	new Handle:kvalue = CreateKeyValues("stamm_items");

	FileToKeyValues(kvalue, "cfg/stamm/features/items_tf2.txt");



	// Key value loop
	if (KvGotoFirstSubKey(kvalue))
	{
		new found;
		decl String:class[4096];
		decl String:definition[256];
		decl String:slot[128];
		decl String:section[64];
		decl String:buffer[128][32];

		do
		{
			KvGetSectionName(kvalue, section, sizeof(section));

			if (STAMM_GetBlockOfName(section) < 1)
			{
				STAMM_WriteToLog(false, "Couldn't find block '%s'", section);

				continue;
			}


			g_Items[g_iItemCount][ITEM_BLOCK] = STAMM_GetBlockOfName(section);

			g_Items[g_iItemCount][ITEM_ATTRIBUTE] = KvGetNum(kvalue, "attribute");
			g_Items[g_iItemCount][ITEM_VALUE] = KvGetFloat(kvalue, "value");

			KvGetString(kvalue, "description", g_Items[g_iItemCount][ITEM_DESC], 128);
			KvGetString(kvalue, "class", class, sizeof(class));
			KvGetString(kvalue, "definition", definition, sizeof(definition));
			KvGetString(kvalue, "slot", slot, sizeof(slot));


			STAMM_WriteToLog(true, "Found block %s(%i) with values: (%i, %.1f, %s, %s, %s, %s)", section, g_Items[g_iItemCount][ITEM_BLOCK], g_Items[g_iItemCount][ITEM_ATTRIBUTE], g_Items[g_iItemCount][ITEM_VALUE], g_Items[g_iItemCount][ITEM_DESC], class, definition, slot);


			if (strlen(class) > 1)
			{
				g_Items[g_iItemCount][ITEM_CLASS] = CreateArray(32);

				found = ExplodeString(class, ",", buffer, sizeof(buffer), sizeof(buffer[]));

				while (found > 0)
				{
					PushArrayString(g_Items[g_iItemCount][ITEM_CLASS], buffer[found-1]);

					found--;
				}
			}
			else
			{
				g_Items[g_iItemCount][ITEM_CLASS] = INVALID_HANDLE;
			}


			if (strlen(definition) > 1)
			{
				g_Items[g_iItemCount][ITEM_ID] = CreateArray(32);

				found = ExplodeString(definition, ",", buffer, sizeof(buffer), sizeof(buffer[]));

				while (found > 0)
				{
					PushArrayString(g_Items[g_iItemCount][ITEM_ID], buffer[found-1]);

					found--;
				}
			}
			else
			{
				g_Items[g_iItemCount][ITEM_ID] = INVALID_HANDLE;
			}


			if (strlen(slot) > 1)
			{
				g_Items[g_iItemCount][ITEM_SLOT] = CreateArray(32);

				found = ExplodeString(slot, ",", buffer, sizeof(buffer), sizeof(buffer[]));

				while (found > 0)
				{
					PushArrayString(g_Items[g_iItemCount][ITEM_SLOT], buffer[found-1]);

					found--;
				}
			}
			else
			{
				g_Items[g_iItemCount][ITEM_SLOT] = INVALID_HANDLE;
			}


			// One attribute more
			g_iItemCount++;
		}
		while (KvGotoNextKey(kvalue));
	}
	

	CloseHandle(kvalue);
}






// Add to auto updater and set description
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







// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	for (new i=0; i < g_iItemCount; i++)
	{
		if (g_Items[i][ITEM_BLOCK] == block)
		{
			PushArrayString(array, g_Items[i][ITEM_DESC]);
		}
	}
}







// A Item gived to player
public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	decl String:buffer[32];
	new attributes = 0;
	new bool:isValid;

	if (STAMM_IsClientValid(client))
	{
		for (new i=0; i < g_iItemCount; i++)
		{
			if (STAMM_HaveClientFeature(client, g_Items[i][ITEM_BLOCK]))
			{
				// Class have to be correct
				if (g_Items[i][ITEM_CLASS] != INVALID_HANDLE)
				{
					isValid = false;

					for (new j=0; j < GetArraySize(g_Items[i][ITEM_CLASS]); j++)
					{
						GetArrayString(g_Items[i][ITEM_CLASS], j, buffer, sizeof(buffer));

						if (StrEqual(buffer, classname, false))
						{
							isValid = true;

							break;
						}
					}

					if (!isValid)
					{
						continue;
					}
				}


				// ID has to be correct
				if (g_Items[i][ITEM_ID] != INVALID_HANDLE)
				{
					isValid = false;

					for (new j=0; j < GetArraySize(g_Items[i][ITEM_ID]); j++)
					{
						GetArrayString(g_Items[i][ITEM_ID], j, buffer, sizeof(buffer));

						if (iItemDefinitionIndex == StringToInt(buffer))
						{
							isValid = true;

							break;
						}
					}

					if (!isValid)
					{
						continue;
					}
				}


				// Slot has to be correct
				if (g_Items[i][ITEM_SLOT] != INVALID_HANDLE)
				{
					new TF2ItemSlot:slot = TF2II_GetItemSlot(iItemDefinitionIndex, TF2_GetPlayerClass(client));
					isValid = false;

					for (new j=0; j < GetArraySize(g_Items[i][ITEM_SLOT]); j++)
					{
						GetArrayString(g_Items[i][ITEM_SLOT], j, buffer, sizeof(buffer));

						if (_:slot == StringToInt(buffer))
						{
							isValid = true;

							break;
						}
					}

					if (!isValid)
					{
						continue;
					}
				}

				// Create new item
				if (attributes < 1)
				{
					hItem = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES);
				}

				// Set new attribute
				TF2Items_SetAttribute(hItem, attributes, g_Items[i][ITEM_ATTRIBUTE], g_Items[i][ITEM_VALUE]);
					
				// Override old
				TF2Items_SetNumAttributes(hItem, attributes++);
			}
		}
	}
	
	if (attributes > 0)
	{
		return Plugin_Changed;
	}
		
	return Plugin_Continue;
}