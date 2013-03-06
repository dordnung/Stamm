#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#undef REQUIRE_EXTENSIONS
#include <tf2>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Stamm Feature No Reload",
	author = "Popoklopsi",
	version = "1.2.0",
	description = "VIP's don't have to reload",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
}

public OnAllPluginsLoaded()
{
	decl String:description[64];

	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");

	if (STAMM_GetGame() == GameDOD) 
		SetFailState("Can't Load Feature, not Supported for your game!");

	STAMM_LoadTranslation();
		
	Format(description, sizeof(description), "%T", "GetNoReload", LANG_SERVER);
	
	STAMM_AddFeature("VIP No Reload", description);

	if (STAMM_GetGame() != GameTF2)
		HookEvent("weapon_fire", eventWeaponFire);
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	giveNoReload(client, weaponname);

	return Plugin_Continue;
}

public Action:eventWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:weapons[64];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	GetEventString(event, "weapon", weapons, sizeof(weapons));

	giveNoReload(client, weapons);
}

public giveNoReload(client, String:weapons[])
{
	decl String:Pri[64];
	decl String:Sec[64];

	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			new pri_i = GetPlayerWeaponSlot(client, 0);
			new sec_i = GetPlayerWeaponSlot(client, 1);
			new weapon;
			
			if (pri_i != -1)
			{
				GetEdictClassname(pri_i, Pri, sizeof(Pri));

				if (STAMM_GetGame() != GameTF2)
					ReplaceString(Pri, sizeof(Pri), "weapon_", "");
			}
			
			if (sec_i != -1)
			{
				GetEdictClassname(sec_i, Sec, sizeof(Sec));

				if (STAMM_GetGame() != GameTF2)
					ReplaceString(Sec, sizeof(Sec), "weapon_", "");
			}

			if (StrEqual(weapons, Pri))
				weapon = pri_i;
				
			else if (StrEqual(weapons, Sec))
				weapon = sec_i;
			else 
				return;

			new clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
			new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
			
			if (clip <= 3)
			{		
				if (ammo > 0)
				{
					SetEntProp(weapon, Prop_Send, "m_iClip1", 4);
					
					new newAmmo = ammo-(4-clip);
					
					if (newAmmo <= 0) 
						newAmmo = 0;
					
					SetEntProp(client, Prop_Send, "m_iAmmo", newAmmo, _, ammotype);
				}
			}
		}
	}
}