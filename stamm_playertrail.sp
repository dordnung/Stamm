#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new v_level;

new Float:lifetime;

new bool:haveBeam[MAXPLAYERS+1];
new Float:PlayerVector[MAXPLAYERS+1][3];

new String:basename[64];

new Handle:c_lifeTime;

public Plugin:myinfo =
{
	name = "Stamm Feature PlayerTrail",
	author = "Popoklopsi",
	version = "1.1",
	description = "Give VIP's a player trail",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) SetFailState("Can't Load Feature, Stamm is not installed!");
	
	if (GetStammGame() != GameCSS) SetFailState("Can't Load Feature, not Supported for your game!");
}

public OnPluginStart()
{
	new Handle:myPlugin = GetMyHandle();
	
	GetPluginFilename(myPlugin, basename, sizeof(basename));
	ReplaceString(basename, sizeof(basename), ".smx", "");
	ReplaceString(basename, sizeof(basename), "stamm/", "");
	ReplaceString(basename, sizeof(basename), "stamm\\", "");
	
	HookEvent("player_spawn", eventPlayerSpawn);
	HookEvent("player_disconnect", eventPlayerDisc);
	HookEvent("player_death", eventPlayerDeath);
	
	c_lifeTime = CreateConVar("ptrail_lifetime", "4.0", "Lifetime of each trail element");
	
	AutoExecConfig(true, "playertrail", "stamm/features");
}

public OnConfigsExecuted()
{
	lifetime = GetConVarFloat(c_lifeTime);
	
	PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[64];

	Format(description, sizeof(description), "%T", "GetPlayerTrail", LANG_SERVER);
	
	v_level = AddStammFeature(basename, "VIP PlayerTrail", description);
	
	Format(description, sizeof(description), "%T", "YouGetPlayerTrail", LANG_SERVER);
	AddStammFeatureInfo(basename, v_level, description);
}

public OnMapStart()
{
	for (new i = 1; i <= MaxClients; i++) haveBeam[i] = false;
}

public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsStammClientValid(client))
	{
		if (IsClientVip(client, v_level) && ClientWantStammFeature(client, basename))
		{
			if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && IsPlayerAlive(client)) CreateTimer(2.5, SetupTrail, client);
		}
	}
}

public Action:eventPlayerDisc(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	haveBeam[client] = false;
}

public Action:eventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	haveBeam[client] = false;
}

public Action:SetupTrail(Handle:timer, any:client)
{
	if (IsStammClientValid(client))
	{
		if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && IsPlayerAlive(client))
		{
			GetClientAbsOrigin(client, PlayerVector[client]);
			
			haveBeam[client] = true;
			
			CreateTimer(0.1, CreateTrail, client, TIMER_REPEAT);
		}
	}
}

public OnClientChangeStammFeature(client, String:base[], mode)
{
	if (StrEqual(basename, base) && mode == 0) haveBeam[client] = false;
}

public Action:CreateTrail(Handle:timer, any:client)
{
	if (IsStammClientValid(client) && haveBeam[client])
	{
		new ent = CreateEntityByName("env_beam");

		if (ent != -1)
		{
			new Float:Orig[3];
			
			GetClientAbsOrigin(client, Orig);
			
			Orig[2] += 40.0;
			
			TeleportEntity(ent, PlayerVector[client], NULL_VECTOR, NULL_VECTOR);
			
			SetEntityModel(ent, "sprites/laserbeam.vmt");
			
			SetEntPropVector(ent, Prop_Data, "m_vecEndPos", Orig);
			
			DispatchKeyValue(ent, "targetname", "beam");
			if (GetClientTeam(client) == 2) DispatchKeyValue(ent, "rendercolor", "255 0 0");
			if (GetClientTeam(client) == 3) DispatchKeyValue(ent, "rendercolor", "0 0 255");
			DispatchKeyValue(ent, "renderamt", "100");
			
			DispatchSpawn(ent);
			
			SetEntPropFloat(ent, Prop_Data, "m_fWidth", 3.0);
			SetEntPropFloat(ent, Prop_Data, "m_fEndWidth", 3.0);
			
			ActivateEntity(ent);
			AcceptEntityInput(ent, "TurnOn");

			PlayerVector[client] = Orig;
			
			CreateTimer(lifetime, DeleteTrail, ent);
		}
	}
	else return Plugin_Stop;
	
	return Plugin_Continue;
}

public Action:DeleteTrail(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		new String:class[128];
		
		GetEdictClassname(ent, class, sizeof(class));
		
		if (StrEqual(class, "env_beam")) RemoveEdict(ent);
	}
}