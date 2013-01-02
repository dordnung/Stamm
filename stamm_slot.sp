#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new Handle:c_let_free;
new Handle:c_vip_kick_message;
new Handle:c_vip_kick_message2;
new Handle:c_vip_slots;

new v_level;
new let_free;
new vip_slots;

new String:vip_kick_message[128];
new String:vip_kick_message2[128];

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature VIP Slot",
	author = "Popoklopsi",
	version = "1.1",
	description = "Give VIP's a VIP Slot",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) SetFailState("Can't Load Feature, Stamm is not installed!");
}

public OnPluginStart()
{
	new Handle:myPlugin = GetMyHandle();
	
	GetPluginFilename(myPlugin, basename, sizeof(basename));
	ReplaceString(basename, sizeof(basename), ".smx", "");
	ReplaceString(basename, sizeof(basename), "stamm/", "");
	ReplaceString(basename, sizeof(basename), "stamm\\", "");
	
	c_let_free = CreateConVar("slot_let_free", "0", "1 = Let a Slot always free and kick a random Player  0 = Off");
	c_vip_kick_message = CreateConVar("slot_vip_kick_message", "You joined on a Reserve Slot", "Message, when someone join on a Reserve Slot");
	c_vip_kick_message2 = CreateConVar("slot_vip_kick_message2", "You get kicked, to let a VIP slot free", "Message for the random kicked person");
	c_vip_slots = CreateConVar("slot_vip_slots", "0", "How many Reserve Slots should there be ?");
	
	AutoExecConfig(true, "slot", "stamm/features");
}

public OnConfigsExecuted()
{
	let_free = GetConVarInt(c_let_free);
	GetConVarString(c_vip_kick_message, vip_kick_message, sizeof(vip_kick_message));
	GetConVarString(c_vip_kick_message2, vip_kick_message2, sizeof(vip_kick_message2));
	vip_slots = GetConVarInt(c_vip_slots);
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[64];

	Format(description, sizeof(description), "%T", "GetSlot", LANG_SERVER);
	
	v_level = AddStammFeature(basename, "VIP Slot", description, false);
	
	Format(description, sizeof(description), "%T", "YouGetSlot", LANG_SERVER);
	AddStammFeatureInfo(basename, v_level, description);
}

public OnStammClientReady(client)
{
	VipSlotCheck(client);
}

public VipSlotCheck(client)
{
	new max_players = MaxClients;
	new current_players = GetClientCount(false);
	new max_slots = max_players - current_players;
	
	if (vip_slots > max_slots)
	{
		if (!IsClientVip(client, v_level) && !IsClientStammAdmin(client)) KickClient(client, vip_kick_message);
	}
	
	current_players = GetClientCount(false);
	max_slots = max_players - current_players;
	
	if (let_free)
	{
		if (!max_slots)
		{
			new bool:playeringame = false;
			
			while(!playeringame)
			{
				new RandPlayer = GetRandomInt(1, 64);
				
				if (IsStammClientValid(RandPlayer))
				{
					if (!IsClientVip(client, v_level) && !IsClientStammAdmin(client))
					{
						KickClient(client, vip_kick_message2);
						playeringame = true;
					}
				}
			}
		}
	}
}