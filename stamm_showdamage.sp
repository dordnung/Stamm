#include <sourcemod>
#include <colors>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new Handle:damage_area_c;

new damage_area;

public Plugin:myinfo =
{
	name = "Stamm Feature Show Damage",
	author = "Popoklopsi",
	version = "1.2",
	description = "VIP's can see the damage they done",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	decl String:description[64];

	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	STAMM_LoadTranslation();
		
	Format(description, sizeof(description), "%T", "GetShowDamage", LANG_SERVER);
	
	STAMM_AddFeature("VIP Show Damage", description);
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("show_damage", "stamm/features");

	damage_area_c = AutoExecConfig_CreateConVar("damage_area", "1", "Textarea where to show message, 1=Center Text, 2=Hint Text, 3=Chat");
	
	AutoExecConfig_AutoExecConfig();
	AutoExecConfig_CleanFile();
	
	HookEvent("player_hurt", eventPlayerHurt);
}

public OnConfigsExecuted()
{
	damage_area = GetConVarInt(damage_area_c);
}

public Action:eventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			new damage;
			
			if (STAMM_GetGame() == GameTF2) 
				damage = GetEventInt(event, "damageamount");
			else if (STAMM_GetGame() == GameDOD)
				damage = GetEventInt(event, "damage");
			else 
				damage = GetEventInt(event, "dmg_health");
			
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