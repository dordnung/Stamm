#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>
#include <hgr>

#pragma semicolon 1

new grap;
new hook;
new rope;

public Plugin:myinfo =
{
	name = "Stamm Feature Hook Grape Rope",
	author = "Popoklopsi",
	version = "1.0.0",
	description = "Allows VIP's to grap, hook or rope",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
		
	STAMM_LoadTranslation();
		
	STAMM_AddFeature("VIP HookGrapeRope", "");
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:description[64];
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);

	grap = STAMM_GetBlockOfName("grap");
	hook = STAMM_GetBlockOfName("hook");
	rope = STAMM_GetBlockOfName("rope");

	if (grap != -1)
	{
		Format(description, sizeof(description), "%T", "GetGrap", LANG_SERVER);
		STAMM_AddFeatureText(STAMM_GetLevel(grap), description);
	}

	if (hook != -1)
	{
		Format(description, sizeof(description), "%T", "GetHook", LANG_SERVER);
		STAMM_AddFeatureText(STAMM_GetLevel(hook), description);
	}

	if (rope != -1)
	{
		Format(description, sizeof(description), "%T", "GetRope", LANG_SERVER);
		STAMM_AddFeatureText(STAMM_GetLevel(rope), description);
	}
}

public STAMM_OnClientReady(client)
{
	if (STAMM_IsClientValid(client))
	{
		if (hook != -1 && STAMM_HaveClientFeature(client, hook))
			HGR_ClientAccess(client, 0, 0);
		else
			HGR_ClientAccess(client, 1, 0);

		if (grap != -1 && STAMM_HaveClientFeature(client, grap))
			HGR_ClientAccess(client, 0, 1);
		else
			HGR_ClientAccess(client, 1, 1);

		if (rope != -1 && STAMM_HaveClientFeature(client, rope))
			HGR_ClientAccess(client, 0, 2);
		else
			HGR_ClientAccess(client, 1, 2);
	}
	else
	{
		HGR_ClientAccess(client, 1, 0);
		HGR_ClientAccess(client, 1, 1);
		HGR_ClientAccess(client, 1, 2);
	}
}