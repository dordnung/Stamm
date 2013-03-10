#include <sourcemod>
#include <sdktools>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

new ammo;

new Handle:c_ammo;
new Handle:thetimer;

new bool:WeaponEdit[MAXPLAYERS + 1][2024];

public Plugin:myinfo =
{
	name = "Stamm Feature MoreAmmo",
	author = "Popoklopsi",
	version = "1.2.0",
	description = "Give VIP's more ammo",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	STAMM_LoadTranslation();
	STAMM_AddFeature("VIP MoreAmmo", "");
}

public OnPluginStart()
{
	HookEvent("player_death", PlayerDeath);
	
	if (STAMM_GetGame() == GameTF2)
	{
		HookEvent("teamplay_round_start", RoundStart);
		HookEvent("arena_round_start", RoundStart);
	}
	
	if (STAMM_GetGame() == GameDOD)
		HookEvent("dod_round_start", RoundStart);

	AutoExecConfig_SetFile("moreammo", "stamm/features");
	
	c_ammo = AutoExecConfig_CreateConVar("ammo_amount", "20", "Ammo increase in percent each block!");
	
	AutoExecConfig(true, "moreammo", "stamm/features");
	AutoExecConfig_CleanFile();
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:haveDescription[64];
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
	
	for (new i=1; i <= STAMM_GetBlockCount(); i++)
	{
		Format(haveDescription, sizeof(haveDescription), "%T", "GetMoreAmmo", LANG_SERVER, ammo * i);
		
		STAMM_AddFeatureText(STAMM_GetLevel(i), haveDescription);
	}
}

public OnMapStart()
{
	if (thetimer != INVALID_HANDLE) 
		KillTimer(thetimer);
	
	thetimer = CreateTimer(1.0, CheckWeapons, _, TIMER_REPEAT);
}

public OnConfigsExecuted()
{
	ammo = GetConVarInt(c_ammo);
}

public PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	for (new x=0; x < 2024; x++) 
		WeaponEdit[client][x] = false;
}

public RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	for (new x=0; x < 2024; x++)
	{
		for (new i=0; i <= MaxClients; i++) 
			WeaponEdit[i][x] = false;
	}
}

public Action:CheckWeapons(Handle:timer, any:data)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		new client = i;
		
		if (STAMM_IsClientValid(client) && IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3))
		{
			for (new j=STAMM_GetBlockCount(); j > 0; j--)
			{
				if (STAMM_HaveClientFeature(client, j))
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
									new newAmmo;
									
									newAmmo = RoundToZero(cAmmo + ((float(cAmmo)/100.0) * (j * ammo)));
									
									SetEntProp(client, Prop_Send, "m_iAmmo", newAmmo, _, ammotype);
									
									WeaponEdit[client][weapon] = true;
								}
							}
						}
					}

					break;
				}
			}
		}
	}
	
	return Plugin_Continue;
}