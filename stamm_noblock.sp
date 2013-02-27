#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new coll_offset;

public Plugin:myinfo =
{
	name = "Stamm Feature NoBlock",
	author = "Popoklopsi",
	version = "1.1",
	description = "VIP's can walk through other players",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	decl String:description[64];

	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");

	STAMM_LoadTranslation();
		
	Format(description, sizeof(description), "%T", "GetNoBlock", LANG_SERVER);
	
	STAMM_AddFeature("VIP NoBlock", description);
	
	coll_offset = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	
	if (coll_offset == -1) 
		SetFailState("Can't Load Feature, failed to find CBaseEntity::m_CollisionGroup");
}

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
}

public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (STAMM_IsClientValid(client))
	{
		if (!STAMM_IsClientVip(client, STAMM_GetLevel()))
			SetEntData(client, coll_offset, 2, 4, true);
	}
	else
		SetEntData(client, coll_offset, 2, 4, true);
}