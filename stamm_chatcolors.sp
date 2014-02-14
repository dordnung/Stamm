/**
 * -----------------------------------------------------
 * File        stamm_chatcolors.sp
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
#include <clientprefs>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#undef COLOR_GREEN
#include <ccc>

#include <scp>

#pragma semicolon 1






public Plugin:myinfo =
{
	name = "Stamm Feature Chat Colors",
	author = "Popoklopsi",
	version = "1.0.0",
	description = "Give VIP's a own chat color and chat tag",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




enum ChatColors
{
	bool:COLOR_TAG,
	COLOR_BLOCK,
	String:COLOR_NAME[32],
	String:COLOR_STRING[32],
}



new g_Colors[256][ChatColors];
new g_iColorCount;

new Handle:g_hClientCookieName;
new Handle:g_hClientCookieColor;
new Handle:g_hClientCookieTag;

new g_iClientColor[MAXPLAYERS + 1][3];






// CCC doesn't mark CCC_SetTag as optional
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("CCC_SetTag");

	return APLRes_Success;
}




// Add feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	if (STAMM_GetGame() == GameCSGO) 
	{
		SetFailState("Can't Load Feature, not Supported for your game!");
	}


	RegConsoleCmd("sm_ctag", OnTag, "Choose a chat tag");
	RegConsoleCmd("sm_ccolor", OnColor, "Choose a chat color");
	RegConsoleCmd("sm_cname", OnName, "Choose a chat name color");


	g_hClientCookieColor = RegClientCookie("Stamm_Chat_Color", "Stamm Chat Color", CookieAccess_Private);
	g_hClientCookieTag = RegClientCookie("Stamm_Chat_Tag", "Stamm Chat Tag", CookieAccess_Private);
	g_hClientCookieName = RegClientCookie("Stamm_Chat_Name", "Stamm Chat Name", CookieAccess_Private);


	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP Chat Colors");
	LoadColors();
}






LoadColors()
{
	g_iColorCount = 0;


	if (!FileExists("cfg/stamm/features/chatcolors.txt"))
	{
		SetFailState("Couldn't load Chat colors. chatcolors.txt missing.");
	}

	new Handle:kvalue = CreateKeyValues("chatcolors");

	FileToKeyValues(kvalue, "cfg/stamm/features/chatcolors.txt");


	if (KvJumpToKey(kvalue, "colors"))
	{
		// Key value loop
		if (KvGotoFirstSubKey(kvalue))
		{
			decl String:block[32];

			do
			{
				KvGetString(kvalue, "block", block, sizeof(block));

				if (STAMM_GetBlockOfName(block) < 1)
				{
					STAMM_WriteToLog(false, "Couldn't find block '%s'", block);

					continue;
				}


				g_Colors[g_iColorCount][COLOR_TAG] = false;
				g_Colors[g_iColorCount][COLOR_BLOCK] = STAMM_GetBlockOfName(block);

				KvGetSectionName(kvalue, g_Colors[g_iColorCount][COLOR_NAME], 32);
				KvGetString(kvalue, "color", g_Colors[g_iColorCount][COLOR_STRING], 32);


				STAMM_WriteToLog(true, "Found block %s(%i) with values: (%i, %s, %s)", block, g_Colors[g_iColorCount][COLOR_BLOCK], g_Colors[g_iColorCount][COLOR_TAG], g_Colors[g_iColorCount][COLOR_NAME], g_Colors[g_iColorCount][COLOR_STRING]);


				g_iColorCount++;
			}
			while (KvGotoNextKey(kvalue));
		}
	}


	KvRewind(kvalue);


	if (KvJumpToKey(kvalue, "tags"))
	{
		// Key value loop
		if (KvGotoFirstSubKey(kvalue, false))
		{
			decl String:block[32];

			do
			{
				KvGetString(kvalue, NULL_STRING, block, sizeof(block));

				if (STAMM_GetBlockOfName(block) < 1)
				{
					STAMM_WriteToLog(false, "Couldn't find block '%s'", block);

					continue;
				}


				g_Colors[g_iColorCount][COLOR_TAG] = true;
				g_Colors[g_iColorCount][COLOR_BLOCK] = STAMM_GetBlockOfName(block);

				KvGetSectionName(kvalue, g_Colors[g_iColorCount][COLOR_STRING], 32);


				STAMM_WriteToLog(true, "Found block %s(%i) with values: (%i, %s)", block, g_Colors[g_iColorCount][COLOR_BLOCK], g_Colors[g_iColorCount][COLOR_TAG], g_Colors[g_iColorCount][COLOR_STRING]);


				g_iColorCount++;
			}
			while (KvGotoNextKey(kvalue, false));
		}
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
	}
}







// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	new bool:foundTag = false;
	new bool:foundColor = false;
	decl String:buffer[128];

	for (new i=0; i < g_iColorCount; i++)
	{
		if (g_Colors[i][COLOR_BLOCK] == block)
		{
			if (g_Colors[i][COLOR_TAG] && !foundTag)
			{
				foundTag = true;

				Format(buffer, sizeof(buffer), "%T", "CanChooseTag", client);

				PushArrayString(array, buffer);
			}
			else if (!g_Colors[i][COLOR_TAG] && !foundColor)
			{
				foundColor = true;

				Format(buffer, sizeof(buffer), "%T", "CanChooseColor", client);

				PushArrayString(array, buffer);
			}
		}
	}
}





// Adding Commands
public STAMM_OnClientRequestCommands(client)
{
	STAMM_AddCommand("!ccolor", "%T", "CommandColor", client);
	STAMM_AddCommand("!ctag", "%T", "CommandTag", client);
	STAMM_AddCommand("!cname", "%T", "CommandName", client);
}





// Cookies cached
public OnClientCookiesCached(client)
{
	decl String:buffer[32];

	if (STAMM_IsClientValid(client) && AreClientCookiesCached(client))
	{
		GetClientCookie(client, g_hClientCookieColor, buffer, sizeof(buffer));

		if (strlen(buffer) > 0 && STAMM_HaveClientFeature(client, g_Colors[StringToInt(buffer)][COLOR_BLOCK]))
		{
			g_iClientColor[client][0] = StringToInt(buffer);

			if (LibraryExists("ccc"))
			{
				CCC_SetColor(client, CCC_ChatColor, StringToInt(g_Colors[g_iClientColor[client][0]][COLOR_STRING], 16), false);
			}
		}
		else
		{
			g_iClientColor[client][0] = -1;
		}


		GetClientCookie(client, g_hClientCookieTag, buffer, sizeof(buffer));

		if (strlen(buffer) > 0 && STAMM_HaveClientFeature(client, g_Colors[StringToInt(buffer)][COLOR_BLOCK]))
		{
			g_iClientColor[client][1] = StringToInt(buffer);

			if (LibraryExists("ccc"))
			{
				CCC_SetTag(client, g_Colors[g_iClientColor[client][1]][COLOR_STRING]);
			}
		}
		else
		{
			g_iClientColor[client][1] = -1;
		}


		GetClientCookie(client, g_hClientCookieName, buffer, sizeof(buffer));

		if (strlen(buffer) > 0 && STAMM_HaveClientFeature(client, g_Colors[StringToInt(buffer)][COLOR_BLOCK]))
		{
			g_iClientColor[client][2] = StringToInt(buffer);

			if (LibraryExists("ccc"))
			{
				CCC_SetColor(client, CCC_NameColor, StringToInt(g_Colors[g_iClientColor[client][2]][COLOR_STRING], 16), false);
			}
		}
		else
		{
			g_iClientColor[client][2] = -1;
		}
	}
}






// Get client information
public STAMM_OnClientReady(client)
{
	OnClientCookiesCached(client);
}





// Client Got load
public CCC_OnUserConfigLoaded(client)
{
	OnClientCookiesCached(client);
}




// client typed something, now change the colors
public Action:OnChatMessage(&author, Handle:recipients, String:name[], String:message[])
{
	if (LibraryExists("ccc"))
	{
		return Plugin_Continue;
	}


	decl String:sTitle[64];
	new bool:found = false;

	if (g_iClientColor[author][1] != -1)
	{

		Format(sTitle, sizeof(sTitle), "%s \x03", g_Colors[g_iClientColor[author][1]][COLOR_STRING]);
		found = true;
	}
	else
	{
		strcopy(sTitle, sizeof(sTitle), "");
	}


	if (g_iClientColor[author][2] != -1)
	{
		Format(name, MAXLENGTH_NAME, "%s\x07%s%s", sTitle, g_Colors[g_iClientColor[author][2]][COLOR_STRING], name);
		found = true;
	}

	else if (g_iClientColor[author][1] != -1)
	{
		Format(name, MAXLENGTH_NAME, "%s%s", sTitle, name);
		found = true;
	}
	

	if (g_iClientColor[author][0] != -1)
	{
		new iMax = MAXLENGTH_MESSAGE - strlen(name) - 5;
		found = true;

		Format(message, iMax, "\x07%s%s", g_Colors[g_iClientColor[author][0]][COLOR_STRING], message);
	}


	if (found)
	{
		return Plugin_Changed;
	}
	else
	{
		return Plugin_Continue;
	}
}





public Action:OnTag(client, args)
{
	if (STAMM_IsClientValid(client))
	{
		decl String:buffer[32];

		new bool:found = false;
		new Handle:menu = CreateMenu(OnChooseTag);

		for (new i=0; i < g_iColorCount; i++)
		{
			if (g_Colors[i][COLOR_TAG] && STAMM_HaveClientFeature(client, g_Colors[i][COLOR_BLOCK]))
			{
				IntToString(i, buffer, sizeof(buffer));

				AddMenuItem(menu, buffer, g_Colors[i][COLOR_STRING]);

				found = true;
			}
		}

		if (found)
		{
			DisplayMenu(menu, client, 40);
		}
		else
		{
			decl String:tag[64];

			STAMM_GetTag(tag, sizeof(tag));

			STAMM_PrintToChat(client, "%s %t", tag, "denied");
		}
	}

	return Plugin_Handled;
}





public Action:OnColor(client, args)
{
	if (STAMM_IsClientValid(client))
	{
		decl String:buffer[32];

		new bool:found = false;
		new Handle:menu = CreateMenu(OnChooseColor);

		for (new i=0; i < g_iColorCount; i++)
		{
			if (!g_Colors[i][COLOR_TAG] && STAMM_HaveClientFeature(client, g_Colors[i][COLOR_BLOCK]))
			{
				IntToString(i, buffer, sizeof(buffer));

				AddMenuItem(menu, buffer, g_Colors[i][COLOR_NAME]);

				found = true;
			}
		}

		if (found)
		{
			DisplayMenu(menu, client, 40);
		}
		else
		{
			decl String:tag[64];

			STAMM_GetTag(tag, sizeof(tag));

			STAMM_PrintToChat(client, "%s %t", tag, "denied");
		}
	}

	return Plugin_Handled;
}





public Action:OnName(client, args)
{
	if (STAMM_IsClientValid(client))
	{
		decl String:buffer[32];

		new bool:found = false;
		new Handle:menu = CreateMenu(OnChooseName);

		for (new i=0; i < g_iColorCount; i++)
		{
			if (!g_Colors[i][COLOR_TAG] && STAMM_HaveClientFeature(client, g_Colors[i][COLOR_BLOCK]))
			{
				IntToString(i, buffer, sizeof(buffer));

				AddMenuItem(menu, buffer, g_Colors[i][COLOR_NAME]);

				found = true;
			}
		}

		if (found)
		{
			DisplayMenu(menu, client, 40);
		}
		else
		{
			decl String:tag[64];

			STAMM_GetTag(tag, sizeof(tag));

			STAMM_PrintToChat(client, "%s %t", tag, "denied");
		}
	}

	return Plugin_Handled;
}




public OnChooseTag(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:buf[32];

		if (STAMM_IsClientValid(param1))
		{
			GetMenuItem(menu, param2, buf, sizeof(buf));


			g_iClientColor[param1][1] = StringToInt(buf);

			SetClientCookie(param1, g_hClientCookieTag, buf);


			if (LibraryExists("ccc"))
			{
				CCC_SetTag(param1, g_Colors[StringToInt(buf)][COLOR_STRING]);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}




public OnChooseName(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:buf[32];

		if (STAMM_IsClientValid(param1))
		{
			GetMenuItem(menu, param2, buf, sizeof(buf));


			g_iClientColor[param1][2] = StringToInt(buf);

			SetClientCookie(param1, g_hClientCookieName, buf);


			if (LibraryExists("ccc"))
			{
				CCC_SetColor(param1, CCC_NameColor, StringToInt(g_Colors[StringToInt(buf)][COLOR_STRING], 16), false);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}




public OnChooseColor(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:buf[32];

		if (STAMM_IsClientValid(param1))
		{
			GetMenuItem(menu, param2, buf, sizeof(buf));


			g_iClientColor[param1][0] = StringToInt(buf);

			SetClientCookie(param1, g_hClientCookieColor, buf);


			if (LibraryExists("ccc"))
			{
				CCC_SetColor(param1, CCC_ChatColor, StringToInt(g_Colors[StringToInt(buf)][COLOR_STRING], 16), false);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}