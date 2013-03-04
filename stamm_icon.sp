#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

new stammview[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Stamm Feature Icon",
	author = "Popoklopsi",
	version = "1.2",
	description = "Adds an Stamm Icon on top of a player",
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
		
	Format(description, sizeof(description), "%T", "GetIcon", LANG_SERVER);
	
	STAMM_AddFeature("VIP Icon", description);
}

public OnPluginStart()
{
	HookEvent("player_spawn", eventPlayerSpawn);
	HookEvent("player_death", eventPlayerDeath);
	
	for (new i=0; i <= MaxClients; i++) 
		stammview[i] = 0;
}

public STAMM_OnClientChangedFeature(client, bool:mode)
{
	if (STAMM_IsClientValid(client))
	{
		if (!mode)
		{
			if (stammview[client] != 0) 
			{
				if (IsValidEntity(stammview[client]))
				{
					decl String:class[128];
					
					GetEdictClassname(stammview[client], class, sizeof(class));
					
					if (StrEqual(class, "prop_dynamic")) 
						RemoveEdict(stammview[client]);
				}
				
				stammview[client] = 0;
			}
		}
		else if (STAMM_HaveClientFeature(client))
			CreateTimer(2.5, CreateStamm, client);
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
	
	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && IsPlayerAlive(client)) 
				CreateTimer(2.5, CreateStamm, client);
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
			decl String:class[128];
			
			GetEdictClassname(stammview[client], class, sizeof(class));
			
			if (StrEqual(class, "prop_dynamic")) 
				RemoveEdict(stammview[client]);
		}
		
		stammview[client] = 0;
	}
}

public Action:CreateStamm(Handle:timer, any:client)
{
	if (STAMM_IsClientValid(client))
	{
		if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && IsPlayerAlive(client))
		{
			if (stammview[client] != 0) 
			{
				if (IsValidEntity(stammview[client]))
				{
					decl String:class[128];
					
					GetEdictClassname(stammview[client], class, sizeof(class));
					
					if (StrEqual(class, "prop_dynamic")) 
						RemoveEdict(stammview[client]);
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
					decl String:steamid[20];
					
					if (IsValidEntity(view))
					{
						stammview[client] = view;
						
						GetClientAbsOrigin(client, origin);
						
						origin[2] = origin[2] + 90.0;
						
						TeleportEntity(view, origin, NULL_VECTOR, NULL_VECTOR);
						
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