#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new ammo;

new Handle:c_ammo;
new Handle:thetimer;

new bool:WeaponEdit[MAXPLAYERS + 1][2024];

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature MoreAmmo",
	author = "Popoklopsi",
	version = "1.1",
	description = "Give VIP's more ammo",
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
	
	HookEvent("player_death", PlayerDeath);
	
	if (GetStammGame() == GameTF2)
	{
		HookEvent("teamplay_round_start", RoundStart);
		HookEvent("arena_round_start", RoundStart);
	}
	
	c_ammo = CreateConVar("ammo_amount", "20", "Ammo increase in percent each level!");
	
	AutoExecConfig(true, "moreammo", "stamm/features");
}

public OnMapStart()
{
	if (thetimer != INVALID_HANDLE) KillTimer(thetimer);
	
	thetimer = CreateTimer(1.0, CheckWeapons, _, TIMER_REPEAT);
}

public OnConfigsExecuted()
{
	ammo = GetConVarInt(c_ammo);
}

public PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	for (new x=0; x < 2024; x++) WeaponEdit[client][x] = false;
}

public RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	for (new x=0; x < 2024; x++)
	{
		for (new i=0; i <= MaxClients; i++) WeaponEdit[i][x] = false;
	}
}

public Action:CheckWeapons(Handle:timer, any:data)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		new client = i;
		
		if (IsStammClientValid(client) && IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3))
		{
			if (IsClientVip(client, 1) && ClientWantStammFeature(client, basename))
			{
				for (new x=0; x < 2; x++)
				{
					new weapon = GetPlayerWeaponSlot(client, x);

					if (weapon != -1 && !WeaponEdit[client][weapon])
					{
						new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");

						if (ammotype != -1)
						{
							new cAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
							
							if (cAmmo > 0)
							{
								new newAmmo = RoundToZero(cAmmo + ((float(cAmmo)/100.0) * (GetClientStammLevel(client) * ammo)));
								
								SetEntProp(client, Prop_Send, "m_iAmmo", newAmmo, _, ammotype);
								
								WeaponEdit[client][weapon] = true;
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[256];
	
	Format(description, sizeof(description), "%T", "GetMoreAmmo", LANG_SERVER, ammo);
	
	AddStammFeature(basename, "VIP MoreAmmo", description);

	for (new i=1; i <= GetStammLevelCount(); i++)
	{
		Format(description, sizeof(description), "%T", "YouGetMoreAmmo", LANG_SERVER, ammo * i);
		AddStammFeatureInfo(basename, i, description);
	}
}