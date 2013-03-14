#include <sourcemod>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

new resize;
new Handle:c_resize;

new Float:clientSize[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Stamm Feature ResizePlayer",
	author = "Popoklopsi",
	version = "1.0.0",
	description = "Resizes VIP's",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");

	if (STAMM_GetGame() == GameCSGO) 
		SetFailState("Can't Load Feature. not Supported for your game!");
	
	STAMM_LoadTranslation();
	STAMM_AddFeature("VIP Resize Player", "");
}

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);

	AutoExecConfig_SetFile("resizeplayer", "stamm/features");
	
	c_resize = AutoExecConfig_CreateConVar("resize_amount", "10", "Resize amount in(+)/de(-)crease in percent each block!");
	
	AutoExecConfig(true, "resizeplayer", "stamm/features");
	AutoExecConfig_CleanFile();
}

public OnConfigsExecuted()
{
	resize = GetConVarInt(c_resize);
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:haveDescription[64];
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
	
	for (new i=1; i <= STAMM_GetBlockCount(); i++)
	{
		Format(haveDescription, sizeof(haveDescription), "%T", "GetResize", LANG_SERVER, resize * i);
		
		STAMM_AddFeatureText(STAMM_GetLevel(i), haveDescription);
	}
}

public STAMM_OnClientReady(client)
{
	clientSize[client] = 1.0;

	for (new i=STAMM_GetBlockCount(); i > 0; i--)
	{
		if (STAMM_HaveClientFeature(client, i))
		{
			clientSize[client] = 1.0 + float(resize)/100.0 * i;

			if (clientSize[client] < 0.1) 
				clientSize[client] = 0.1;

			break;
		}
	}
}

public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	STAMM_OnClientChangedFeature(client, true);
}

public STAMM_OnClientChangedFeature(client, bool:mode)
{
	if (STAMM_IsClientValid(client))
	{
		STAMM_OnClientReady(client);

		SetEntPropFloat(client, Prop_Send, "m_flModelScale", clientSize[client]);

		if (STAMM_GetGame() == GameTF2)
			SetEntPropFloat(client, Prop_Send, "m_flHeadScale", clientSize[client]);
	}
}

public OnGameFrame()
{
	if (STAMM_GetGame() == GameTF2)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (STAMM_IsClientValid(i) && clientSize[i] != 1.0)
				SetEntPropFloat(i, Prop_Send, "m_flHeadScale", clientSize[i]);
		}
	}
}