/**
 * -----------------------------------------------------
 * File        eventlib.sp
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


// Use Semicolons
#pragma semicolon 1



// Start Eventlib
public eventlib_Start()
{

	// Event Round start for TF2
	if (otherlib_getGame() == 3)
	{
		HookEvent("teamplay_round_start", eventlib_RoundStart);
		HookEvent("arena_round_start", eventlib_RoundStart);
	}
	else if (otherlib_getGame() == 4)
	{
		// Event Round start for DOD
		HookEvent("dod_round_start", eventlib_RoundStart);
	}
	else
	{
		// Event Round start for CSS and CSGO
		HookEvent("round_start", eventlib_RoundStart);
	}

	// Player Death
	HookEvent("player_death", eventlib_PlayerDeath);
}



// Round started
public Action:eventlib_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{

	// Get points with rounds and enough players on server?
	if ((g_vip_type == 2 || g_vip_type == 4 || g_vip_type == 6 || g_vip_type == 7) && clientlib_GetPlayerCount() >= g_min_player)
	{
		// Client loop
		for (new client = 1; client <= MaxClients; client++)
		{
			// Client valid?
			if (clientlib_isValidClient(client))
			{
				// In a team?
				if (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)
				{
					// Give global points
					pointlib_GivePlayerPoints(client, g_points, true);
				}
			}
		}
	}
	

	// Announce Happy hour
	if (g_happyhouron) 
	{
		CPrintToChatAll("%s %t", g_StammTag, "HappyActive", g_points);
	}
}


// A Player died
public Action:eventlib_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{

	// Get client and attacker of event
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));

	// Are both valid?
	if (clientlib_isValidClient(userid) && clientlib_isValidClient(client))
	{
		// Get points with kills?
		if (g_vip_type == 1 || g_vip_type == 4 || g_vip_type == 5 || g_vip_type == 7)
		{
			// Valid Team? Enough Players? No suicide?
			if (clientlib_GetPlayerCount() >= g_min_player && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3) &&  userid != client && GetClientTeam(userid) != GetClientTeam(client))
			{
				// Give global Points
				pointlib_GivePlayerPoints(client, g_points, true);
			}
		}
	}
}