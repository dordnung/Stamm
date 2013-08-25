#include <sourcemod>
#include <colors>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new dur;
new mode_infect;
new lhp;
new timers[MAXPLAYERS+1];
new v_level;

new Handle:dur_c;
new Handle:mode_c;
new Handle:lhp_c;

new bool:Infected[MAXPLAYERS+1];

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature KnifeInfect",
	author = "Popoklopsi",
	version = "1.1",
	description = "VIP's can infect players with knife",
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
	
	HookEvent("player_death", PlayerDeath);
	HookEvent("player_hurt", PlayerHurt);
	HookEvent("player_spawn", PlayerDeath);
	
	dur_c = CreateConVar("infect_duration", "0", "Infect Duration, 0 = Next Spawn, x = Time in Seconds");
	mode_c = CreateConVar("infect_mode", "2", "Infect Mode, 0 = Enemy lose HP every second, 1 = Enemy have an infected overlay, 2 = Both");
	lhp_c = CreateConVar("infect_hp", "2", "If mode is 0 or 2: HP lose every Second");
	
	AutoExecConfig(true, "knife_infect", "stamm/features");
}

public OnConfigsExecuted()
{
	dur = GetConVarInt(dur_c);
	mode_infect = GetConVarInt(mode_c);
	lhp = GetConVarInt(lhp_c);
	
	if (mode_infect != 1 || dur) CreateTimer(1.0, SecondTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:SecondTimer(Handle:timer, any:data)
{
	for (new i=1; i <= MaxClients; i++)
	{
		if (IsStammClientValid(i))
		{
			if (Infected[i])
			{
				if (dur)
				{
					timers[i]--;
					
					if (timers[i] <= 0)
					{
						Infected[i] = false;
						if (mode_infect) ClientCommand(i, "r_screenoverlay \"\"");
						
						continue;
					}
				}
				if (mode_infect != 1)
				{
					new newhp = GetClientHealth(i) - lhp;
					if (newhp <= 0)
					{
						newhp = 0;
						ForcePlayerSuicide(i);
					}
					SetEntityHealth(i, newhp);
				}
			}
		}
	}
	return Plugin_Continue;
}

public PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsStammClientValid(client) && Infected[client])
	{
		Infected[client] = false;

		if (mode_infect) ClientCommand(client, "r_screenoverlay \"\"");
	}
}

public PlayerHurt(Handle:event, String:name[], bool:dontBroadcast)
{
	new String:weapon[64];
	new String:p_name[128];
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if (IsStammClientValid(client) && IsStammClientValid(attacker))
	{
		if (StrEqual(weapon, "knife") && !Infected[client])
		{
			if (IsClientVip(attacker, v_level) && ClientWantStammFeature(attacker, basename))
			{
				Infected[client] = true;
				GetClientName(attacker, p_name, sizeof(p_name));
				
				if (mode_infect)
				{
					if (GetStammGame() == GameCSS) ClientCommand(client, "r_screenoverlay effects/tp_eyefx/tp_eyefx");
					else
					{
						ClientCommand(client, "r_drawscreenoverlay 1");
						ClientCommand(client, "r_screenoverlay effects/nightvision");
					}
				}
				
				if (dur)
				{
					timers[client] = dur;
					CPrintToChat(client, "{olive}[ {green}Stamm {olive}] %T", "YouGotTimeInfected", LANG_SERVER, p_name, dur);
				}
				else CPrintToChat(client, "{olive}[ {green}Stamm {olive}] %T", "YouGotRoundInfected", LANG_SERVER, p_name);
			}
		}
	}
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[256];
	
	Format(description, sizeof(description), "%T", "GetKnifeInfect", LANG_SERVER);
	
	v_level = AddStammFeature(basename, "VIP KnifeInfect", description);
	
	Format(description, sizeof(description), "%T", "YouGetKnifeInfect", LANG_SERVER);
	AddStammFeatureInfo(basename, v_level, description);
}