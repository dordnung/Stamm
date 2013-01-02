#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new v_level;

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature Instant Defuse",
	author = "Popoklopsi",
	version = "1.1",
	description = "VIP's can defuse the bomb instantly",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) SetFailState("Can't Load Feature, Stamm is not installed!");
	
	if (GetStammGame() == GameTF2) SetFailState("Can't Load Feature, not Supported for your game!");
}

public OnPluginStart()
{
	new Handle:myPlugin = GetMyHandle();
	
	GetPluginFilename(myPlugin, basename, sizeof(basename));
	ReplaceString(basename, sizeof(basename), ".smx", "");
	ReplaceString(basename, sizeof(basename), "stamm/", "");
	ReplaceString(basename, sizeof(basename), "stamm\\", "");
	
	HookEvent("bomb_begindefuse", Event_Defuse);
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[64];
	
	Format(description, sizeof(description), "%T", "GetInstantDefuse", LANG_SERVER);
	
	v_level = AddStammFeature(basename, "VIP Instant Defuse", description);
	
	Format(description, sizeof(description), "%T", "YouGetInstantDefuse", LANG_SERVER);
	AddStammFeatureInfo(basename, v_level, description);
}

public Event_Defuse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsStammClientValid(client))
	{
		if (IsClientVip(client, v_level) && ClientWantStammFeature(client, basename)) CreateTimer(0.5, setCountdown, client);
	}
}

public Action:setCountdown(Handle:timer, any:client)
{
	new bombent = FindEntityByClassname(-1, "planted_c4");
	
	if (bombent) SetEntPropFloat(bombent, Prop_Send, "m_flDefuseCountDown", 0.1);
}