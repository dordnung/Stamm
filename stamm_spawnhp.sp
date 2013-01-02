#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new hp;
new v_level;

new Handle:c_hp;

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature SpawnHP",
	author = "Popoklopsi",
	version = "1.2",
	description = "Give VIP's more HP on spawn",
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
	
	HookEvent("player_spawn", PlayerSpawn);
	
	c_hp = CreateConVar("spawnhp_hp", "50", "HP a VIP gets every spawn more");
	
	AutoExecConfig(true, "spawnhp", "stamm/features");
}

public OnConfigsExecuted()
{
	hp = GetConVarInt(c_hp);
}

public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsStammClientValid(client))
	{
		if (IsClientVip(client, v_level) && ClientWantStammFeature(client, basename) && IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)) CreateTimer(0.5, changeHealth, client);
	}
}

public Action:changeHealth(Handle:timer, any:client)
{
	new newHP = GetClientHealth(client) + hp;
	
	SetEntProp(client, Prop_Data, "m_iMaxHealth", newHP);
	SetEntityHealth(client, newHP);
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[256];
	
	Format(description, sizeof(description), "%T", "GetSpawnHP", LANG_SERVER, hp);
	
	v_level = AddStammFeature("stamm_spawnhp", "VIP SpawnHP", description);
	
	Format(description, sizeof(description), "%T", "YouGetSpawnHP", LANG_SERVER, hp);
	AddStammFeatureInfo(basename, v_level, description);
}