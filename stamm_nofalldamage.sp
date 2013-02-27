#include <sourcemod>
#include <sdkhooks>

#undef REQUIRE_PLUGIN 
#include <stamm>

#pragma semicolon 1

#define DMG_FALL   (1 << 5)

public Plugin:myinfo =
{
	name = "Stamm Feature No Fall Damage",
	author = "Popoklopsi",
	version = "1.1",
	description = "Give VIP's No Fall Damage",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	decl String:description[64];
	
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
		
	if (!LibraryExists("sdkhooks")) 
		SetFailState("Can't Load Feature, SDKHooks is not installed!");
	
	STAMM_LoadTranslation();
		
	Format(description, sizeof(description), "%T", "GetNoFallDamage", LANG_SERVER);
	
	STAMM_AddFeature("VIP No Fall Damage", description);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && IsPlayerAlive(client))
			{
				if (damagetype & DMG_FALL)
					return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}
