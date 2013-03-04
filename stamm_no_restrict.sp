#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <restrict>
#include <updater>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Stamm Feature No Restrict",
	author = "Popoklopsi",
	version = "1.2.0",
	description = "VIP's can use restricted weapons",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.couch-fighter.de/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
}

public OnAllPluginsLoaded()
{
	decl String:description[64];
	
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
		
	if (!LibraryExists("weaponrestrict")) 
		SetFailState("Can't Load Feature, Weapon Restrict is not installed!");
	
	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
		SetFailState("Can't Load Feature, not Supported for your game!");
		
	STAMM_LoadTranslation();
		
	Format(description, sizeof(description), "%T", "GetNoRestrict", LANG_SERVER);
	
	STAMM_AddFeature("VIP No Restrict", description);
}

public Action:Restrict_OnCanBuyWeapon(client, team, WeaponID:id, &CanBuyResult:result)
{
	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			if (result != CanBuy_Allow)
			{
				result = CanBuy_Allow;
				
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Restrict_OnCanPickupWeapon(client, team, WeaponID:id, &bool:result)
{
	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			if (result != true)
			{
				result = true;
				
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}