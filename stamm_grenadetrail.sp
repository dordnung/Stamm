#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#define HEColor 	{225,0,0,225}
#define FlashColor 	{255,255,0,225}
#define SmokeColor	{0,225,0,225}
#define DecoyColor	{139,090,043,225}
#define MoloColor	{255,069,0,225}

#pragma semicolon 1

new BeamSprite;

public Plugin:myinfo =
{
	name = "Stamm Feature GrenadeTrail",
	author = "Popoklopsi",
	version = "1.3.0",
	description = "Give VIP's a grenade trail",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
}

public OnAllPluginsLoaded()
{
	decl String:description[64];

	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	if (STAMM_GetGame() == GameDOD || STAMM_GetGame() == GameTF2) 
		SetFailState("Can't Load Feature, not Supported for your game!");
		
	STAMM_LoadTranslation();
		
	Format(description, sizeof(description), "%T", "GetGrenadeTrail", LANG_SERVER);
	
	STAMM_AddFeature("VIP Grenade Trail", description);
}

public OnPluginStart()
{
	HookEvent("weapon_fire", eventWeaponFire);
}

public OnMapStart()
{
	BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public Action:eventWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:weapon[64];
	
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			if (StrEqual(weapon, "hegrenade"))
				CreateTimer(0.15, SetupHE, client);

			else if (StrEqual(weapon, "flashbang"))
				CreateTimer(0.15, SetupFlash, client);

			else if (StrEqual(weapon, "smokegrenade"))
				CreateTimer(0.15, SetupSmoke, client);
				
			else if (StrEqual(weapon, "decoy"))
				CreateTimer(0.15, SetupDecoy, client);
				
			else if (StrEqual(weapon, "molotov"))
				CreateTimer(0.15, SetupMolo, client);
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