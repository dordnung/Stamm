#include <sourcemod>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

new hp;
new mhp;

new Handle:c_hp;
new Handle:m_hp;

public Plugin:myinfo =
{
	name = "Stamm Feature KillHP",
	author = "Popoklopsi",
	version = "1.2.0",
	description = "Give VIP's HP every kill",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	STAMM_LoadTranslation();
		
	STAMM_AddFeature("VIP KillHP", "");
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:description[64];
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
	
	Format(description, sizeof(description), "%T", "GetKillHP", LANG_SERVER, hp);
	
	STAMM_AddFeatureText(STAMM_GetLevel(), description);
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("killhp", "stamm/features");

	HookEvent("player_death", PlayerDeath);
	
	c_hp = AutoExecConfig_CreateConVar("killhp_hp", "5", "HP a VIP gets every kill");
	m_hp = AutoExecConfig_CreateConVar("killhp_max", "100", "Max HP of a player");
	
	AutoExecConfig(true, "killhp", "stamm/features");
	AutoExecConfig_CleanFile();
}

public OnConfigsExecuted()
{
	hp = GetConVarInt(c_hp);
	mhp = GetConVarInt(m_hp);
}

public PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (STAMM_IsClientValid(client) && STAMM_IsClientValid(attacker))
	{
		if (STAMM_HaveClientFeature(attacker))
		{
			new newHP = GetClientHealth(attacker) + hp;
			
			if (newHP >= mhp) 
				newHP = mhp;
			
			SetEntityHealth(attacker, newHP);
		}
	}
}