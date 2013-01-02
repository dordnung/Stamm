#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new hp;
new mhp;
new v_level;

new Handle:c_hp;
new Handle:m_hp;

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature KillHP",
	author = "Popoklopsi",
	version = "1.1",
	description = "Give VIP's HP every kill",
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
	
	HookEvent("player_death", PlayerDeath);
	
	c_hp = CreateConVar("killhp_hp", "5", "HP a VIP gets every kill");
	m_hp = CreateConVar("killhp_max", "100", "Max HP of a player");
	
	AutoExecConfig(true, "killhp", "stamm/features");
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
	
	if (IsStammClientValid(client) && IsStammClientValid(attacker))
	{
		if (IsClientVip(attacker, v_level) && ClientWantStammFeature(attacker, basename))
		{
			new newHP = GetClientHealth(attacker) + hp;
			
			if (newHP >= mhp) newHP = mhp;
			
			SetEntityHealth(attacker, newHP);
		}
	}
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[256];
	
	Format(description, sizeof(description), "%T", "GetKillHP", LANG_SERVER, hp);
	
	v_level = AddStammFeature(basename, "VIP KillHP", description);
	
	Format(description, sizeof(description), "%T", "YouGetKillHP", LANG_SERVER, hp);
	AddStammFeatureInfo(basename, v_level, description);
}