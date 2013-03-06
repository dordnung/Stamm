#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

new coll_offset;

public Plugin:myinfo =
{
	name = "Stamm Feature NoBlock",
	author = "Popoklopsi",
	version = "1.1.0",
	description = "Non VIP's cant' walk through VIP's",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
}

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
		if (!STAMM_HaveClientFeature(client))
			SetEntData(client, coll_offset, 2, 4, true);
	}
	else
		SetEntData(client, coll_offset, 2, 4, true);
}