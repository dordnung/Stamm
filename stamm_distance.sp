/**
 * -----------------------------------------------------
 * File        stamm_distance.sp
 * Authors     David <popoklopsi> Ordnung
 * License     GPLv3
 * Web         http://popoklopsi.de
 * -----------------------------------------------------
 * 
 * Copyright (C) 2012-2013 David <popoklopsi> Ordnung
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



new blockDirection;
new blockDistance;
new blockName;

new unit;
new bool:vipPlayers[MAXPLAYERS + 1][3];
new Handle:unit_c;

new String:unitString[12];
new String:unitStringOne[12];



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

	unit_c = AutoExecConfig_CreateConVar("distance_unit", "1", "1 = Use feet as unit, 0 = Use meters as unit");
	
	AutoExecConfig(true, "distance", "stamm/features");
	AutoExecConfig_CleanFile();


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
		blockDirection = blockDistance = blockName = 1;

		STAMM_AddBlockDescription(1, "%T", "GetAll", LANG_SERVER);
	}

	else
	{
		// Get Blocks
		blockDirection = STAMM_GetBlockOfName("direction");
		blockDistance = STAMM_GetBlockOfName("distance");
		blockName = STAMM_GetBlockOfName("name");


		// Check valid?
		if (blockDirection != -1)
		{
			STAMM_AddBlockDescription(blockDirection, "%T", "GetDirection", LANG_SERVER);
		}

		if (blockDistance != -1)
		{
			STAMM_AddBlockDescription(blockDistance, "%T", "GetDistance", LANG_SERVER);
		}

		if (blockName != -1)
		{
			STAMM_AddBlockDescription(blockName, "%T", "GetName", LANG_SERVER);
		}
	}

	// check for nearest player
	CreateTimer(0.2, checkPlayers, _, TIMER_REPEAT);
}



// Add feature
public OnAllPluginsLoaded()
{

	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	STAMM_LoadTranslation();
	
	STAMM_AddFeature("VIP Distance");
}




// Disable hud hint sound
public OnConfigsExecuted()
{
	if (FindConVar("sv_hudhint_sound") != INVALID_HANDLE)
	{
		SetConVarInt(FindConVar("sv_hudhint_sound"), 0);
	}


	// Get unit to take
	unit = GetConVarInt(unit_c);


	// Get unit text
	if (unit == 1)
	{
		Format(unitString, sizeof(unitString), "feet");
		Format(unitStringOne, sizeof(unitStringOne), "feet");
	}

	else
	{
		Format(unitString, sizeof(unitString), "meters");
		Format(unitStringOne, sizeof(unitStringOne), "meter");
	}
}



// A player spawned
public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);


	// Reset
	vipPlayers[client][0] = false;
	vipPlayers[client][1] = false;
	vipPlayers[client][2] = false;


	// Is client VIP?
	if (STAMM_IsClientValid(client))
	{
		if (blockDirection != -1 && STAMM_HaveClientFeature(client, blockDirection))
		{
			vipPlayers[client][2] = true;
		}

		if (blockDistance != -1 && STAMM_HaveClientFeature(client, blockDistance))
		{
			vipPlayers[client][1] = true;
		}

		if (blockName != -1 && STAMM_HaveClientFeature(client, blockName))
		{
			vipPlayers[client][0] = true;
		}
	}
}



// Client disconnected
public OnClientDisconnect(client)
{
	vipPlayers[client][0] = false;
	vipPlayers[client][1] = false;
	vipPlayers[client][2] = false;
}



// Client changed feature
public STAMM_OnClientChangedFeature(client, bool:mode /* TODO: IMPLEMENT, bool:isShop */)
{
	if (!mode)
	{
		vipPlayers[client][0] = false;
		vipPlayers[client][1] = false;
		vipPlayers[client][2] = false;
	}
	else
	{
		if (blockDirection != -1 && STAMM_HaveClientFeature(client, blockDirection))
		{
			vipPlayers[client][2] = true;
		}

		if (blockDistance != -1 && STAMM_HaveClientFeature(client, blockDistance))
		{
			vipPlayers[client][1] = true;
		}

		if (blockName != -1 && STAMM_HaveClientFeature(client, blockName))
		{
			vipPlayers[client][0] = true;
		}
	}
}



// Check for nearest player
public Action:checkPlayers(Handle:timer, any:data)
{
	new Float:clientOrigin[3];
	new Float:searchOrigin[3];
	new Float:near;
	new Float:distance;

	new nearest;

	// Client loop
	for (new client = 1; client <= MaxClients; client++)
	{
		// Valid client?
		if ((vipPlayers[client][0] || vipPlayers[client][1] || vipPlayers[client][2]) && IsPlayerAlive(client))
		{
			// Is VIP and want it?
			if (!STAMM_IsClientValid(client) || !STAMM_WantClientFeature(client))
			{
				vipPlayers[client][0] = false;
				vipPlayers[client][1] = false;
				vipPlayers[client][2] = false;
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
					if (vipPlayers[client][2])
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
						if (vipPlayers[client][1] || vipPlayers[client][0])
						{
							Format(textToPrint, sizeof(textToPrint), "%s\n", directionString);
						}
						else
						{
							Format(textToPrint, sizeof(textToPrint), directionString);
						}
					}



					// Client get Distance?
					if (vipPlayers[client][1])
					{
						// Distance to meters
						dist = near * 0.01905;

						// Distance to feet
						if (unit == 1)
						{
							dist = dist * 3.2808399;
						}


						// Add to text
						if (vipPlayers[client][0])
						{
							Format(textToPrint, sizeof(textToPrint), "%s(%i %s)\n", textToPrint, RoundFloat(dist), (RoundFloat(dist) == 1 ? unitStringOne : unitString));
						}
						else
						{
							Format(textToPrint, sizeof(textToPrint), "%s(%i %s)", textToPrint, RoundFloat(dist), (RoundFloat(dist) == 1 ? unitStringOne : unitString));
						}
					}


					// Add name
					if (vipPlayers[client][0])
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