#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <restrict>

#pragma semicolon 1

new v_level;

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature No Restrict",
	author = "Popoklopsi",
	version = "1.1",
	description = "VIP's can use restricted weapons",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) SetFailState("Can't Load Feature, Stamm is not installed!");
	if (!LibraryExists("weaponrestrict")) SetFailState("Can't Load Feature, Restrict is not installed!");
	
	if (GetStammGame() == GameTF2) SetFailState("Can't Load Feature, not Supported for your game!");
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

	Format(description, sizeof(description), "%T", "GetNoRestrict", LANG_SERVER);
	
	v_level = AddStammFeature(basename, "VIP No Restrict", description);
	
	Format(description, sizeof(description), "%T", "YouGetNoRestrict", LANG_SERVER);
	AddStammFeatureInfo(basename, v_level, description);
}

public Action:Restrict_OnCanBuyWeapon(client, team, WeaponID:id, &CanBuyResult:result)
{
	if (IsStammClientValid(client))
	{
		if (IsClientVip(client, v_level) && ClientWantStammFeature(client, basename))
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
	if (IsStammClientValid(client))
	{
		if (IsClientVip(client, v_level) && ClientWantStammFeature(client, basename))
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
