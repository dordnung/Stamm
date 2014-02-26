/**
 * -----------------------------------------------------
 * File        stamm_distance.sp
 * Authors     David <popoklopsi> Ordnung
 * License     GPLv3
 * Web         http://popoklopsi.de
 * -----------------------------------------------------
 * 
 * Copyright (C) 2012-2014 David <popoklopsi> Ordnung
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>
 */


// Includes
#include <sourcemod>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1



new g_iBlockDirection;
new g_iBlockDistance;
new g_iBlockName;
new Handle:g_hUnit;

new bool:g_bVipPlayers[MAXPLAYERS + 1][3];



public Plugin:myinfo =
{
	name = "Stamm Feature Distance",
	author = "Popoklopsi",
	version = "1.1.0",
	description = "VIP's see the distance and direction to the nearest player",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// Hook spawning
public OnPluginStart()
{
	AutoExecConfig_SetFile("distance", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hUnit = AutoExecConfig_CreateConVar("distance_unit", "1", "1 = Use feet as unit, 0 = Use meters as unit");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();


	HookEvent("player_spawn", eventPlayerSpawn);
}



// Auto updater
public STAMM_OnFeatureLoaded(const String:basename[])
{
	decl String:urlString[256];


	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
	}



	// Found old config 
	if (STAMM_GetBlockCount() < 3)
	{
		g_iBlockDirection = g_iBlockDistance = g_iBlockName = 1;
	}
	else
	{
		// Get Blocks
		g_iBlockDirection = STAMM_GetBlockOfName("direction");
		g_iBlockDistance = STAMM_GetBlockOfName("distance");
		g_iBlockName = STAMM_GetBlockOfName("name");
	}


	// check for nearest player
	CreateTimer(0.2, checkPlayers, _, TIMER_REPEAT);
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	
	if (block == g_iBlockDirection)
	{
		Format(fmt, sizeof(fmt), "%T", "GetDirection", client);
		PushArrayString(array, fmt);
	}

	if (block == g_iBlockDistance)
	{
		Format(fmt, sizeof(fmt), "%T", "GetDistance", client);
		PushArrayString(array, fmt);
	}

	if (block == g_iBlockName)
	{
		Format(fmt, sizeof(fmt), "%T", "GetName", client);
		PushArrayString(array, fmt);
	}
}




// Add feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP Distance");
}




// Disable hud hint sound
public OnConfigsExecuted()
{
	if (FindConVar("sv_hudhint_sound") != INVALID_HANDLE)
	{
		SetConVarInt(FindConVar("sv_hudhint_sound"), 0);
	}
}




// A player spawned
public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));


	// Reset
	g_bVipPlayers[client][0] = false;
	g_bVipPlayers[client][1] = false;
	g_bVipPlayers[client][2] = false;


	// Is client VIP?
	if (STAMM_IsClientValid(client))
	{
		if (g_iBlockDirection != -1 && STAMM_HaveClientFeature(client, g_iBlockDirection))
		{
			g_bVipPlayers[client][2] = true;
		}

		if (g_iBlockDistance != -1 && STAMM_HaveClientFeature(client, g_iBlockDistance))
		{
			g_bVipPlayers[client][1] = true;
		}

		if (g_iBlockName != -1 && STAMM_HaveClientFeature(client, g_iBlockName))
		{
			g_bVipPlayers[client][0] = true;
		}
	}
}




public STAMM_OnClientBecomeVip(client, oldlevel, newlevel)
{
	if (g_iBlockDirection != -1 && STAMM_HaveClientFeature(client, g_iBlockDirection))
	{
		g_bVipPlayers[client][2] = true;
	}

	if (g_iBlockDistance != -1 && STAMM_HaveClientFeature(client, g_iBlockDistance))
	{
		g_bVipPlayers[client][1] = true;
	}

	if (g_iBlockName != -1 && STAMM_HaveClientFeature(client, g_iBlockName))
	{
		g_bVipPlayers[client][0] = true;
	}
}




// Client disconnected
public OnClientDisconnect(client)
{
	g_bVipPlayers[client][0] = false;
	g_bVipPlayers[client][1] = false;
	g_bVipPlayers[client][2] = false;
}




// Client changed feature
public STAMM_OnClientChangedFeature(client, bool:mode, bool:isShop)
{
	if (!mode)
	{
		g_bVipPlayers[client][0] = false;
		g_bVipPlayers[client][1] = false;
		g_bVipPlayers[client][2] = false;
	}
	else
	{
		if (g_iBlockDirection != -1 && STAMM_HaveClientFeature(client, g_iBlockDirection))
		{
			g_bVipPlayers[client][2] = true;
		}

		if (g_iBlockDistance != -1 && STAMM_HaveClientFeature(client, g_iBlockDistance))
		{
			g_bVipPlayers[client][1] = true;
		}

		if (g_iBlockName != -1 && STAMM_HaveClientFeature(client, g_iBlockName))
		{
			g_bVipPlayers[client][0] = true;
		}
	}
}




