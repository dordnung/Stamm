#include <sourcemod>
#include <colors>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new Handle:damage_area_c;

new v_level;

new damage_area;

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature Show Damage",
	author = "Popoklopsi",
	version = "1.1",
	description = "VIP's can see the damage they done",
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
	
	damage_area_c = CreateConVar("damage_area", "1", "Textarea where to show message, 1=Center Text, 2=Hint Text, 3=Chat");
	
	AutoExecConfig(true, "show_damage", "stamm/features");
	
	HookEvent("player_hurt", eventPlayerHurt);
}

public OnConfigsExecuted()
{
	damage_area = GetConVarInt(damage_area_c);
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[64];
	
	Format(description, sizeof(description), "%T", "GetShowDamage", LANG_SERVER);
	
	v_level = AddStammFeature(basename, "VIP Show Damage", description);
	
	Format(description, sizeof(description), "%T", "YouGetShowDamage", LANG_SERVER);
	AddStammFeatureInfo(basename, v_level, description);
}

public Action:eventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (IsStammClientValid(client))
	{
		if (IsClientVip(client, v_level) && ClientWantStammFeature(client, basename))
		{
			new damage;
			
			if (GetStammGame() == GameTF2) damage = GetEventInt(event, "damageamount");
			else damage = GetEventInt(event, "dmg_health");
			
			switch(damage_area)
			{
				case 1:
				{
					PrintCenterText(client, "- %i HP", damage);
				}
				case 2:
				{
					PrintHintText(client, "- %i HP", damage);
				}
				case 3:
				{
					CPrintToChat(client, "{green}- %i HP", damage);
				}
			}
		}
	}
}