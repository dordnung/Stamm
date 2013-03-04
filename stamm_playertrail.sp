#include <sourcemod>
#include <sdktools>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

new String:material[PLATFORM_MAX_PATH + 1];

new Float:lifetime;

new Handle:beamTimer[MAXPLAYERS+1];
new haveBeam[MAXPLAYERS+1];
new modelInd;

new Handle:c_lifeTime;
new Handle:c_material;

public Plugin:myinfo =
{
	name = "Stamm Feature PlayerTrail",
	author = "Popoklopsi",
	version = "1.2.0",
	description = "Give VIP's a player trail",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.couch-fighter.de/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
}

public OnAllPluginsLoaded()
{
	decl String:description[64];

	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");

	STAMM_LoadTranslation();
		
	Format(description, sizeof(description), "%T", "GetPlayerTrail", LANG_SERVER);
	
	STAMM_AddFeature("VIP PlayerTrail", description);
}

public OnPluginStart()
{
	HookEvent("player_spawn", eventPlayerSpawn);
	HookEvent("player_death", eventPlayerDeath);

	AutoExecConfig_SetFile("playertrail", "stamm/features");
	
	c_lifeTime = AutoExecConfig_CreateConVar("ptrail_lifetime", "4.0", "Lifetime of each trail element");
	c_material = AutoExecConfig_CreateConVar("ptrail_material", "sprites/laserbeam.vmt", "Material to use, start after materials/");
	
	AutoExecConfig_AutoExecConfig();
	AutoExecConfig_CleanFile();
}

public OnConfigsExecuted()
{
	decl String:materialPrecache[PLATFORM_MAX_PATH + 1];

	lifetime = GetConVarFloat(c_lifeTime);

	GetConVarString(c_material, materialPrecache, sizeof(materialPrecache));

	Format(material, sizeof(material), "materials/%s", materialPrecache);

	modelInd = PrecacheModel(material, true);

	if (FileExists(material))
	{
		AddFileToDownloadsTable(material);

		strcopy(materialPrecache, sizeof(materialPrecache), material);

		ReplaceString(materialPrecache, sizeof(materialPrecache), ".vmt", ".vtf", false);
		AddFileToDownloadsTable(materialPrecache);
	}
}

public OnMapStart()
{
	for (new i = 1; i <= MaxClients; i++) 
		DeleteTrail(i);
}

public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (STAMM_IsClientValid(client))
	{
		DeleteTrail(client);

		if (STAMM_HaveClientFeature(client))
		{
			if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3)) 
				CreateTimer(2.5, SetupTrail, client);
		}
	}
}

public OnClientDisconnect(client)
{	
	DeleteTrail(client);
}

public Action:eventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	DeleteTrail(client);
}

public Action:SetupTrail(Handle:timer, any:client)
{
	if (STAMM_IsClientValid(client))
	{
		if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && IsPlayerAlive(client))
		{
			DeleteTrail(client);

			if (STAMM_GetGame() == GameCSGO)
				beamTimer[client] = CreateTimer(0.1, CreateTrail, client, TIMER_REPEAT);
			else
				CreateTrail2(client);
		}
	}
}

public STAMM_OnClientChangedFeature(client, bool:mode)
{
	if (!mode) 
		DeleteTrail(client);
}

public Action:CreateTrail(Handle:timer, any:client)
{
	if (STAMM_IsClientValid(client))
	{
		decl Float:velocity[3];
		new color[4];

		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);		

		if (!(velocity[0] == 0.0 && velocity[1] == 0.0 && velocity[2] == 0.0))
			return Plugin_Continue;

		new ent = GetPlayerWeaponSlot(client, 2);

		if (ent == -1)
			ent = client;

		if (GetClientTeam(client) == 2) 
			color[0] = 255;
		else
			color[2] = 255;

		color[3] = 255;

		TE_SetupBeamFollow(ent, modelInd, 0, lifetime, 3.0, 3.0, 1, color);
		TE_SendToAll();
	}
	else 
	{
		DeleteTrail(client);

		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public CreateTrail2(client)
{
	if (STAMM_IsClientValid(client) && haveBeam[client] == -1)
	{
		new ent = CreateEntityByName("env_spritetrail");

		if (ent != -1 && IsValidEntity(ent))
		{
			new Float:Orig[3];
			decl String:name[MAX_NAME_LENGTH + 1];

			GetClientName(client, name, sizeof(name));

			DispatchKeyValue(client, "targetname", name);
			DispatchKeyValue(ent, "parentname", name);
			DispatchKeyValueFloat(ent, "lifetime", lifetime);
			DispatchKeyValueFloat(ent, "endwidth", 3.0);
			DispatchKeyValueFloat(ent, "startwidth", 3.0);
			DispatchKeyValue(ent, "spritename", material);
			DispatchKeyValue(ent, "renderamt", "255");
			
			if (GetClientTeam(client) == 2) 
				DispatchKeyValue(ent, "rendercolor", "255 0 0 255");
				
			if (GetClientTeam(client) == 3) 
				DispatchKeyValue(ent, "rendercolor", "0 0 255 255");
				
			DispatchKeyValue(ent, "rendermode", "5");
			
			DispatchSpawn(ent);

			GetClientAbsOrigin(client, Orig);
			
			Orig[2] += 40.0;
			
			TeleportEntity(ent, Orig, NULL_VECTOR, NULL_VECTOR);
			
			SetVariantString(name);
			AcceptEntityInput(ent, "SetParent"); 
			SetEntPropFloat(ent, Prop_Send, "m_flTextureRes", 0.05);

			haveBeam[client] = ent;
		}
	}
}

public DeleteTrail(client)
{
	if (beamTimer[client] != INVALID_HANDLE)
		CloseHandle(beamTimer[client]);

	beamTimer[client] = INVALID_HANDLE;

	new ent = haveBeam[client];

	if (ent != -1 && IsValidEntity(ent))
	{
		decl String:class[128];
		
		GetEdictClassname(ent, class, sizeof(class));
		
		if (StrEqual(class, "env_spritetrail")) 
			RemoveEdict(ent);
	}

	haveBeam[client] = -1;
}