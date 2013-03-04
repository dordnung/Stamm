#include <sourcemod>
#include <colors>
#include <sdktools>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new dur;
new mode_infect;
new lhp;
new timers[MAXPLAYERS+1];

new Handle:dur_c;
new Handle:mode_c;
new Handle:lhp_c;

new bool:Infected[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Stamm Feature KnifeInfect",
	author = "Popoklopsi",
	version = "1.2",
	description = "VIP's can infect players with knife",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	decl String:description[64];

	if (!CColorAllowed(Color_Lightgreen))
	{
		if (CColorAllowed(Color_Lime))
			CReplaceColor(Color_Lightgreen, Color_Lime);
		else if (CColorAllowed(Color_Olive))
			CReplaceColor(Color_Lightgreen, Color_Olive);
	}

	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
		SetFailState("Can't Load Feature, not Supported for your game!");
		
	STAMM_LoadTranslation();
		
	Format(description, sizeof(description), "%T", "GetKnifeInfect", LANG_SERVER);
	
	STAMM_AddFeature("VIP KnifeInfect", description);
}

public OnPluginStart()
{
	HookEvent("player_death", PlayerDeath);
	HookEvent("player_hurt", PlayerHurt);
	HookEvent("player_spawn", PlayerDeath);

	AutoExecConfig_SetFile("knife_infect", "stamm/features");
	
	dur_c = AutoExecConfig_CreateConVar("infect_duration", "0", "Infect Duration, 0 = Next Spawn, x = Time in Seconds");
	mode_c = AutoExecConfig_CreateConVar("infect_mode", "2", "Infect Mode, 0 = Enemy lose HP every second, 1 = Enemy have an infected overlay, 2 = Both");
	lhp_c = AutoExecConfig_CreateConVar("infect_hp", "2", "If mode is 0 or 2: HP lose every Second");
	
	AutoExecConfig_AutoExecConfig();
	AutoExecConfig_CleanFile();
}

public OnConfigsExecuted()
{
	dur = GetConVarInt(dur_c);
	mode_infect = GetConVarInt(mode_c);
	lhp = GetConVarInt(lhp_c);
	
	if (mode_infect != 1 || dur) 
		CreateTimer(1.0, SecondTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:SecondTimer(Handle:timer, any:data)
{
	for (new i=1; i <= MaxClients; i++)
	{
		if (STAMM_IsClientValid(i))
		{
			if (Infected[i])
			{
				if (dur)
				{
					timers[i]--;
					
					if (timers[i] <= 0)
					{
						Infected[i] = false;
						
						if (mode_infect) 
							ClientCommand(i, "r_screenoverlay \"\"");
						
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
	
	if (STAMM_IsClientValid(client) && Infected[client])
	{
		Infected[client] = false;

		if (mode_infect) 
			ClientCommand(client, "r_screenoverlay \"\"");
	}
}

public PlayerHurt(Handle:event, String:name[], bool:dontBroadcast)
{
	new String:weapon[64];
	new String:p_name[128];
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if (STAMM_IsClientValid(client) && STAMM_IsClientValid(attacker))
	{
		if (StrEqual(weapon, "knife") && !Infected[client])
		{
			if (STAMM_HaveClientFeature(attacker))
			{
				Infected[client] = true;
				
				GetClientName(attacker, p_name, sizeof(p_name));
				
				if (mode_infect)
				{
					if (STAMM_GetGame() == GameCSS) 
						ClientCommand(client, "r_screenoverlay effects/tp_eyefx/tp_eyefx");
					else
					{
						ClientCommand(client, "r_drawscreenoverlay 1");
						ClientCommand(client, "r_screenoverlay effects/nightvision");
					}
				}
				
				if (dur)
				{
					timers[client] = dur;
					
					CPrintToChat(client, "{lightgreen}[ {green}Stamm {lightgreen}] %T", "YouGotTimeInfected", LANG_SERVER, p_name, dur);
				}
				else 
					CPrintToChat(client, "{lightgreen}[ {green}Stamm {lightgreen}] %T", "YouGotRoundInfected", LANG_SERVER, p_name);
			}
		}
	}
}