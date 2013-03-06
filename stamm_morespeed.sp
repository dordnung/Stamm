#include <sourcemod>
#include <sdktools>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

new pspeed;
new Handle:c_speed;

public Plugin:myinfo =
{
	name = "Stamm Feature MoreSpeed",
	author = "Popoklopsi",
	version = "1.2.0",
	description = "Give VIP's more speed",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	STAMM_LoadTranslation();
	STAMM_AddFeature("VIP MoreSpeed", "");
}

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);

	AutoExecConfig_SetFile("morespeed", "stamm/features");
	
	c_speed = AutoExecConfig_CreateConVar("speed_increase", "20", "Speed increase in percent each block!");
	
	AutoExecConfig_AutoExecConfig();
	AutoExecConfig_CleanFile();
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:haveDescription[64];
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
	
	for (new i=1; i <= STAMM_GetBlockCount(); i++)
	{
		Format(haveDescription, sizeof(haveDescription), "%T", "GetMoreSpeed", LANG_SERVER, pspeed * i);
		
		STAMM_AddFeatureText(STAMM_GetLevel(i), haveDescription);
	}
}

public OnConfigsExecuted()
{
	pspeed = GetConVarInt(c_speed);
}

public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	STAMM_OnClientChangedFeature(client, true);
}

public STAMM_OnClientChangedFeature(client, bool:mode)
{
	if (STAMM_IsClientValid(client) && IsPlayerAlive(client))
	{
		if (mode)
		{
			for (new i=STAMM_GetBlockCount(); i > 0; i--)
			{
				if (STAMM_HaveClientFeature(client, i))
				{
					new Float:newSpeed;
					
					newSpeed = 1.0 + float(pspeed)/100.0 * i;
					
					SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", newSpeed);

					break;
				}
			}
		}
		else
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
}