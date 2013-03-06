#include <sourcemod>
#include <cstrike>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

new Handle:s_tag;
new Handle:s_admin;
new admin_tag;

new String:tag[PLATFORM_MAX_PATH + 1];

public Plugin:myinfo =
{
	name = "Stamm Feature VIP Tag",
	author = "Popoklopsi",
	version = "1.3.0",
	description = "Give VIP's a VIP Tag",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
		SetFailState("Can't Load Feature, not Supported for your game!");
		
	STAMM_LoadTranslation();

	STAMM_AddFeature("VIP Tag", "", true, false);
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("tag", "stamm/features");

	s_tag = AutoExecConfig_CreateConVar("tag_text", "*VIP*", "Stamm Tag");
	s_admin = AutoExecConfig_CreateConVar("tag_admin", "1", "1=Admins get also tag, 0=Off");
	
	AutoExecConfig_AutoExecConfig();

	AutoExecConfig_CleanFile();
	
	HookEvent("player_spawn", eventPlayerSpawn);
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:description[64];
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
	
	Format(description, sizeof(description), "%T", "GetTag", LANG_SERVER, tag);
	
	STAMM_AddFeatureText(STAMM_GetLevel(), description);
}

public OnConfigsExecuted()
{
	GetConVarString(s_tag, tag, sizeof(tag));
	admin_tag = GetConVarInt(s_admin);
}

public STAMM_OnClientReady(client)
{
	NameCheck(client);
}

public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (STAMM_IsClientValid(client)) 
		NameCheck(client);
}


public NameCheck(client)
{
	new String:name[MAX_NAME_LENGTH+1];
	
	CS_GetClientClanTag(client, name, sizeof(name));
	
	if (StrContains(name, tag) != -1)
	{
		if (!STAMM_IsClientVip(client, STAMM_GetLevel()))
		{
			ReplaceString(name, sizeof(name), tag, "");
			CS_SetClientClanTag(client, name);
		}
	}
	else
	{
		if (STAMM_HaveClientFeature(client)) 
		{
			if (admin_tag || (!admin_tag && !STAMM_IsClientAdmin(client))) 
				CS_SetClientClanTag(client, tag);
		}
	}
}