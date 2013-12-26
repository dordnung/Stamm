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
#include <colors>
#include <morecolors_stamm>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1




new Handle:c_MessageTag;
new Handle:c_OwnChatTag;
new Handle:c_NeedTag;

new String:MessageTag[32];
new String:OwnChatTag[32];
new NeedTag;

new messages;
new chat;




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
	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}


	// Cool colors :)
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
	messages = STAMM_GetBlockOfName("messages");
	chat = STAMM_GetBlockOfName("chat");



	// Found a valid block?
	if (messages != -1)
	{
		if (NeedTag)
		{
			Format(activate, sizeof(activate), "%T", "Activate", LANG_SERVER, "*");

			STAMM_AddBlockDescription(messages, "%T", "GetVIPMessage", LANG_SERVER, activate);
		}
		else
		{
			STAMM_AddBlockDescription(messages, "%T", "GetVIPMessage", LANG_SERVER, "");
		}
	}	

	// Found valid block?
	if (chat != -1)
	{
		Format(activate, sizeof(activate), "%T", "Activate", LANG_SERVER, "#");

		STAMM_AddBlockDescription(chat, "%T", "GetVIPChat", LANG_SERVER, activate);
	}
}




// Create the config
public OnPluginStart()
{
	AutoExecConfig_SetFile("chats", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	c_MessageTag = AutoExecConfig_CreateConVar("chats_messagetag", "VIP Message", "Tag when a player writes something as a VIP");
	c_OwnChatTag = AutoExecConfig_CreateConVar("chats_ownchattag", "VIP Chat", "Tag when a player writes something in the VIP Chat");
	c_NeedTag = AutoExecConfig_CreateConVar("chats_needtag", "1", "1 = Player have to write * at the start of the message to activate it, 0 = Off");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
	
	RegConsoleCmd("say", CmdSay);
}




// Load the config
public OnConfigsExecuted()
{
	GetConVarString(c_MessageTag, MessageTag, sizeof(MessageTag));
	GetConVarString(c_OwnChatTag, OwnChatTag, sizeof(OwnChatTag));

	NeedTag = GetConVarInt(c_NeedTag);
}



// Playe said something
public Action:CmdSay(client, args)
{
	decl String:text[128];
	decl String:name[MAX_NAME_LENGTH+1];
	decl String:tag[64];


	GetClientName(client, name, sizeof(name));
	GetCmdArgString(text, sizeof(text));
	STAMM_GetTag(tag, sizeof(tag));

	ReplaceString(text, sizeof(text), "\"", "");
	


	// Client valid?
	if (STAMM_IsClientValid(client))
	{
		// Want feature?
		if (!STAMM_WantClientFeature(client))
		{
			if (STAMM_GetGame() == GameCSGO)
			{
				CPrintToChat(client, "%s %t", tag, "FeatureDisabled");
			}
			else
			{
				MCPrintToChat(client, "%s %t", tag, "FeatureDisabled");
			}
		}


		// Can write VIP message?
		if (messages != -1 && STAMM_HaveClientFeature(client, messages))
		{
			if (!NeedTag || (FindCharInString(text, '*') == 0))
			{
				if (NeedTag)
				{
					ReplaceString(text, sizeof(text), "*", "");
				
				}


				// print according to Team
				if (GetClientTeam(client) == 2) 
				{
					if (STAMM_GetGame() == GameCSGO)
					{
						CPrintToChatAll("{red}[%s] {green}%s:{red} %s", MessageTag, name, text);
					}
					else
					{
						MCPrintToChatAll("{red}[%s] {green}%s:{red} %s", MessageTag, name, text);
					}
				}

				else if (GetClientTeam(client) == 3) 
				{
					if (STAMM_GetGame() == GameCSGO)
					{
						CPrintToChatAll("{blue}[%s] {green}%s:{blue} %s", MessageTag, name, text);
					}
					else
					{
						MCPrintToChatAll("{blue}[%s] {green}%s:{blue} %s", MessageTag, name, text);
					}
				}

				else
				{
					if (STAMM_GetGame() == GameCSGO)
					{
						CPrintToChatAll("{lightgreen}[%s] {green}%s:{lightgreen} %s", MessageTag, name, text);
					}
					else
					{
						MCPrintToChatAll("{lightgreen}[%s] {green}%s:{lightgreen} %s", MessageTag, name, text);
					}
				}

				return Plugin_Handled;
			}
		}

		// Can write to vip chat?
		if (chat != -1 && STAMM_HaveClientFeature(client, chat))
		{
			new index2 = FindCharInString(text, '#');


			// Found tag?
			if (index2 == 0)
			{
				ReplaceString(text, sizeof(text), "#", "");
					

				// Print to all VIP's
				for (new i=1; i <= MaxClients; i++)
				{
					if (STAMM_IsClientValid(i))
					{
						// Client have feature
						if (STAMM_HaveClientFeature(i, chat))
						{
							// Print according to team
							if (GetClientTeam(i) == 2) 
							{
								if (STAMM_GetGame() == GameCSGO)
								{
									CPrintToChat(i, "{red}[%s] {green}%s:{red} %s", OwnChatTag, name, text);
								}
								else
								{
									MCPrintToChat(i, "{red}[%s] {green}%s:{red} %s", OwnChatTag, name, text);
								}
							}
							
							else if (GetClientTeam(i) == 3) 
							{
								if (STAMM_GetGame() == GameCSGO)
								{
									CPrintToChat(i, "{blue}[%s] {green}%s:{blue} %s", OwnChatTag, name, text);
								}
								else
								{
									MCPrintToChat(i, "{blue}[%s] {green}%s:{blue} %s", OwnChatTag, name, text);
								}
							}

							else
							{
								if (STAMM_GetGame() == GameCSGO)
								{
									CPrintToChat(i, "{lightgreen}[%s] {green}%s:{lightgreen} %s", OwnChatTag, name, text);
								}
								else
								{
									MCPrintToChat(i, "{lightgreen}[%s] {green}%s:{lightgreen} %s", OwnChatTag, name, text);
								}
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