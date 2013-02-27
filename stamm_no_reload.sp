#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Stamm Feature No Reload",
	author = "Popoklopsi",
	version = "1.2",
	description = "VIP's don't have to reload",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	decl String:description[64];

	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	if (STAMM_GetGame() == GameTF2) 
		SetFailState("Can't Load Feature, not Supported for your game!");
		
	STAMM_LoadTranslation();
		
	Format(description, sizeof(description), "%T", "GetNoReload", LANG_SERVER);
	
	STAMM_AddFeature("VIP No Reload", description);
}

public OnPluginStart()
{
	HookEvent("weapon_fire", eventWeaponFire);
}

public Action:eventWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	decl String:weapons[64];
	decl String:Pri[64];
	decl String:Sec[64];
	
	GetEventString(event, "weapon", weapons, sizeof(weapons));
	
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
				ReplaceString(Pri, sizeof(Pri), "weapon_", "");
			}
			
			if (sec_i != -1)
			{
				GetEdictClassname(sec_i, Sec, sizeof(Sec));
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