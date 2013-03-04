#include <sourcemod>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new grav;
new Handle:c_grav;

public Plugin:myinfo =
{
	name = "Stamm Feature LessGravity",
	author = "Popoklopsi",
	version = "1.2",
	description = "Give VIP's less gravity",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	STAMM_LoadTranslation();
	STAMM_AddFeature("VIP KnifeInfect", "");
}

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);

	AutoExecConfig_SetFile("lessgravity", "stamm/features");
	
	c_grav = AutoExecConfig_CreateConVar("gravity_decrease", "10", "Gravity decrease in percent each block!");
	
	AutoExecConfig_AutoExecConfig();
	AutoExecConfig_CleanFile();
}

public OnConfigsExecuted()
{
	grav = GetConVarInt(c_grav);
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:haveDescription[64];
	
	for (new i=1; i <= STAMM_GetBlockCount(); i++)
	{
		Format(haveDescription, sizeof(haveDescription), "%T", "GetLessGravity", LANG_SERVER, grav * i);
		
		STAMM_AddFeatureText(STAMM_GetLevel(i), haveDescription);
	}
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
		new Float:newGrav;
		
		if (mode)
		{
			for (new i=STAMM_GetBlockCount(); i > 0; i--)
			{
				if (STAMM_HaveClientFeature(client, i))
				{
					newGrav = 1.0 - float(grav)/100.0 * i;

					if (newGrav < 0.1) 
						newGrav = 0.1;
					
					SetEntityGravity(client, newGrav);

					break;
				}
			}
		}
		else
			SetEntityGravity(client, 1.0);
	}
}