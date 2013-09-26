/**
 * -----------------------------------------------------
 * File        stamm_slot.sp
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




new Handle:c_let_free;
new Handle:c_vip_kick_message;
new Handle:c_vip_kick_message2;
new Handle:c_vip_slots;

new let_free;
new vip_slots;

new String:vip_kick_message[128];
new String:vip_kick_message2[128];




// Information
public Plugin:myinfo =
{
	name = "Stamm Feature VIP Slot",
	author = "Popoklopsi",
	version = "1.2.1",
	description = "Give VIP's a VIP Slot",
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




// Add Feature
public OnAllPluginsLoaded()
{
	decl String:description[64];


	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}


	STAMM_LoadTranslation();
		
	Format(description, sizeof(description), "%T", "GetSlot", LANG_SERVER);
	
	STAMM_AddFeature("VIP Slot", description);
}




// Create cvars
public OnPluginStart()
{
	AutoExecConfig_SetFile("slot", "stamm/features");

	c_let_free = AutoExecConfig_CreateConVar("slot_let_free", "0", "1 = Let a Slot always free and kick a random Player  0 = Off");
	c_vip_kick_message = AutoExecConfig_CreateConVar("slot_vip_kick_message", "You joined on a Reserve Slot", "Message, when someone join on a Reserve Slot");
	c_vip_kick_message2 = AutoExecConfig_CreateConVar("slot_vip_kick_message2", "You get kicked, to let a VIP slot free", "Message for the random kicked person");
	c_vip_slots = AutoExecConfig_CreateConVar("slot_vip_slots", "0", "How many Reserve Slots should there be ?");
	
	AutoExecConfig(true, "slot", "stamm/features");
	AutoExecConfig_CleanFile();
}



// Load Config
public OnConfigsExecuted()
{
	let_free = GetConVarInt(c_let_free);
	
	GetConVarString(c_vip_kick_message, vip_kick_message, sizeof(vip_kick_message));
	GetConVarString(c_vip_kick_message2, vip_kick_message2, sizeof(vip_kick_message2));
	
	vip_slots = GetConVarInt(c_vip_slots);
}



// A Client is ready
public STAMM_OnClientReady(client)
{
	VipSlotCheck(client);
}



// Check him
public VipSlotCheck(client)
{
	new max_players = MaxClients;
	new current_players = GetClientCount(false);
	new max_slots = max_players - current_players;
	


	// vip slots greater than max slots?
	if (vip_slots > max_slots)
	{
		// -> Kick non VIP's
		if (!STAMM_HaveClientFeature(client)) 
		{
			KickClient(client, vip_kick_message);
		}
	}
	
	
	// Check for let a slot free
	current_players = GetClientCount(false);
	max_slots = max_players - current_players;
	

	
	// Want let free?
	if (let_free)
	{
		// No slot is free?
		if (!max_slots)
		{
			new bool:playeringame = false;
			
			// Check all players
			while(!playeringame)
			{
				// Get random player
				new RandPlayer = GetRandomInt(1, MaxClients);
				
				// Check if client is valid
				if (STAMM_IsClientValid(RandPlayer))
				{
					// Only non admins and non vips
					if (!STAMM_HaveClientFeature(RandPlayer) && !STAMM_IsClientAdmin(RandPlayer))
					{
						// kick to let free
						KickClient(RandPlayer, vip_kick_message2);
						
						playeringame = true;
					}
				}
			}
		}
	}
}