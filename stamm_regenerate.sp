#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new hp;

new v_level;

new Handle:c_hp;
new Handle:ClientTimers[MAXPLAYERS + 1];

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature RegenerateHP",
	author = "Popoklopsi",
	version = "1.1",
	description = "Regenerate HP of VIP's",
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
	
	c_hp = CreateConVar("regenerate_hp", "2", "HP regeneration of a VIP, every second");
	
	AutoExecConfig(true, "regenerate", "stamm/features");
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
		if (IsClientVip(client, v_level) && ClientWantStammFeature(client, basename))
		{
			if (ClientTimers[client] != INVALID_HANDLE) KillTimer(ClientTimers[client]);
			
			ClientTimers[client] = CreateTimer(1.0, GiveHealth, client, TIMER_REPEAT);
		}
	}
}

public Action:GiveHealth(Handle:timer, any:client)
{
	if (IsStammClientValid(client))
	{
		if (IsClientVip(client, v_level) && ClientWantStammFeature(client, basename) && IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3))
		{
			new maxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
			new oldHP = GetClientHealth(client);
			new newHP = oldHP + hp;
			
			if (newHP > maxHealth)
			{
				if (oldHP < maxHealth) newHP = maxHealth;
				else return Plugin_Continue;
			}
			
			SetEntityHealth(client, newHP);
			
			return Plugin_Continue;
		}
	}
	
	return Plugin_Handled;
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[256];
	
	Format(description, sizeof(description), "%T", "GetRegenerate", LANG_SERVER, hp);
	
	v_level = AddStammFeature("stamm_regenerate", "VIP HP Regenerate", description);
	
	Format(description, sizeof(description), "%T", "YouGetRegenerate", LANG_SERVER, hp);
	AddStammFeatureInfo(basename, v_level, description);
}