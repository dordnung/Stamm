#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

new bool:vipPlayers[MAXPLAYERS + 1] = false;

public Plugin:myinfo =
{
	name = "Stamm Feature Distance",
	author = "Popoklopsi",
	version = "1.0",
	description = "VIP's see the distance of the nearest player",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnPluginStart()
{
	HookEvent("player_spawn", eventPlayerSpawn);
}


public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.couch-fighter.de/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
}

public OnAllPluginsLoaded()
{
	decl String:haveDescription[64];

	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");

	STAMM_LoadTranslation();

	Format(haveDescription, sizeof(haveDescription), "%T", "GetDistance", LANG_SERVER);
	
	STAMM_AddFeature("VIP Distance", haveDescription);

	CreateTimer(0.2, checkPlayers, _, TIMER_REPEAT);
}

public OnConfigsExecuted()
{
	if (FindConVar("sv_hudhint_sound") != INVALID_HANDLE)
		SetConVarInt(FindConVar("sv_hudhint_sound"), 0);
}

public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (STAMM_IsClientValid(client) && STAMM_HaveClientFeature(client))
		vipPlayers[client] = true;
	else
		vipPlayers[client] = false;
}

public OnClientDisconnect(client)
{
	vipPlayers[client] = false;
}

public STAMM_OnClientChangedFeature(client, bool:mode)
{
	if (!mode)
		vipPlayers[client] = false;
	else if (STAMM_HaveClientFeature(client))
		vipPlayers[client] = true;
}

public Action:checkPlayers(Handle:timer, any:data)
{
	new Float:clientOrigin[3];
	new Float:searchOrigin[3];
	new Float:near;
	new Float:distance;

	new nearest;

	for (new client = 1; client <= MaxClients; client++)
	{
		if (vipPlayers[client] && IsPlayerAlive(client))
		{
			if (!STAMM_IsClientValid(client))
				vipPlayers[client] = false;

			else if (!STAMM_HaveClientFeature(client))
				vipPlayers[client] = false;

			else
			{
				nearest = 0;
				near = 0.0;

				GetClientAbsOrigin(client, clientOrigin);

				for (new search = 1; search <= MaxClients; search++)
				{
					if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
					{
						GetClientAbsOrigin(search, searchOrigin);

						distance = GetVectorDistance(clientOrigin, searchOrigin);

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

				if (nearest != 0)
				{
					new direction = 1;

					GetClientAbsOrigin(nearest, searchOrigin);

					new Float:diffX = searchOrigin[0] - clientOrigin[0];
					new Float:diffY = searchOrigin[1] - clientOrigin[1];

					if (FloatAbs(diffX) > FloatAbs(diffY))
					{
						if (diffX <= 0)
							direction = 3;
					}
					else
					{
						if (diffY <= 0)
							direction = 2;
						else
							direction = 0;
					}

					direction = convertDirection(client, direction);

					PrintHintText(client, "%c\n%N", direction, nearest);
				}
			}
		}
	}

	return Plugin_Continue;
}

public convertDirection(client, direction)
{
	new Float:clientAngles[3];
	new Float:dir;

	GetClientAbsAngles(client, clientAngles);

	dir = clientAngles[1];

	if (dir <= 135.0 && dir >= 45.0)
		return DirToDir(direction);

	if (dir < 45.0 && dir >= -45.0)
	{
		if (--direction == -1)
			direction = 3;

		return DirToDir(direction);
	}

	if (dir < -45.0 && dir >= -135.0)
	{
		if (--direction == -1)
			direction = 3;

		if (--direction == -1)
			direction = 3;
			
		return DirToDir(direction);
	}

	if (--direction == -1)
		direction = 3;

	if (--direction == -1)
		direction = 3;

	if (--direction == -1)
		direction = 3;
		
	return DirToDir(direction);
}

public DirToDir(direction)
{
	switch (direction)
	{
		case 1:
		{
			return '>';
		}

		case 2:
		{
			return 'v';
		}

		case 3:
		{
			return '<';
		}
	}

	return '^';
}