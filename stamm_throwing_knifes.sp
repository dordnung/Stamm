#include <sourcemod>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <cssthrowingknives>
#include <updater>

#pragma semicolon 1

new Handle:c_throwingknife;

new throwingknife;

public Plugin:myinfo =
{
	name = "Stamm Feature Throwing Knife",
	author = "Popoklopsi",
	version = "1.3.0",
	description = "Give VIP's every Round x Throwing Knifes",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
		
	if (!LibraryExists("cssthrowingknives")) 	
		SetFailState("Can't Load Feature, Throwing Knifes is not installed!");
	
	if (STAMM_GetGame() != GameCSS) 
		SetFailState("Can't Load Feature, not Supported for your game!");
		
	STAMM_LoadTranslation();
		
	STAMM_AddFeature("VIP Throwing Knife", "");
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:description[64];
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
	
	Format(description, sizeof(description), "%T", "GetThrowingKnife", LANG_SERVER, throwingknife);
	
	STAMM_AddFeatureText(STAMM_GetLevel(), description);
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("throwing_knifes", "stamm/features");

	c_throwingknife = AutoExecConfig_CreateConVar("throwingknife_amount", "3", "x = Amount of throwing knifes VIP's get");
	
	AutoExecConfig(true, "throwing_knifes", "stamm/features");

	AutoExecConfig_CleanFile();
	
	HookEvent("player_spawn", eventPlayerSpawn);
}

public OnConfigsExecuted()
{
	throwingknife = GetConVarInt(c_throwingknife);
}

public STAMM_OnClientChangedFeature(client, bool:mode)
{
	if (!mode) 
		SetClientThrowingKnives(client, 0);
}

public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	CreateTimer(1.0, SetKnifes, client);
}

public Action:SetKnifes(Handle:timer, any:client)
{
	if (STAMM_IsClientValid(client))
	{
		SetClientThrowingKnives(client, 0);
		
		if (STAMM_HaveClientFeature(client))
		{
			if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && IsPlayerAlive(client)) 
				SetClientThrowingKnives(client, throwingknife);
		}
	}
}