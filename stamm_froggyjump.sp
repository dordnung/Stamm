#include <sourcemod>
#include <autoexecconfig>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new FroggyJumped[MAXPLAYERS + 1];

new Handle:c_strong;
new strong;

public Plugin:myinfo =
{
	name = "Stamm Feature FroggyJump",
	author = "Popoklopsi",
	version = "1.0",
	description = "VIP's have Froggy Jump",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnPluginStart()
{
	AutoExecConfig_SetFile("froggyjump", "stamm/features");

	c_strong = AutoExecConfig_CreateConVar("froggyjump_strong", "200", "The push up strong");

	AutoExecConfig_AutoExecConfig();
	AutoExecConfig_CleanFile();
}

public OnConfigsExecuted()
{
	strong = GetConVarInt(c_strong);
}

public OnAllPluginsLoaded()
{
	decl String:haveDescription[64];

	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");

	STAMM_LoadTranslation();

	Format(haveDescription, sizeof(haveDescription), "%T", "GetFroggyJump", LANG_SERVER);
	
	STAMM_AddFeature("VIP FroggyJump", haveDescription);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!STAMM_IsClientValid(client))
		return Plugin_Continue;

	if (!STAMM_HaveClientFeature(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	if (STAMM_GetGame() == GameTF2)
	{
		if (TF2_GetPlayerClass(client) == TFClass_Scout)
			return Plugin_Continue;
	}

	static bool:bPressed[MAXPLAYERS+1] = false;
	
	if(GetEntityFlags(client) & FL_ONGROUND)
	{
		FroggyJumped[client] = 0;
		bPressed[client] = false;
	}
	else
	{
		if (buttons & IN_JUMP)
		{
			if(!bPressed[client] && FroggyJumped[client]++ == 1)
			{
				new Float:velocity[3];
				new Float:velocity0;
				new Float:velocity1;
				new Float:velocity2;
				new Float:velocity2_new;

				velocity0 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
				velocity1 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
				velocity2 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");

				velocity2_new = float(strong);

				if (velocity2 < 150.0) 
					velocity2_new = velocity2_new + 20.0;
				if (velocity2 < 100.0) 
					velocity2_new = velocity2_new + 30.0;
				if (velocity2 < 50.0) 
					velocity2_new = velocity2_new + 40.0;
				if (velocity2 < 0.0) 
					velocity2_new = velocity2_new + 50.0;
				if (velocity2 < -50.0) 
					velocity2_new = velocity2_new + 60.0;
				if (velocity2 < -100.0) 
					velocity2_new = velocity2_new + 70.0;
				if (velocity2 < -150.0) 
					velocity2_new = velocity2_new + 80.0;
				if (velocity2 < -200.0) 
					velocity2_new = velocity2_new + 90.0;

				velocity[0] = velocity0 * 0.1;
				velocity[1] = velocity1 * 0.1;
				velocity[2] = velocity2_new;
				
				SetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", velocity);
			}

			bPressed[client] = true;
		}
		else
			bPressed[client] = false;
	}

	return Plugin_Continue;
}