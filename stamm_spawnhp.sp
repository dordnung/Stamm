#include <sourcemod>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

new hp;
new Handle:c_hp;

public Plugin:myinfo =
{
	name = "Stamm Feature SpawnHP",
	author = "Popoklopsi",
	version = "1.3",
	description = "Give VIP's more HP on spawn",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	STAMM_LoadTranslation();
		
	STAMM_AddFeature("VIP SpawnHP", "");
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:haveDescription[64];
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.couch-fighter.de/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
	
	for (new i=1; i <= STAMM_GetBlockCount(); i++)
	{
		Format(haveDescription, sizeof(haveDescription), "%T", "GetSpawnHP", LANG_SERVER, hp * i);
		
		STAMM_AddFeatureText(STAMM_GetLevel(i), haveDescription);
	}
}

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);

	AutoExecConfig_SetFile("spawnhp", "stamm/features");
	
	c_hp = AutoExecConfig_CreateConVar("spawnhp_hp", "50", "HP a VIP gets every spawn more");
	
	AutoExecConfig_AutoExecConfig();

	AutoExecConfig_CleanFile();
}

public OnConfigsExecuted()
{
	hp = GetConVarInt(c_hp);
}

public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (STAMM_IsClientValid(client))
	{
		if (IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)) 
			CreateTimer(0.5, changeHealth, client);
	}
}

public Action:changeHealth(Handle:timer, any:client)
{
	for (new i=STAMM_GetBlockCount(); i > 0; i--)
	{
		if (STAMM_HaveClientFeature(client, i))
		{
			new newHP = GetClientHealth(client) + hp * i;
			
			SetEntProp(client, Prop_Data, "m_iMaxHealth", newHP);
			SetEntityHealth(client, newHP);

			break;
		}
	}
}