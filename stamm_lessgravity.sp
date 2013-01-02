#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new grav;

new Handle:c_grav;

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature LessGravity",
	author = "Popoklopsi",
	version = "1.1",
	description = "Give VIP's less gravity",
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
	
	c_grav = CreateConVar("gravity_decrease", "10", "Gravity decrease in percent each level!");
	
	AutoExecConfig(true, "lessgravity", "stamm/features");
}

public OnConfigsExecuted()
{
	grav = GetConVarInt(c_grav);
}

public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsStammClientValid(client) && IsPlayerAlive(client))
	{
		if (IsClientVip(client, 1) && ClientWantStammFeature(client, basename))
		{
			new Float:newGrav;
			
			newGrav = 1.0 - float(grav)/100.0 * GetClientStammLevel(client);
			
			if (newGrav < 0.1) newGrav = 0.1;
			
			SetEntityGravity(client, newGrav);
		}
		else SetEntityGravity(client, 1.0);
	}
}

public OnClientChangeStammFeature(client, String:base[], mode)
{
	if (IsStammClientValid(client) && StrEqual(base, basename))
	{
		new Float:newGrav;
		
		if (mode == 1 && IsClientVip(client, 1))
		{
			newGrav = 1.0 - float(grav)/100.0 * GetClientStammLevel(client);
			
			if (newGrav < 0.1) newGrav = 0.1;
				
			SetEntityGravity(client, newGrav);
		}
		if (mode == 0) SetEntityGravity(client, 1.0);
	}
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[256];
	
	Format(description, sizeof(description), "%T", "GetLessGravity", LANG_SERVER, grav);
	
	AddStammFeature(basename, "VIP LessGravity", description);

	for (new i=1; i <= GetStammLevelCount(); i++)
	{
		Format(description, sizeof(description), "%T", "YouGetLessGravity", LANG_SERVER, grav * i);
		AddStammFeatureInfo(basename, i, description);
	}
}