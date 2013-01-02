#include <sourcemod>
#include <colors>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new v_level;

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature Chat Messages",
	author = "Popoklopsi",
	version = "1.1",
	description = "Give VIP's VIP Chat and Message",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnPluginStart()
{
	new Handle:myPlugin = GetMyHandle();
	
	GetPluginFilename(myPlugin, basename, sizeof(basename));
	ReplaceString(basename, sizeof(basename), ".smx", "");
	ReplaceString(basename, sizeof(basename), "stamm/", "");
	ReplaceString(basename, sizeof(basename), "stamm\\", "");
}

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) SetFailState("Can't Load Feature, Stamm is not installed!");
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[64];

	Format(description, sizeof(description), "%T", "GetChatMessages", LANG_SERVER);
	
	v_level = AddStammFeature(basename, "VIP Chat Messages", description);
	
	Format(description, sizeof(description), "%T", "YouGetChatMessages", LANG_SERVER);
	AddStammFeatureInfo(basename, v_level, description);

}

public OnStammClientReady(client)
{
	new String:name[MAX_NAME_LENGTH + 1];
	
	GetClientName(client, name, sizeof(name));
	
	if (IsClientVip(client, v_level) && ClientWantStammFeature(client, basename)) CPrintToChatAll("{olive}[ {green}Stamm {olive}] %T", "WelcomeMessage", LANG_SERVER, name);
}

public OnClientDisconnect(client)
{
	if (IsStammClientValid(client))
	{
		new String:name[MAX_NAME_LENGTH + 1];
		
		GetClientName(client, name, sizeof(name));
		
		if (IsClientVip(client, v_level))
		{
			if (ClientWantStammFeature(client, basename)) CPrintToChatAll("{olive}[ {green}Stamm {olive}] %T", "LeaveMessage", LANG_SERVER, name);
		}
	}
}