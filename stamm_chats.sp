#include <sourcemod>
#include <colors>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new Handle:c_MessageTag;
new Handle:c_OwnChatTag;

new v_level;

new String:MessageTag[32];
new String:OwnChatTag[32];
new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature Chats",
	author = "Popoklopsi",
	version = "1.1",
	description = "Give VIP's welcome and leave message",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) SetFailState("Can't Load Feature, Stamm is not installed!");
}

public OnPluginStart()
{
	new Handle:myPlugin = GetMyHandle();
	
	GetPluginFilename(myPlugin, basename, sizeof(basename));
	ReplaceString(basename, sizeof(basename), ".smx", "");
	ReplaceString(basename, sizeof(basename), "stamm/", "");
	ReplaceString(basename, sizeof(basename), "stamm\\", "");
	
	c_MessageTag = CreateConVar("chats_messagetag", "VIP Message", "Tag when a player writes something as a VIP");
	c_OwnChatTag = CreateConVar("chats_ownchattag", "VIP Chat", "Tag when a player writes something in the VIP Chat");
	
	AutoExecConfig(true, "chats", "stamm/features");
	
	RegConsoleCmd("say", CmdSay);
}

public OnConfigsExecuted()
{
	GetConVarString(c_MessageTag, MessageTag, sizeof(MessageTag));
	GetConVarString(c_OwnChatTag, OwnChatTag, sizeof(OwnChatTag));
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[64];

	Format(description, sizeof(description), "%T", "GetChats", LANG_SERVER);
	
	v_level = AddStammFeature(basename, "VIP Chats", description);
	
	Format(description, sizeof(description), "%T", "YouGetChats", LANG_SERVER);
	AddStammFeatureInfo(basename, v_level, description);
}

public Action:CmdSay(client, args)
{
	new String:text[128];
	new String:name[MAX_NAME_LENGTH+1];
	
	GetClientName(client, name, sizeof(name));
	GetCmdArgString(text, sizeof(text));
	
	ReplaceString(text, sizeof(text), "\"", "");
	
	if (IsStammClientValid(client))
	{
		if (ClientWantStammFeature(client, basename))
		{
			if (IsClientVip(client, v_level))
			{
				new index = FindCharInString(text, '*');
				new index2 = FindCharInString(text, '#');
				
				if (index == 0)
				{
					if (!ClientWantStammFeature(client, basename)) CPrintToChat(client, "{olive}[ {green}Stamm {olive}] %T", "FeatureDisabled", LANG_SERVER);
					else
					{
						ReplaceString(text, sizeof(text), "*", "");

						if (GetClientTeam(client) == 2) CPrintToChatAll("{red}[%s] {green}%s:{red} %s", MessageTag, name, text);
						if (GetClientTeam(client) == 3) CPrintToChatAll("{blue}[%s] {green}%s:{blue} %s", MessageTag, name, text);
					}
					return Plugin_Handled;
				}
				else if (index2 == 0)
				{
					if (!ClientWantStammFeature(client, basename)) CPrintToChat(client, "{olive}[ {green}Stamm {olive}] %T", "FeatureDisabled", LANG_SERVER);
					else
					{
						ReplaceString(text, sizeof(text), "#", "");
						
						for (new i=1; i <= MaxClients; i++)
						{
							if (IsStammClientValid(i))
							{
								if (IsClientVip(i, v_level) && ClientWantStammFeature(i, basename))
								{
									if (GetClientTeam(i) == 2) CPrintToChat(i, "{red}[%s] {green}%s:{red} %s", OwnChatTag, name, text);
									if (GetClientTeam(i) == 3) CPrintToChat(i, "{blue}[%s] {green}%s:{blue} %s", OwnChatTag, name, text);
								}
							}
						}
					}
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}