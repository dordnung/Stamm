#include <sourcemod>
#include <autoexecconfig>
#include <colors>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

new deathCounter[MAXPLAYERS + 1];

new Handle:deathcount_c;
new Handle:pointscount_c;

new deathcount;
new pointscount;

public Plugin:myinfo =
{
	name = "Stamm Feature LosePoints",
	author = "Popoklopsi",
	version = "1.0.0",
	description = "Non VIP's lose until a specific level points on death",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	decl String:haveDescription[64];

	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");

	STAMM_LoadTranslation();

	Format(haveDescription, sizeof(haveDescription), "%T", "NoLosePoints", LANG_SERVER);
	
	STAMM_AddFeature("VIP LosePoints", haveDescription, false);
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.couch-fighter.de/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
}

public OnPluginStart()
{
	if (!CColorAllowed(Color_Lightgreen))
	{
		if (CColorAllowed(Color_Lime))
			CReplaceColor(Color_Lightgreen, Color_Lime);
		else if (CColorAllowed(Color_Olive))
			CReplaceColor(Color_Lightgreen, Color_Olive);
	}
	
	HookEvent("player_death", PlayerDeath);

	AutoExecConfig_SetFile("losepoints", "stamm/features");

	deathcount_c = AutoExecConfig_CreateConVar("death_count", "2", "How much deaths a player needs to lose points");
	pointscount_c = AutoExecConfig_CreateConVar("points_count", "2", "How much points a player loses after <death_count> deaths");

	AutoExecConfig_AutoExecConfig();
	AutoExecConfig_CleanFile();
}

public OnConfigsExecuted()
{
	deathcount = GetConVarInt(deathcount_c);
	pointscount = GetConVarInt(pointscount_c);
}

public OnClientAuthorized(client, const String:auth[])
{
	deathCounter[client] = 0;
}

public PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (STAMM_IsClientValid(client) && attacker > 0 && client != attacker)
	{
		if (!STAMM_HaveClientFeature(client) && IsClientInGame(attacker) && (GetClientTeam(client) != GetClientTeam(attacker)))
		{
			if (++deathCounter[client] == deathcount)
			{				
				STAMM_DelClientPoints(client, pointscount);

				CPrintToChat(client, "{lightgreen}[ {green}Stamm {lightgreen}] %t", "LosePoints", pointscount, deathcount);

				deathCounter[client] = 0;
			}
		}
	}
}