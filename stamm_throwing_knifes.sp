#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <cssthrowingknives>

#pragma semicolon 1

new Handle:c_throwingknife;

new v_level;

new throwingknife;

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature Throwing Knife",
	author = "Popoklopsi/Bara",
	version = "1.2",
	description = "Give VIP's every Round x Throwing Knifes",
	url = "www.pupboard.de"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) SetFailState("Can't Load Feature, Stamm is not installed!");
	if (!LibraryExists("cssthrowingknives")) SetFailState("Can't Load Feature, Throwing Knifes is not installed!");
	
	if (GetStammGame() != GameCSS) SetFailState("Can't Load Feature, not Supported for your game!");
}

public OnPluginStart()
{
	new Handle:myPlugin = GetMyHandle();
	
	GetPluginFilename(myPlugin, basename, sizeof(basename));
	ReplaceString(basename, sizeof(basename), ".smx", "");
	ReplaceString(basename, sizeof(basename), "stamm/", "");
	ReplaceString(basename, sizeof(basename), "stamm\\", "");
	
	c_throwingknife = CreateConVar("throwingknife_amount", "3", "x = Amount of throwing knifes VIP's get");
	
	AutoExecConfig(true, "throwing_knifes", "stamm/features");
	
	HookEvent("player_spawn", eventPlayerSpawn);
}

public OnConfigsExecuted()
{
	throwingknife = GetConVarInt(c_throwingknife);
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[64];

	Format(description, sizeof(description), "%T", "GetThrowingKnife", LANG_SERVER, throwingknife);
	
	v_level = AddStammFeature(basename, "VIP Throwing Knife", description);
	
	Format(description, sizeof(description), "%T", "YouGetThrowingKnife", LANG_SERVER, throwingknife);
	AddStammFeatureInfo(basename, v_level, description);
}

public OnClientChangeStammFeature(client, String:base[], mode)
{
	if (mode == 0) SetClientThrowingKnives(client, 0);
}

public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	CreateTimer(1.0, SetKnifes, client);
}

public Action:SetKnifes(Handle:timer, any:client)
{
	if (IsStammClientValid(client))
	{
		SetClientThrowingKnives(client, 0);
		
		if (ClientWantStammFeature(client, basename))
		{
			if (IsClientVip(client, v_level) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && IsPlayerAlive(client)) SetClientThrowingKnives(client, throwingknife);
		}
	}
}