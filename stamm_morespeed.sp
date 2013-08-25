#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new speed;

new Handle:c_speed;

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature MoreSpeed",
	author = "Popoklopsi",
	version = "1.1",
	description = "Give VIP's more speed",
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
	
	c_speed = CreateConVar("speed_increase", "20", "Speed increase in percent each level!");
	
	AutoExecConfig(true, "morespeed", "stamm/features");
}

public OnConfigsExecuted()
{
	speed = GetConVarInt(c_speed);
}

public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsStammClientValid(client) && IsPlayerAlive(client))
	{
		if (IsClientVip(client, 1) && ClientWantStammFeature(client, basename))
		{
			new Float:newSpeed;
			
			newSpeed = 1.0 + float(speed)/100.0 * GetClientStammLevel(client);
			
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", newSpeed);
		}
		else SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
}

public OnClientChangeStammFeature(client, String:base[], mode)
{
	if (IsStammClientValid(client) && StrEqual(basename, base))
	{
		if (mode == 1 && IsClientVip(client, 1))
		{
			new Float:newSpeed;
			
			newSpeed = 1.0 + float(speed)/100.0 * GetClientStammLevel(client);
			
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", newSpeed);
		}
		
		if (mode == 0) SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[256];
	
	Format(description, sizeof(description), "%T", "GetMoreSpeed", LANG_SERVER, speed);
	
	AddStammFeature(basename, "VIP MoreSpeed", description);

	for (new i=1; i <= GetStammLevelCount(); i++)
	{
		Format(description, sizeof(description), "%T", "YouGetMoreSpeed", LANG_SERVER, speed * i);
		AddStammFeatureInfo(basename, i, description);
	}
}