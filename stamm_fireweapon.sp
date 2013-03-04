#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Stamm Feature FireWeapon",
	author = "Popoklopsi",
	version = "1.0",
	description = "VIP's can ignite players with there weapon",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	decl String:haveDescription[64];

	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");

	STAMM_LoadTranslation();

	Format(haveDescription, sizeof(haveDescription), "%T", "GetFireWeapon", LANG_SERVER);
	
	STAMM_AddFeature("VIP FireWeapon", haveDescription);
}

public OnPluginStart()
{
	HookEvent("player_hurt", PlayerHurt);
}

public PlayerHurt(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (STAMM_IsClientValid(attacker) && client > 0 && client != attacker)
	{
		if (STAMM_HaveClientFeature(attacker) && IsClientInGame(client) && IsPlayerAlive(client) && (GetClientTeam(client) != GetClientTeam(attacker)))
			IgniteEntity(client, 2.0);
	}
}