#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <stamm>

#define HEColor 	{225,0,0,225}
#define FlashColor 	{255,255,0,225}
#define SmokeColor	{0,225,0,225}
#define DecoyColor	{139,090,043,225}
#define MoloColor	{255,069,0,225}

#pragma semicolon 1

new v_level;
new BeamSprite;

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature GrenadeTrail",
	author = "Popoklopsi",
	version = "1.2",
	description = "Give VIP's a grenade trail",
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
	
	HookEvent("weapon_fire", eventWeaponFire);
}

public OnMapStart()
{
	BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[64];

	Format(description, sizeof(description), "%T", "GetGrenadeTrail", LANG_SERVER);
	
	v_level = AddStammFeature(basename, "VIP Grenade Trail", description);
	
	Format(description, sizeof(description), "%T", "YouGetGrenadeTrail", LANG_SERVER);
	AddStammFeatureInfo(basename, v_level, description);
}

public Action:eventWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weapon[64];
	
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if (IsStammClientValid(client))
	{
		if (ClientWantStammFeature(client, basename) && IsClientVip(client, v_level))
		{
			if (StrEqual(weapon, "hegrenade"))
			{
				CreateTimer(0.15, SetupHE, client);
			}
			else if (StrEqual(weapon, "flashbang"))
			{
				CreateTimer(0.15, SetupFlash, client);
			}
			else if (StrEqual(weapon, "smokegrenade"))
			{
				CreateTimer(0.15, SetupSmoke, client);
			}
			else if (StrEqual(weapon, "decoy"))
			{
				CreateTimer(0.15, SetupDecoy, client);
			}
			else if (StrEqual(weapon, "molotov"))
			{
				CreateTimer(0.15, SetupMolo, client);
			}
		}
	}
}

public Action:SetupHE(Handle:timer, any:client)
{
	new ent = FindEntityByClassname(-1, "hegrenade_projectile");
	
	AddTrail(client, ent, HEColor);
}

public Action:SetupFlash(Handle:timer, any:client)
{
	new ent = FindEntityByClassname(-1, "flashbang_projectile");
	
	AddTrail(client, ent, FlashColor);
}

public Action:SetupSmoke(Handle:timer, any:client)
{
	new ent = FindEntityByClassname(-1, "smokegrenade_projectile");
	
	AddTrail(client, ent, SmokeColor);
}

public Action:SetupDecoy(Handle:timer, any:client)
{
	new ent = FindEntityByClassname(-1, "decoy_projectile");
	
	AddTrail(client, ent, DecoyColor);
}

public Action:SetupMolo(Handle:timer, any:client)
{
	new ent = FindEntityByClassname(-1, "molotov_projectile");
	
	AddTrail(client, ent, MoloColor);
}

public AddTrail(client, ent, tcolor[4])
{
	if (ent != -1)
	{
		new owner = GetEntPropEnt(ent, Prop_Send, "m_hThrower");
		
		if (IsValidEntity(ent) && owner == client)
		{
			TE_SetupBeamFollow(ent, BeamSprite,	0, 5.0, 3.0, 3.0, 1, tcolor);
			TE_SendToAll();
		}
	}
}