// Check for nearest player
public Action:checkPlayers(Handle:timer, any:data)
{
	decl String:unitString[12];
	decl String:unitStringOne[12];

	new Float:clientOrigin[3];
	new Float:searchOrigin[3];
	new Float:near;
	new Float:distance;

	new nearest;



	if (GetConVarInt(g_hUnit) == 1)
	{
		Format(unitString, sizeof(unitString), "feet");
		Format(unitStringOne, sizeof(unitStringOne), "feet");
	}

	else
	{
		Format(unitString, sizeof(unitString), "meters");
		Format(unitStringOne, sizeof(unitStringOne), "meter");
	}



	// Client loop
	for (new client = 1; client <= MaxClients; client++)
	{
		// Valid client?
		if ((g_bVipPlayers[client][0] || g_bVipPlayers[client][1] || g_bVipPlayers[client][2]) && IsPlayerAlive(client))
		{
			// Is VIP and want it?
			if (!STAMM_IsClientValid(client) || !STAMM_WantClientFeature(client))
			{
				g_bVipPlayers[client][0] = false;
				g_bVipPlayers[client][1] = false;
				g_bVipPlayers[client][2] = false;
			}

			else
			{
				nearest = 0;
				near = 0.0;

				// Get origin
				GetClientAbsOrigin(client, clientOrigin);

				// Next client loop
				for (new search = 1; search <= MaxClients; search++)
				{
					if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
					{
						// Get distance to first client
						GetClientAbsOrigin(search, searchOrigin);

						distance = GetVectorDistance(clientOrigin, searchOrigin);

						// Is he more near to the player as the player before?
						if (near == 0.0)
						{
							near = distance;
							nearest = search;
						}

						if (distance < near)
						{
							near = distance;
							nearest = search;
						}
					}
				}

				// Found a player?
				if (nearest != 0)
				{
					new Float:dist;
					new Float:vecPoints[3];
					new Float:vecAngles[3];
					new Float:clientAngles[3];

					decl String:directionString[64];
					new String:textToPrint[64];


					// Client get Direction?
					if (g_bVipPlayers[client][2])
					{
						// Get the origin of the nearest player
						GetClientAbsOrigin(nearest, searchOrigin);

						// Angles
						GetClientAbsAngles(client, clientAngles);

						// Angles from origin
						MakeVectorFromPoints(clientOrigin, searchOrigin, vecPoints);
						GetVectorAngles(vecPoints, vecAngles);

						// Differenz
						new Float:diff = clientAngles[1] - vecAngles[1];

						// Correct it
						if (diff < -180)
						{
							diff = 360 + diff;
						}

						if (diff > 180)
						{
							diff = 360 - diff;
						}


						// Now geht the direction

						// Up
						if (diff >= -22.5 && diff < 22.5)
						{
							Format(directionString, sizeof(directionString), "\xe2\x86\x91");
						}

						// right up
						else if (diff >= 22.5 && diff < 67.5)
						{
							Format(directionString, sizeof(directionString), "\xe2\x86\x97");
						}

						// right
						else if (diff >= 67.5 && diff < 112.5)
						{
							Format(directionString, sizeof(directionString), "\xe2\x86\x92");
						}

						// right down
						else if (diff >= 112.5 && diff < 157.5)
						{
							Format(directionString, sizeof(directionString), "\xe2\x86\x98");
						}

						// down
						else if (diff >= 157.5 || diff < -157.5)
						{
							Format(directionString, sizeof(directionString), "\xe2\x86\x93");
						}

						// down left
						else if (diff >= -157.5 && diff < -112.5)
						{
							Format(directionString, sizeof(directionString), "\xe2\x86\x99");
						}

						// left
						else if (diff >= -112.5 && diff < -67.5)
						{
							Format(directionString, sizeof(directionString), "\xe2\x86\x90");
						}

						// left up
						else if (diff >= -67.5 && diff < -22.5)
						{
							Format(directionString, sizeof(directionString), "\xe2\x86\x96");
						}



						// Add to text
						if (g_bVipPlayers[client][1] || g_bVipPlayers[client][0])
						{
							Format(textToPrint, sizeof(textToPrint), "%s\n", directionString);
						}
						else
						{
							Format(textToPrint, sizeof(textToPrint), directionString);
						}
					}



					// Client get Distance?
					if (g_bVipPlayers[client][1])
					{
						// Distance to meters
						dist = near * 0.01905;

						// Distance to feet
						if (GetConVarInt(g_hUnit) == 1)
						{
							dist = dist * 3.2808399;
						}


						// Add to text
						if (g_bVipPlayers[client][0])
						{
							Format(textToPrint, sizeof(textToPrint), "%s(%i %s)\n", textToPrint, RoundFloat(dist), (RoundFloat(dist) == 1 ? unitStringOne : unitString));
						}
						else
						{
							Format(textToPrint, sizeof(textToPrint), "%s(%i %s)", textToPrint, RoundFloat(dist), (RoundFloat(dist) == 1 ? unitStringOne : unitString));
						}
					}


					// Add name
					if (g_bVipPlayers[client][0])
					{
						Format(textToPrint, sizeof(textToPrint), "%s%N", textToPrint, nearest);
					}

					// Print text
					PrintHintText(client, textToPrint);
				}
			}
		}
	}

	return Plugin_Continue;
}