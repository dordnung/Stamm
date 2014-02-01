/**
 * -----------------------------------------------------
 * File        stamm_chats.sp
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
#include <sourcecomms>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1




new Handle:g_hMessageTag;
new Handle:g_hOwnChatTag;
new Handle:g_hNeedTag;
new String:g_sMessageFile[PLATFORM_MAX_PATH + 1];
new String:g_sChatFile[PLATFORM_MAX_PATH + 1];
new String:smFolder[PLATFORM_MAX_PATH + 1];
new String:CurrentDate[20];

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

	BuildPath(Path_SM, smFolder, sizeof(smFolder), "logs");
	FormatTime(CurrentDate, sizeof(CurrentDate), "%d-%m-%y");

	Format(g_sMessageFile, sizeof(g_sMessageFile), "%s/stamm_message_(%s).log", smFolder, CurrentDate);
	Format(g_sChatFile, sizeof(g_sChatFile), "%s/stamm_chat_(%s).log", smFolder, CurrentDate);

	// Load	
	STAMM_LoadTranslation();
	STAMM_AddFeature("VIP Chats");
}




// Add to auto updater and make descriptions
public STAMM_OnFeatureLoaded(const String:basename[])
{
	decl String:activate[64];
	decl String:urlString[256];



	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);	
	}



	// Get block of messages
	g_iMessages = STAMM_GetBlockOfName("messages");
	g_iChat = STAMM_GetBlockOfName("chat");



	// Found a valid block?
	if (g_iMessages != -1)
	{
		if (GetConVarBool(g_hNeedTag))
		{
			Format(activate, sizeof(activate), "%T", "Activate", LANG_SERVER, "*");

			STAMM_AddBlockDescription(g_iMessages, "%T", "GetVIPMessage", LANG_SERVER, activate);
		}
		else
		{
			STAMM_AddBlockDescription(g_iMessages, "%T", "GetVIPMessage", LANG_SERVER, "");
		}
	}	


	// Found valid block?
	if (g_iChat != -1)
	{
		STAMM_AddBlockDescription(g_iChat, "%T", "GetVIPChat", LANG_SERVER);
	}


	if (g_iMessages == -1 && g_iChat == -1)
	{
		SetFailState("Found neither block messages nor block chat!");
	}
}




// Create the config
public OnPluginStart()
{
	AutoExecConfig_SetFile("chats", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hMessageTag = AutoExecConfig_CreateConVar("chats_messagetag", "VIP Message", "Tag when a player writes something as a VIP");
	g_hOwnChatTag = AutoExecConfig_CreateConVar("chats_ownchattag", "VIP Chat", "Tag when a player writes something in the VIP Chat");
	g_hNeedTag = AutoExecConfig_CreateConVar("chats_needtag", "1", "1 = Player have to write * at the start of the message to activate a VIP message, 0 = Off");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
	

	RegConsoleCmd("say", CmdSay);
}





// Playe said something
public Action:CmdSay(client, args)
{
	decl String:text[128];
	decl String:name[MAX_NAME_LENGTH+1];
	decl String:tag[64];
	decl String:messageTag[32];
	decl String:ownChatTag[32];


	GetClientName(client, name, sizeof(name));

	GetCmdArgString(text, sizeof(text));

	GetConVarString(g_hMessageTag, messageTag, sizeof(messageTag));
	GetConVarString(g_hOwnChatTag, ownChatTag, sizeof(ownChatTag));


	STAMM_GetTag(tag, sizeof(tag));

	ReplaceString(text, sizeof(text), "\"", "");
	


	// Client valid?
	if (STAMM_IsClientValid(client) && SourceComms_GetClientGagType(client) == bNot)
	{
		// Can write VIP message?
		if (g_iMessages != -1 && STAMM_HaveClientFeature(client, g_iMessages))
		{
			if (!GetConVarBool(g_hNeedTag) || (FindCharInString(text, '*') == 0 && !StrEqual(text, "*", false)))
			{
				if (GetConVarBool(g_hNeedTag))
				{
					// Want feature?
					if (!STAMM_WantClientFeature(client))
					{
						STAMM_PrintToChat(client, "%s %t", tag, "FeatureDisabled");

						return Plugin_Continue;
					}

					ReplaceString(text, sizeof(text), "*", "");
				}


				// print according to Team
				if (GetClientTeam(client) == 2 && SourceComms_GetClientGagType(client) == bNot) 
				{
					STAMM_PrintToChatAll("{red}[%s] {green}%s:{red} %s", messageTag, name, text);
					LogToFile(g_sMessageFile, "\"%L\" executes: say %s", client, text);
				}

				else if (GetClientTeam(client) == 3 && SourceComms_GetClientGagType(client) == bNot) 
				{
					STAMM_PrintToChatAll("{blue}[%s] {green}%s:{blue} %s", messageTag, name, text);
					LogToFile(g_sMessageFile, "\"%L\" executes: say %s", client, text);
				}

				else if (SourceComms_GetClientGagType(client) == bNot)
				{
					STAMM_PrintToChatAll("{lightgreen}[%s] {green}%s:{lightgreen} %s", messageTag, name, text);
					LogToFile(g_sMessageFile, "\"%L\" executes: say %s", client, text);
				}

				return Plugin_Handled;
			}
		}

		// Can write to vip chat?
		if (g_iChat != -1 && STAMM_HaveClientFeature(client, g_iChat))
		{
			// Found tag?
			if (FindCharInString(text, '#') == 0 && !StrEqual(text, "#", false))
			{
				ReplaceString(text, sizeof(text), "#", "");


				// Want feature?
				if (!STAMM_WantClientFeature(client))
				{
					STAMM_PrintToChat(client, "%s %t", tag, "FeatureDisabled");

					return Plugin_Continue;
				}


				// Print to all VIP's
				for (new i=1; i <= MaxClients; i++)
				{
					if (STAMM_IsClientValid(i))
					{
						// Client have feature
						if (STAMM_HaveClientFeature(i, g_iChat))
						{
							// Print according to team
							if (GetClientTeam(i) == 2 && SourceComms_GetClientGagType(client) == bNot) 
							{
								STAMM_PrintToChat(i, "{red}[%s] {green}%s:{red} %s", ownChatTag, name, text);
								LogToFile(g_sChatFile, "\"%L\" executes: say %s", client, text);
							}
							
							else if (GetClientTeam(i) == 3 && SourceComms_GetClientGagType(client) == bNot) 
							{
								STAMM_PrintToChat(i, "{blue}[%s] {green}%s:{blue} %s", ownChatTag, name, text);
								LogToFile(g_sChatFile, "\"%L\" executes: say %s", client, text);
							}

							else if(SourceComms_GetClientGagType(client) == bNot)
							{
								STAMM_PrintToChat(i, "{lightgreen}[%s] {green}%s:{lightgreen} %s", ownChatTag, name, text);
								LogToFile(g_sChatFile, "\"%L\" executes: say %s", client, text);
							}
						}
					}
				}
				
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}
