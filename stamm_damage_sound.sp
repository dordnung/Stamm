#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1


new v_level;

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature Damage Sound",
	author = "Popoklopsi",
	version = "1.0",
	description = "VIP's can hear a damage sound",
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
	
	HookEvent("player_hurt", eventPlayerHurt);
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[64];
	
	Format(description, sizeof(description), "%T", "GetDamageSound", LANG_SERVER);
	
	v_level = AddStammFeature(basename, "VIP Damage Sound", description);
	
	Format(description, sizeof(description), "%T", "YouGetDamageSound", LANG_SERVER);
	AddStammFeatureInfo(basename, v_level, description);
}

public Action:eventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (IsStammClientValid(client))
	{
		if (IsClientVip(client, v_level) && ClientWantStammFeature(client, basename))
		{
			if (GetStammGame() == GameTF2) EmitSoundToClient(client, "physics/body/body_medium_impact_hard6.wav");
			else if (GetStammGame() == GameCSGO) ClientCommand(client, "play physics/body/body_medium_impact_hard6.wav");
			else EmitSoundToClient(client, "physics/cardboard/cardboard_box_break2.wav");
		}
	}
}