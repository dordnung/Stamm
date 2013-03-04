#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Stamm Feature Instant Defuse",
	author = "Popoklopsi",
	version = "1.2.0",
	description = "VIP's can defuse the bomb instantly",
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
	
	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
		SetFailState("Can't Load Feature, not Supported for your game!");
		
	STAMM_LoadTranslation();
		
	Format(description, sizeof(description), "%T", "GetInstantDefuse", LANG_SERVER);
	
	STAMM_AddFeature("VIP Instant Defuse", description);
}

public OnPluginStart()
{
	HookEvent("bomb_begindefuse", Event_Defuse);
}

public Event_Defuse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client)) 
			CreateTimer(0.5, setCountdown, client);
	}
}

public Action:setCountdown(Handle:timer, any:client)
{
	new bombent = FindEntityByClassname(-1, "planted_c4");
	
	if (bombent) 
		SetEntPropFloat(bombent, Prop_Send, "m_flDefuseCountDown", 0.1);
}