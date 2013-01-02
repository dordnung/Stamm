#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new Handle:hear_all;

new v_level;
new hear;

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature Holy Granade",
	author = "Popoklopsi",
	version = "1.2",
	description = "Give VIP's a holy granade",
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
	
	hear_all = CreateConVar("holy_hear", "1", "0=Every one hear Granade, 1=Only Player");
	
	AutoExecConfig(true, "holy_grenade", "stamm/features");
	
	HookEvent("weapon_fire", eventWeaponFire);
	HookEvent("hegrenade_detonate", eventHeDetonate);
}

public OnConfigsExecuted()
{
	hear = GetConVarInt(hear_all);
	
	AddFileToDownloadsTable("sound/music/stamm/throw.mp3");
	AddFileToDownloadsTable("sound/music/stamm/explode.mp3");
	AddFileToDownloadsTable("materials/models/stamm/holy_grenade.vtf");
	AddFileToDownloadsTable("models/stamm/holy_grenade.mdl");
	AddFileToDownloadsTable("materials/models/stamm/holy_grenade.vmt");
	AddFileToDownloadsTable("models/stamm/holy_grenade.vvd");
	AddFileToDownloadsTable("models/stamm/holy_grenade.sw.vtx");
	AddFileToDownloadsTable("models/stamm/holy_grenade.phy");
	AddFileToDownloadsTable("models/stamm/holy_grenade.dx80.vtx");
	AddFileToDownloadsTable("models/stamm/holy_grenade.dx90.vtx");
	
	PrecacheModel("models/stamm/holy_grenade.mdl", true);
	PrecacheModel("materials/sprites/splodesprite.vmt", true);
	PrecacheSound("music/stamm/throw.mp3", true);
	PrecacheSound("music/stamm/explode.mp3", true);
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[64];

	Format(description, sizeof(description), "%T", "GetHoly", LANG_SERVER);
	
	v_level = AddStammFeature(basename, "VIP Holy Granade", description);
	
	Format(description, sizeof(description), "%T", "YouGetHoly", LANG_SERVER);
	AddStammFeatureInfo(basename, v_level, description);
}

public Action:eventWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new String:weapon[256];
	
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if (IsStammClientValid(client))
	{
		if (ClientWantStammFeature(client, basename))
		{
			if (StrEqual(weapon, "hegrenade")) 
			{
				if (IsClientVip(client, v_level))
				{
					if (hear) 
					{
						if (GetStammGame() != GameCSGO) EmitSoundToClient(client, "music/stamm/throw.mp3");
						else ClientCommand(client, "play music/stamm/throw.mp3");
					}
					else
					{
						if (GetStammGame() != GameCSGO) EmitSoundToAll("music/stamm/throw.mp3");
						else
						{
							for (new i=0; i <= MaxClients; i++)
							{
								if (IsStammClientValid(i)) ClientCommand(i, "play music/stamm/throw.mp3");
							}
						}
					}
					
					CreateTimer(0.25, change, client);
				}
			}
		}
	}
}

public Action:eventHeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new Float:origin[3];
	
	origin[0] = float(GetEventInt(event, "x"));
	origin[1] = float(GetEventInt(event, "y"));
	origin[2] = float(GetEventInt(event, "z"));
	
	if (IsStammClientValid(client))
	{
		if (ClientWantStammFeature(client, basename))
		{
			if (IsClientVip(client, v_level))
			{
				new explode = CreateEntityByName("env_explosion");
				new shake = CreateEntityByName("env_shake");
				
				if (explode != -1 && shake != -1)
				{
					DispatchKeyValue(explode, "fireballsprite", "sprites/splodesprite.vmt");
					DispatchKeyValue(explode, "iMagnitude", "20");
					DispatchKeyValue(explode, "iRadiusOverride", "500");
					DispatchKeyValue(explode, "rendermode", "5");
					DispatchKeyValue(explode, "spawnflags", "2");
					
					DispatchKeyValue(shake, "amplitude", "4");
					DispatchKeyValue(shake, "duration", "5");
					DispatchKeyValue(shake, "frequency", "255");
					DispatchKeyValue(shake, "radius", "500");
					DispatchKeyValue(shake, "spawnflags", "0");
					
					DispatchSpawn(explode);
					DispatchSpawn(shake);
					
					TeleportEntity(explode, origin, NULL_VECTOR, NULL_VECTOR);
					TeleportEntity(shake, origin, NULL_VECTOR, NULL_VECTOR);
					
					AcceptEntityInput(explode, "Explode");
					AcceptEntityInput(shake, "StartShake");
					
				}
				
				if (hear) 
				{
					if (GetStammGame() != GameCSGO) EmitSoundToClient(client, "music/stamm/explode.mp3");
					else ClientCommand(client, "play music/stamm/explode.mp3");
				}
				else
				{
					if (GetStammGame() != GameCSGO) EmitSoundToAll("music/stamm/explode.mp3");
					else
					{
						for (new i=0; i <= MaxClients; i++)
						{
							if (IsStammClientValid(i)) ClientCommand(i, "play music/stamm/explode.mp3");
						}
					}
				}
			}
		}
	}
}

public Action:change(Handle:timer, any:client)
{
	new ent = -1;
	
	ent = FindEntityByClassname(ent, "hegrenade_projectile");
	
	if (ent > -1)
	{
		new owner = GetEntPropEnt(ent, Prop_Send, "m_hThrower");
		
		if (IsValidEntity(ent) && owner == client) SetEntityModel(ent, "models/stamm/holy_grenade.mdl");
	}
}
