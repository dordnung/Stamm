/**
 * -----------------------------------------------------
 * File        stamm_end_immunity.sp
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
#include <tf2_stocks>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>


#pragma semicolon 1



new bool:RoundEnd;

new particels[MAXPLAYERS + 1][2];



public Plugin:myinfo =
{
	name = "Stamm Feature End of Round Immunity",
	author = "Popoklopsi",
	version = "1.1.0",
	description = "Give VIP's immunity at the end of the round",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};



// Add to auto updater
public STAMM_OnFeatureLoaded(const String:basename[])
{
	decl String:urlString[256];



	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
	}
}



// Hooke needed events
public OnPluginStart()
{
	HookEvent("teamplay_round_win", RoundWin);
	
	HookEvent("teamplay_round_start", RoundStart);
	HookEvent("teamplay_round_stalemate", RoundStart);
	
	HookEvent("player_death", PlayerDeath);
}



// Add feature for TF2
public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	if (STAMM_GetGame() != GameTF2) 
	{
		SetFailState("Can't Load Feature, not Supported for your game!");
	}
	
	
	STAMM_LoadTranslation();
	STAMM_AddFastFeature("VIP End of Round Immunity", "%T", "GetImmunity", LANG_SERVER);
}



// A round is finish
public RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{	
	RoundEnd = true;

	// Set god mod for each VIP
	for (new i=1; i <= MaxClients; i++)
	{
		if (STAMM_IsClientValid(i) && STAMM_HaveClientFeature(i))
		{
			SetEntProp(i, Prop_Data, "m_takedamage", 1, 1);
			
			// Show effects
			ImmuneEffects(i);
		}
	}
}



// A round started
public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	RoundEnd = false;
	
	// Delete Effects
	for (new i=0; i < MAXPLAYERS+1; i++)
	{
		ClearParticles(i);
	}
}



// A player died
public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!RoundEnd) 
	{
		return Plugin_Continue;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	

	// Delete effects
	if (STAMM_IsClientValid(client))
	{
		ClearParticles(client);
	}

	return Plugin_Continue;
}




// Create the effects
public ImmuneEffects(client)
{
	particels[client][0] = EntIndexToEntRef(AttachParticle(client, "player_recent_teleport_red", 2.0));
	particels[client][1] = EntIndexToEntRef(AttachParticle(client, "player_recent_teleport_blue", 2.0));
}



// Attach the effects
public AttachParticle(entity, String:particleType[], Float:offsetZ)
{
	new particle = CreateEntityByName("info_particle_system");
	

	// Is a valid ent?
	if (IsValidEntity(particle))
	{
		new Float:pos[3];

		// Set Origin to client origin
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);

		pos[2] += offsetZ;
		

		// Teleport it
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		

		// Spawn it
		DispatchKeyValue(particle, "effect_name", particleType);
		
		DispatchSpawn(particle);
		

		// Set parent to client
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", entity);
		
		ActivateEntity(particle);
		
		AcceptEntityInput(particle, "start");
		
		return particle;
	}
	
	return -1;
}



// Clear effects
public ClearParticles(client)
{
	// Client have effect?
	if (particels[client][0] > 0)
	{
		new particle = EntRefToEntIndex(particels[client][0]);
		
		// Kill
		if (particle > MaxClients && IsValidEntity(particle))
		{
			AcceptEntityInput(particle, "Kill");
		}

		particels[client][0] = 0;
	}

	if (particels[client][1] > 0)
	{
		new particle = EntRefToEntIndex(particels[client][1]);
		
		// Kill
		if (particle > MaxClients && IsValidEntity(particle))
		{
			AcceptEntityInput(particle, "Kill");
		}
			
		particels[client][1] = 0;
	}
}



// Set speed to highest on Round end
public OnGameFrame()
{
	if (RoundEnd)
	{
		// For each VIP
		for (new i=1; i <= MaxClients; i++)
		{
			if (STAMM_IsClientValid(i) && IsPlayerAlive(i))
			{
				new TFClassType:class = TF2_GetPlayerClass(i);
				
				if (class != TFClass_Scout && !TF2_IsPlayerInCondition(i, TFCond_Charging) && class != TFClass_Unknown)
				{
					// set Speed
					if (STAMM_HaveClientFeature(i))
					{
						SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", 400.0);
					}
				}
			}
		}
	}
}