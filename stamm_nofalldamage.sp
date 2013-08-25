#pragma semicolon 1
#include <sourcemod>

#undef REQUIRE_PLUGIN 
#include <sdkhooks>
#include <stamm>

new v_level;

new String:basename[64];

#define DMG_FALL   (1 << 5)


public Plugin:myinfo =
{
	name = "Stamm Feature No Fall Damage",
	author = "Franc1sco steam: franug",
	version = "1.0",
	description = "Give VIP's No Fall Damage",
	url = "www.servers-cfg.foroactivo.com"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) SetFailState("Can't Load Feature, Stamm is not installed!");
	if (!LibraryExists("sdkhooks")) SetFailState("Can't Load Feature, SDKHooks is not installed!");
	
	if (GetStammGame() != GameCSS) SetFailState("Can't Load Feature, not Supported for your game!");
}

public OnPluginStart()
{
	new Handle:myPlugin = GetMyHandle();
	
	GetPluginFilename(myPlugin, basename, sizeof(basename));
	ReplaceString(basename, sizeof(basename), ".smx", "");
	ReplaceString(basename, sizeof(basename), "stamm/", "");
	ReplaceString(basename, sizeof(basename), "stamm\\", "");
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[64];

	Format(description, sizeof(description), "%T", "GetNoFallDamage", LANG_SERVER);
	
	v_level = AddStammFeature(basename, "VIP No Fall Damage", description);
	
	Format(description, sizeof(description), "%T", "YouGetNoFallDamage", LANG_SERVER);
	AddStammFeatureInfo(basename, v_level, description);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsStammClientValid(client))
	{
		if (ClientWantStammFeature(client, basename))
		{
			if (IsClientVip(client, v_level) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && IsPlayerAlive(client))
			{
				if (damagetype & DMG_FALL)
				{
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}
