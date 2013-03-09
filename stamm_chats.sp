#include <sourcemod>
#include <colors>
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
	version = "1.2.0",
	description = "Give VIP's welcome and leave message",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");

	if (!CColorAllowed(Color_Lightgreen))
	{
		if (CColorAllowed(Color_Lime))
			CReplaceColor(Color_Lightgreen, Color_Lime);
		else if (CColorAllowed(Color_Olive))
			CReplaceColor(Color_Lightgreen, Color_Olive);
	}
		
	STAMM_LoadTranslation();
		
	STAMM_AddFeature("VIP Chats", "");
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:description[64];
	decl String:activate[64];
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);

	if (NeedTag)
	{
		Format(activate, sizeof(activate), "%T", "Activate", LANG_SERVER, "*");
		Format(description, sizeof(description), "%T", "GetVIPMessage", LANG_SERVER, activate);
	}
	else
		Format(description, sizeof(description), "%T", "GetVIPMessage", LANG_SERVER, "");

	messages = STAMM_GetBlockOfName("messages");
	chat = STAMM_GetBlockOfName("chat");

	if (messages == -1)
		messages = 1;

	if (chat == -1)
		chat = 1;

	STAMM_AddFeatureText(STAMM_GetLevel(STAMM_GetBlockOfName("messages")), description);

	Format(activate, sizeof(activate), "%T", "Activate", LANG_SERVER, "#");
	Format(description, sizeof(description), "%T", "GetVIPChat", LANG_SERVER, activate);

	STAMM_AddFeatureText(STAMM_GetLevel(STAMM_GetBlockOfName("chat")), description);
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("chats", "stamm/features");

	c_MessageTag = AutoExecConfig_CreateConVar("chats_messagetag", "VIP Message", "Tag when a player writes something as a VIP");
	c_OwnChatTag = AutoExecConfig_CreateConVar("chats_ownchattag", "VIP Chat", "Tag when a player writes something in the VIP Chat");
	c_NeedTag = AutoExecConfig_CreateConVar("chats_needtag", "1", "1 = Player have to write * at the start of the message to activate it, 0 = Off");
	
	AutoExecConfig(true, "chats", "stamm/features");
	AutoExecConfig_CleanFile();
	
	RegConsoleCmd("say", CmdSay);
}

public OnConfigsExecuted()
{
	GetConVarString(c_MessageTag, MessageTag, sizeof(MessageTag));
	GetConVarString(c_OwnChatTag, OwnChatTag, sizeof(OwnChatTag));

	NeedTag = GetConVarInt(c_NeedTag);
}

public Action:CmdSay(client, args)
{
	decl String:text[128];
	decl String:name[MAX_NAME_LENGTH+1];
	
	GetClientName(client, name, sizeof(name));
	GetCmdArgString(text, sizeof(text));
	
	ReplaceString(text, sizeof(text), "\"", "");
	
	if (STAMM_IsClientValid(client))
	{
		if (!STAMM_WantClientFeature(client))
			CPrintToChat(client, "{lightgreen}[ {green}Stamm {lightgreen}] %T", "FeatureDisabled", LANG_SERVER);
			
		if (STAMM_HaveClientFeature(client, messages))
		{
			if (!NeedTag || (FindCharInString(text, '*') == 0))
			{
				if (NeedTag)
					ReplaceString(text, sizeof(text), "*", "");

				if (GetClientTeam(client) == 2) 
					CPrintToChatAll("{red}[%s] {green}%s:{red} %s", MessageTag, name, text);
					
				if (GetClientTeam(client) == 3) 
					CPrintToChatAll("{blue}[%s] {green}%s:{blue} %s", MessageTag, name, text);

				else
					CPrintToChatAll("{lightgreen}[%s] {green}%s:{lightgreen} %s", MessageTag, name, text);
				
				return Plugin_Handled;
			}
		}

		if (STAMM_HaveClientFeature(client, chat))
		{
			new index2 = FindCharInString(text, '#');

			if (index2 == 0)
			{
				ReplaceString(text, sizeof(text), "#", "");
					
				for (new i=1; i <= MaxClients; i++)
				{
					if (STAMM_IsClientValid(i))
					{
						if (STAMM_HaveClientFeature(i, STAMM_GetBlockOfName("chat")))
						{
							if (GetClientTeam(i) == 2) 
								CPrintToChat(i, "{red}[%s] {green}%s:{red} %s", OwnChatTag, name, text);
								
							if (GetClientTeam(i) == 3) 
								CPrintToChat(i, "{blue}[%s] {green}%s:{blue} %s", OwnChatTag, name, text);

							else
								CPrintToChat(i, "{lightgreen}[%s] {green}%s:{lightgreen} %s", OwnChatTag, name, text);
						}
					}
				}
				
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}