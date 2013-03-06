#include <sourcemod>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

new bool:bPressed[MAXPLAYERS+1] = false;

new Handle:c_strong;
new strong;

public Plugin:myinfo =
{
	name = "Stamm Feature LongJump",
	author = "Popoklopsi",
	version = "1.0.0",
	description = "VIP's have Long Jump",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnPluginStart()
{
	AutoExecConfig_SetFile("longjump", "stamm/features");

	c_strong = AutoExecConfig_CreateConVar("longjump_strong", "6", "The longjump factor");

	AutoExecConfig_AutoExecConfig();
	AutoExecConfig_CleanFile();
}

public OnConfigsExecuted()
{
	strong = GetConVarInt(c_strong);
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
}

public OnAllPluginsLoaded()
{
	decl String:haveDescription[64];

	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");

	STAMM_LoadTranslation();

	Format(haveDescription, sizeof(haveDescription), "%T", "GetLongJump", LANG_SERVER);
	
	STAMM_AddFeature("VIP LongJump", haveDescription);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!STAMM_IsClientValid(client))
		return Plugin_Continue;

	if (!STAMM_HaveClientFeature(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	if(GetEntityFlags(client) & FL_ONGROUND)
		bPressed[client] = false;
	else
	{
		if (buttons & IN_JUMP)
		{
			if(!bPressed[client])
			{
				new Float:velocity[3];
				new Float:velocity0;
				new Float:velocity1;
				
				velocity0 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
				velocity1 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
				
				velocity[0] = (float(strong) * velocity0) * (1.0 / 4.1);
				velocity[1] = (float(strong) * velocity1) * (1.0 / 4.1);
				velocity[2] = 0.0;
				
				SetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", velocity);
			}

			bPressed[client] = true;
		}
	}

	return Plugin_Continue;
}