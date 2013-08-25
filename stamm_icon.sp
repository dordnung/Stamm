#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new stammview[MAXPLAYERS + 1];
new v_level;

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature Icon",
	author = "Popoklopsi",
	version = "1.1",
	description = "Adds an Stamm Icon on top of a player",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) SetFailState("Can't Load Feature, Stamm is not installed!");
}

public OnPluginStart()
{
	HookEvent("player_spawn", eventPlayerSpawn);
	HookEvent("player_death", eventPlayerDeath);
	
	for (new i=0; i <= MaxClients; i++) stammview[i] = 0;
}

public OnStammReady()
{
	new Handle:myPlugin = GetMyHandle();
	
	GetPluginFilename(myPlugin, basename, sizeof(basename));
	ReplaceString(basename, sizeof(basename), ".smx", "");
	ReplaceString(basename, sizeof(basename), "stamm/", "");
	ReplaceString(basename, sizeof(basename), "stamm\\", "");
	
	LoadTranslations("stamm-features.phrases");
	
	new String:description[64];

	Format(description, sizeof(description), "%T", "GetIcon", LANG_SERVER);
	
	v_level = AddStammFeature(basename, "VIP Icon", description);
	
	Format(description, sizeof(description), "%T", "YouGetIcon", LANG_SERVER);
	AddStammFeatureInfo(basename, v_level, description);
}

public OnClientChangeStammFeature(client, String:base[], mode)
{
	if (StrEqual(basename, base))
	{
		if (IsStammClientValid(client))
		{
			if (!mode) 
			{
				if (stammview[client] != 0) 
				{
					if (IsValidEntity(stammview[client]))
					{
						new String:class[128];
						
						GetEdictClassname(stammview[client], class, sizeof(class));
						
						if (StrEqual(class, "prop_dynamic")) RemoveEdict(stammview[client]);
					}
					stammview[client] = 0;
				}
			}
			else CreateTimer(2.5, CreateStamm, client);
		}
	}
}

public OnMapStart()
{
	PrecacheModel("models/stamm/stammview.mdl", true);
	
	AddFileToDownloadsTable("materials/models/stamm/stammview.vtf");
	AddFileToDownloadsTable("models/stamm/stammview.mdl");
	AddFileToDownloadsTable("materials/models/stamm/stammview.vmt");
	AddFileToDownloadsTable("models/stamm/stammview.vvd");
	AddFileToDownloadsTable("models/stamm/stammview.sw.vtx");
	AddFileToDownloadsTable("models/stamm/stammview.phy");
	AddFileToDownloadsTable("models/stamm/stammview.dx80.vtx");
	AddFileToDownloadsTable("models/stamm/stammview.dx90.vtx");
}

public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsStammClientValid(client))
	{
		if (IsClientVip(client, v_level) && ClientWantStammFeature(client, basename))
		{
			if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && IsPlayerAlive(client)) CreateTimer(2.5, CreateStamm, client);
		}
	}
}

public Action:eventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (stammview[client] != 0) 
	{
		if (IsValidEntity(stammview[client]))
		{
			new String:class[128];
			
			GetEdictClassname(stammview[client], class, sizeof(class));
			
			if (StrEqual(class, "prop_dynamic")) RemoveEdict(stammview[client]);
		}
		stammview[client] = 0;
	}
}

public Action:CreateStamm(Handle:timer, any:client)
{
	if (IsStammClientValid(client))
	{
		if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && IsPlayerAlive(client))
		{
			if (stammview[client] != 0) 
			{
				if (IsValidEntity(stammview[client]))
				{
					new String:class[128];
					
					GetEdictClassname(stammview[client], class, sizeof(class));
					
					if (StrEqual(class, "prop_dynamic")) RemoveEdict(stammview[client]);
				}
			}
			new view = CreateEntityByName("prop_dynamic");
			
			if (view != -1)
			{
				DispatchKeyValue(view, "DefaultAnim", "rotate");
				DispatchKeyValue(view, "spawnflags", "256");
				DispatchKeyValue(view, "model", "models/stamm/stammview.mdl");
				DispatchKeyValue(view, "solid", "6");
				
				if (DispatchSpawn(view))
				{
					decl Float:origin[3];
					
					if (IsValidEntity(view))
					{
						stammview[client] = view;
						
						GetClientAbsOrigin(client, origin);
						
						origin[2] = origin[2] + 90.0;
						
						TeleportEntity(view, origin, NULL_VECTOR, NULL_VECTOR);
						
						new String:steamid[20];
						
						GetClientAuthString(client, steamid, sizeof(steamid));
						DispatchKeyValue(client, "targetname", steamid);
						
						SetVariantString(steamid);
						AcceptEntityInput(view, "SetParent", -1, -1, 0);
					}
				}
			}
		}
	}
}