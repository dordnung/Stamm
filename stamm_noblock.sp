#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new v_level;
new coll_offset;

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature NoBlock",
	author = "Popoklopsi",
	version = "1.0",
	description = "VIP's can walk through other players",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) SetFailState("Can't Load Feature, Stamm is not installed!");
	
	coll_offset = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	if (coll_offset == -1) SetFailState("Can't Load Feature, failed to find CBaseEntity::m_CollisionGroup");
}

public OnPluginStart()
{
	new Handle:myPlugin = GetMyHandle();
	
	GetPluginFilename(myPlugin, basename, sizeof(basename));
	ReplaceString(basename, sizeof(basename), ".smx", "");
	ReplaceString(basename, sizeof(basename), "stamm/", "");
	ReplaceString(basename, sizeof(basename), "stamm\\", "");
	
	HookEvent("player_spawn", PlayerSpawn);
}

public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsStammClientValid(client))
	{
		if (!IsClientVip(client, v_level)) SetEntData(client, coll_offset, 2, 4, true);
	}
	else SetEntData(client, coll_offset, 2, 4, true);
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[256];
	
	Format(description, sizeof(description), "%T", "GetNoBlock", LANG_SERVER);
	
	v_level = AddStammFeature(basename, "VIP NoBlock", description);
	
	Format(description, sizeof(description), "%T", "YouGetNoBlock", LANG_SERVER);
	AddStammFeatureInfo(basename, v_level, description);
}