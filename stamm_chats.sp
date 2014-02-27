/**
 * -----------------------------------------------------
 * File        stamm_chats.sp
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
#include <scp>
#include <updater>

#pragma semicolon 1



new Handle:g_hNeedTag;

new g_iMessages;
new g_iChat;




public Plugin:myinfo =
{
	name = "Stamm Feature Chats",
	author = "Popoklopsi",
	version = "1.3.0",
	description = "Give VIP's welcome and leave message",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};



// Add Feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	if (!LibraryExists("scp"))
	{
		SetFailState("Can't Load Feature, Simple Chat Processor is not installed!");
	}


	// Load	
	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP Chats");
}




// Add to auto updater and make descriptions
public STAMM_OnFeatureLoaded(const String:basename[])
{
	decl String:urlString[256];



	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);	
	}



	// Get block of messages
	g_iMessages = STAMM_GetBlockOfName("messages");
	g_iChat = STAMM_GetBlockOfName("chat");


	if (g_iMessages == -1 && g_iChat == -1)
	{
		SetFailState("Found neither block messages nor block chat!");
	}
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	if (block == g_iMessages)
	{
		if (GetConVarBool(g_hNeedTag))
		{
			Format(fmt, sizeof(fmt), "%T", "Activate", client, "*");
			Format(fmt, sizeof(fmt), "%T", "GetVIPMessage", client, fmt);
		}
		else
		{
			Format(fmt, sizeof(fmt), "%T", "GetVIPMessage", client, "");
		}
		
		PushArrayString(array, fmt);
	}

	if (block == g_iChat)
	{
		Format(fmt, sizeof(fmt), "%T", "GetVIPChat", client);
		
		PushArrayString(array, fmt);
	}
}




// Create the config
public OnPluginStart()
{
	AutoExecConfig_SetFile("chats", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hNeedTag = AutoExecConfig_CreateConVar("chats_needtag", "1", "1 = Player have to write * at the start of the message to activate a VIP message, 0 = Off");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();


	RegConsoleCmd("say", CmdSay);
}





// Playe said something
public Action:OnChatMessage(&author, Handle:recipients, String:name[], String:message[])
{
	decl String:tag[64];
	decl String:nameBackup[MAXLENGTH_NAME];
	decl String:messageBackup[MAXLENGTH_MESSAGE];


	STAMM_GetTag(tag, sizeof(tag));
	


	// Client valid?
	if (STAMM_IsClientValid(author))
	{
		strcopy(nameBackup, sizeof(nameBackup), name);
		strcopy(messageBackup, sizeof(messageBackup), message);


		if (!GetConVarBool(g_hNeedTag))
		{
			if (!STAMM_WantClientFeature(author))
			{
				return Plugin_Continue;
			}

			// Can write VIP message?
			if (g_iMessages != -1 && STAMM_HaveClientFeature(author, g_iMessages))
			{
				// print according to Team
				Format(name, MAXLENGTH_NAME, "%t", "VIPMessageName", nameBackup);
				STAMM_FormatColor(name, MAXLENGTH_NAME, author);

				Format(message, MAXLENGTH_MESSAGE, "%t", "VIPMessage", messageBackup);
				STAMM_FormatColor(message, MAXLENGTH_MESSAGE, author);

				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}





// Playe said something
public Action:CmdSay(client, args)
{
	if (!STAMM_IsClientValid(client))
	{
		return Plugin_Continue;
	}

	decl String:text[128];
	decl String:tag[64];
	decl String:name[64];


	GetCmdArgString(text, sizeof(text));
	GetClientName(client, name, sizeof(name));

	STAMM_GetTag(tag, sizeof(tag));
	ReplaceString(text, sizeof(text), "\"", "");


	if (GetConVarBool(g_hNeedTag) && text[0] == '*' && !StrEqual(text, "*", false))
	{
		ReplaceString(text, sizeof(text), "*", "");

		if (!STAMM_WantClientFeature(client))
		{
			STAMM_PrintToChat(client, "%s %t", tag, "FeatureDisabled");

			return Plugin_Continue;
		}


		// Can write VIP message?
		if (g_iMessages != -1 && STAMM_HaveClientFeature(client, g_iMessages))
		{
			for (new i=1; i <= MaxClients; i++)
			{
				if (STAMM_IsClientValid(i))
				{
					STAMM_PrintToChatEx(i, client, "%t{default} :  %t", "VIPMessageName", name, "VIPMessage", text);
				}
			}

			return Plugin_Handled;
		}
	}

	// Found tag?
	else if (text[0] == '#' && !StrEqual(text, "#", false))
	{
		ReplaceString(text, sizeof(text), "#", "");

		// Want feature?
		if (!STAMM_WantClientFeature(client))
		{
			STAMM_PrintToChat(client, "%s %t", tag, "FeatureDisabled");

			return Plugin_Continue;
		}


		if (g_iChat != -1 && STAMM_HaveClientFeature(client, g_iChat))
		{
			// Print to all VIP's
			for (new i=1; i <= MaxClients; i++)
			{
				if (STAMM_IsClientValid(i))
				{
					// Client have feature
					if (STAMM_HaveClientFeature(i, g_iChat))
					{
						// Print according to team
						STAMM_PrintToChatEx(i, client, "%t{default} :  %t", "VIPChatName", name, "VIPChat", text);
					}
				}
			}

			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}