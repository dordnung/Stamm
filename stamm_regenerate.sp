#include <sourcemod>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new hp;

new Handle:c_hp;
new Handle:ClientTimers[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Stamm Feature RegenerateHP",
	author = "Popoklopsi",
	version = "1.2",
	description = "Regenerate HP of VIP's",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	STAMM_LoadTranslation();
		
	STAMM_AddFeature("VIP HP Regenerate", "");
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:haveDescription[64];

	for (new i=1; i <= STAMM_GetBlockCount(); i++)
	{
		Format(haveDescription, sizeof(haveDescription), "%T", "GetRegenerate", LANG_SERVER, hp * i);
		
		STAMM_AddFeatureText(STAMM_GetLevel(i), haveDescription);
	}
}

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);

	AutoExecConfig_SetFile("stamm/features/regenerate");
	
	c_hp = AutoExecConfig_CreateConVar("regenerate_hp", "2", "HP regeneration of a VIP, every second per block");
	
	AutoExecConfig(true, "regenerate", "stamm/features");
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
		if (STAMM_HaveClientFeature(client))
		{
			if (ClientTimers[client] != INVALID_HANDLE) 
				KillTimer(ClientTimers[client]);
			
			ClientTimers[client] = CreateTimer(1.0, GiveHealth, client, TIMER_REPEAT);
		}
	}
}

public Action:GiveHealth(Handle:timer, any:client)
{
	if (STAMM_IsClientValid(client))
	{
		for (new i=STAMM_GetBlockCount(); i > 0; i--)
		{
			if (STAMM_HaveClientFeature(client, i) && IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3))
			{
				new maxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
				new oldHP = GetClientHealth(client);
				new newHP = oldHP + hp*i;
				
				if (newHP > maxHealth)
				{
					if (oldHP < maxHealth) 
						newHP = maxHealth;
					else 
						return Plugin_Continue;
				}
				
				SetEntityHealth(client, newHP);
				
				return Plugin_Continue;
			}
		}
	}
	
	return Plugin_Handled;
}