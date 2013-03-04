#include <sourcemod>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

new hp;
new timeInterval;

new Handle:c_hp;
new Handle:c_time;
new Handle:ClientTimers[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Stamm Feature RegenerateHP",
	author = "Popoklopsi",
	version = "1.2.0",
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
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.couch-fighter.de/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
	
	for (new i=1; i <= STAMM_GetBlockCount(); i++)
	{
		Format(haveDescription, sizeof(haveDescription), "%T", "GetRegenerate", LANG_SERVER, hp * i, timeInterval);
		
		STAMM_AddFeatureText(STAMM_GetLevel(i), haveDescription);
	}
}

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);

	AutoExecConfig_SetFile("regenerate", "stamm/features");
	
	c_hp = AutoExecConfig_CreateConVar("regenerate_hp", "2", "HP regeneration of a VIP, every x seconds per block");
	c_time = AutoExecConfig_CreateConVar("regenerate_time", "1", "Time interval to regenerate (in Seconds)");
	
	AutoExecConfig_AutoExecConfig();
	AutoExecConfig_CleanFile();
}

public OnConfigsExecuted()
{
	hp = GetConVarInt(c_hp);
	timeInterval = GetConVarInt(c_time);
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
			
			ClientTimers[client] = CreateTimer(float(timeInterval), GiveHealth, client, TIMER_REPEAT);
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