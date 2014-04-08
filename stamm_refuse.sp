#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>



new g_iCount[MAXPLAYERS+1];

new Handle:g_hTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_hResetTimer[MAXPLAYERS+1] = INVALID_HANDLE;

new Handle:g_hMode = INVALID_HANDLE;
new Handle:g_hNonVIP = INVALID_HANDLE;
new Handle:g_hMinT = INVALID_HANDLE;
new Handle:g_hReset = INVALID_HANDLE;


new g_BeamSprite;
new g_HaloSprite;



public Plugin:myinfo =
{
	name = "Stamm Feature Refuse",
	author = "Bara",
	version = "1.0.0",
	description = "On every level terrorists are be able to refuse one more game",
	url = "www.bara.in"
};




public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable())
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP Refuse");
}




public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];

	Format(fmt, sizeof(fmt), "%T", "GetRefuse", client, block+1);
	
	PushArrayString(array, fmt);
}



public STAMM_OnClientRequestCommands(client)
{
	STAMM_AddCommand("!refuse", "%T", "RefuseCommand", client);
}



public OnPluginStart()
{
	RegConsoleCmd("sm_v", Command_Refuse);
	RegConsoleCmd("sm_refuse", Command_Refuse);
	RegConsoleCmd("sm_verweigern", Command_Refuse);

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);


	AutoExecConfig_SetFile("refuse", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hMode = AutoExecConfig_CreateConVar("refuse_mode", "1", "0 - None, 1 - Beam Ring");
	g_hNonVIP = AutoExecConfig_CreateConVar("refuse_nonvip", "1", "Should non-VIPs be able to refuse?", _, true, 0.0, true, 1.0);
	g_hMinT = AutoExecConfig_CreateConVar("refuse_t", "3", "How many terrorists have to live for refusal at least.");
	g_hReset = AutoExecConfig_CreateConVar("refuse_reset_time", "10.0", "After how many seconds should refuse effect disappear ( refuse_mode must be 1 ) (0 - unlimited) ?");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}




public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
}





public OnClientDisconnect(client)
{
	if (STAMM_IsClientValid(client))
	{
		Reset(client);
	}
}




public Action:Event_PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (STAMM_IsClientValid(client))
	{
		Reset(client);
	}
}




public Action:Event_PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (STAMM_IsClientValid(client))
	{
		Reset(client);
	}
}




public Action:Command_Refuse(client, args)
{
	if (STAMM_IsClientValid(client))
	{
		if (GetClientTeam(client) == 2)
		{
			if (IsPlayerAlive(client))
			{
				new g_iClientBlock = STAMM_GetClientBlock(client) + 1;

				if (g_iClientBlock > 1)
				{
					if (g_iCount[client] < g_iClientBlock)
					{
						if (CheckTeam() <= GetConVarInt(g_hMinT))
						{
							STAMM_PrintToChat(client, "%T", "NotEnoughT", client, GetConVarInt(g_hMinT));

							return Plugin_Handled;
						}

						g_iCount[client]++;

						STAMM_PrintToChatAll("%T", "MultiRefuse", client, client, g_iCount[client], g_iClientBlock);

						if (GetConVarInt(g_hMode))
						{
							SetClientAura(client);
						}
					}
					else if (g_iCount[client] >= g_iClientBlock)
					{
						STAMM_PrintToChat(client, "%T", "CantRefuse", client);

						return Plugin_Handled;
					}
				}
				else
				{
					if (GetConVarInt(g_hNonVIP))
					{
						if (g_iCount[client] == 0)
						{
							if (CheckTeam() <= GetConVarInt(g_hMinT))
							{
								STAMM_PrintToChat(client, "%T", "NotEnoughT", client, GetConVarInt(g_hMinT));

								return Plugin_Handled;
							}

							g_iCount[client] = 1;

							STAMM_PrintToChatAll("%T", "Refuse", client, client);

							if (GetConVarInt(g_hMode))
							{
								SetClientAura(client);
							}
						}
						else
						{
							STAMM_PrintToChat(client, "%T", "CantRefuse", client);

							return Plugin_Handled;
						}
					}
				}
			}
			else
			{
				STAMM_PrintToChat(client, "%T", "NotAlive", client);

				return Plugin_Handled;
			}
		}
		else
		{
			STAMM_PrintToChat(client, "%T", "NoT", client);

			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}






public Action:Timer_V(Handle:hTimer, any:client)
{
	if (STAMM_IsClientValid(client) && IsPlayerAlive(client))
	{
		static Float:fVec[3];

		GetClientAbsOrigin(client, fVec);
		fVec[2] += (5 * g_iCount[client]);

		new fColor[4];
		fColor[0] = 0;
		fColor[1] = 0;
		fColor[2] = 255;
		fColor[3] = 255;

		TE_SetupBeamRingPoint(fVec, 50.0, 51.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.1, 10.0, 0.0, fColor, 100, 0);
		TE_SendToAll();

		return Plugin_Continue;
	}
	else if(g_hTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hTimer[client]);

		g_hTimer[client] = INVALID_HANDLE;
	}


	return Plugin_Stop;
}





public Action:Timer_Reset(Handle:hTimer, any:client)
{
	if (STAMM_IsClientValid(client))
	{
		if (g_hTimer[client] != INVALID_HANDLE)
		{
			CloseHandle(g_hTimer[client]);

			g_hTimer[client] = INVALID_HANDLE;
		}

		if (g_hResetTimer[client] != INVALID_HANDLE)
		{
			g_hResetTimer[client] = INVALID_HANDLE;
		}
	}
}





stock SetClientAura(client)
{
	if (g_hTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hTimer[client]);

		g_hTimer[client] = INVALID_HANDLE;
	}

	if (g_hResetTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hResetTimer[client]);

		g_hResetTimer[client] = INVALID_HANDLE;
	}


	if (GetConVarInt(g_hMode) > 0)
	{
		if (GetConVarFloat(g_hReset) > 0.0)
		{
			g_hResetTimer[client] = CreateTimer(GetConVarFloat(g_hReset), Timer_Reset, client);
		}
	}
	

	g_hTimer[client] = CreateTimer(0.1, Timer_V, client, TIMER_REPEAT);
}





stock Reset(client)
{
	g_iCount[client] = 0;

	if (g_hTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hTimer[client]);

		g_hTimer[client] = INVALID_HANDLE;
	}

	if (g_hResetTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hResetTimer[client]);

		g_hResetTimer[client] = INVALID_HANDLE;
	}
}





stock CheckTeam()
{
	new TCount;

	for (new i = 1; i <= MaxClients; i++) 
	{
		if (STAMM_IsClientValid(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			TCount++;
		}
	}

	return TCount;
}