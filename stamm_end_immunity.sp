#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

new bool:RoundEnd;

new particels[MAXPLAYERS + 1][2];

public Plugin:myinfo =
{
	name = "Stamm Feature End of Round Immunity",
	author = "Popoklopsi",
	version = "1.0.0",
	description = "Give VIP's immunity at the end of the round",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.couch-fighter.de/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
}

public OnPluginStart()
{
	HookEvent("teamplay_round_win", RoundWin);
	
	HookEvent("teamplay_round_start", RoundStart);
	HookEvent("teamplay_round_stalemate", RoundStart);
	
	HookEvent("player_death", PlayerDeath);
}

public OnAllPluginsLoaded()
{
	decl String:haveDescription[64];

	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");

	if (STAMM_GetGame() != GameTF2) 
		SetFailState("Can't Load Feature, not Supported for your game!");
	
	STAMM_LoadTranslation();

	Format(haveDescription, sizeof(haveDescription), "%T", "GetImmunity", LANG_SERVER);

	STAMM_AddFeature("VIP End of Round Immunity", haveDescription);
}

public RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{	
	RoundEnd = true;

	for (new i=1; i <= MaxClients; i++)
	{
		if (STAMM_IsClientValid(i) && STAMM_HaveClientFeature(i))
		{
			SetEntProp(i, Prop_Data, "m_takedamage", 1, 1);
			
			ImmuneEffects(i);
		}
	}
}

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	RoundEnd = false;
	
	for (new i=0; i < MAXPLAYERS+1; i++)
		ClearParticles(i);
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!RoundEnd) 
		return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (STAMM_IsClientValid(client))
		ClearParticles(client);

	return Plugin_Continue;
}

public ImmuneEffects(client)
{
	particels[client][0] = EntIndexToEntRef(AttachParticle(client, "player_recent_teleport_red", 2.0));
	particels[client][1] = EntIndexToEntRef(AttachParticle(client, "player_recent_teleport_blue", 2.0));
}

public AttachParticle(entity, String:particleType[], Float:offsetZ)
{
	new particle = CreateEntityByName("info_particle_system");
	
	if (IsValidEntity(particle))
	{
		new Float:pos[3];

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);

		pos[2] += offsetZ;
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(particle, "effect_name", particleType);
		
		DispatchSpawn(particle);
		
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", entity);
		
		ActivateEntity(particle);
		
		AcceptEntityInput(particle, "start");
		
		return particle;
	}
	
	return -1;
}

public ClearParticles(client)
{
	if (particels[client][0] > 0)
	{
		new particle = EntRefToEntIndex(particels[client][0]);
		
		if (particle > MaxClients && IsValidEntity(particle))
			AcceptEntityInput(particle, "Kill");
			
		particels[client][0] = 0;
	}

	if (particels[client][1] > 0)
	{
		new particle = EntRefToEntIndex(particels[client][1]);
		
		if (particle > MaxClients && IsValidEntity(particle))
			AcceptEntityInput(particle, "Kill");
			
		particels[client][1] = 0;
	}
}

public OnGameFrame()
{
	if (RoundEnd)
	{
		for (new i=1; i <= MaxClients; i++)
		{
			if (STAMM_IsClientValid(i) && IsPlayerAlive(i))
			{
				new TFClassType:class = TF2_GetPlayerClass(i);
				
				if (class != TFClass_Scout && !TF2_IsPlayerInCondition(i, TFCond_Charging) && class != TFClass_Unknown)
				{
					if (STAMM_HaveClientFeature(i))
						SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", 400.0);
				}
			}
		}
	}
}