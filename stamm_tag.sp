#include <sourcemod>
#include <cstrike>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new Handle:s_tag;
new Handle:s_admin;

new v_level;
new admin_tag;

new String:tag[PLATFORM_MAX_PATH + 1];
new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature VIP Tag",
	author = "Popoklopsi",
	version = "1.2",
	description = "Give VIP's a VIP Tag",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) SetFailState("Can't Load Feature, Stamm is not installed!");
	
	if (GetStammGame() == GameTF2) SetFailState("Can't Load Feature, not Supported for your game!");
}

public OnPluginStart()
{
	new Handle:myPlugin = GetMyHandle();
	
	GetPluginFilename(myPlugin, basename, sizeof(basename));
	ReplaceString(basename, sizeof(basename), ".smx", "");
	ReplaceString(basename, sizeof(basename), "stamm/", "");
	ReplaceString(basename, sizeof(basename), "stamm\\", "");
	
	s_tag = CreateConVar("tag_text", "*VIP*", "Stamm Tag");
	s_admin = CreateConVar("tag_admin", "1", "1=Admins get also tag, 0=Off");
	
	AutoExecConfig(true, "tag", "stamm/features");
	
	HookEvent("player_spawn", eventPlayerSpawn);
}

public OnConfigsExecuted()
{
	GetConVarString(s_tag, tag, sizeof(tag));
	admin_tag = GetConVarInt(s_admin);
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[64];

	Format(description, sizeof(description), "%T", "GetTag", LANG_SERVER, tag);
	
	v_level = AddStammFeature(basename, "VIP Tag", description);
	
	Format(description, sizeof(description), "%T", "YouGetTag", LANG_SERVER, tag);
	AddStammFeatureInfo(basename, v_level, description);
}

public OnStammClientReady(client)
{
	NameCheck(client);
}

public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (IsStammClientValid(client)) NameCheck(client);
}


public NameCheck(client)
{
	new String:name[MAX_NAME_LENGTH+1];
	
	CS_GetClientClanTag(client, name, sizeof(name));
	
	if (StrContains(name, tag) != -1)
	{
		if (!IsClientVip(client, v_level))
		{
			ReplaceString(name, sizeof(name), tag, "");
			CS_SetClientClanTag(client, name);
		}
	}
	else
	{
		if (IsClientVip(client, v_level) && ClientWantStammFeature(client, basename)) 
		{
			if (admin_tag || (!admin_tag && !IsClientStammAdmin(client))) CS_SetClientClanTag(client, tag);
		}
	}
}