#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "EasyBhop",
	author = "Bara",
	version = "1.0.0",
	description = "Give VIP's eady bunnyhop",
	url = "www.bara.in"
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
	
	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
		SetFailState("Can't Load Feature. Not Supported for your game!");
		
	STAMM_LoadTranslation();

	Format(description, sizeof(description), "%T", "GetEasyBhop", LANG_SERVER);

	STAMM_AddFeature("VIP EasyBhop", description, true, true);
}

public OnPluginStart()
{
	HookEvent("player_jump", eventPlayerJump);
}

public Action:eventPlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (STAMM_IsClientValid(client) && STAMM_HaveClientFeature(client))
		SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
}