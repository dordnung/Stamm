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

public Plugin:myinfo =
{
	name = "Stamm Feature VIP Slot",
	author = "Popoklopsi",
	version = "1.2.0",
	description = "Give VIP's a VIP Slot",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.couch-fighter.de/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
}

public OnAllPluginsLoaded()
{
	decl String:description[64];

	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	STAMM_LoadTranslation();
		
	Format(description, sizeof(description), "%T", "GetSlot", LANG_SERVER);
	
	STAMM_AddFeature("VIP Slot", description);
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("slot", "stamm/features");

	c_let_free = AutoExecConfig_CreateConVar("slot_let_free", "0", "1 = Let a Slot always free and kick a random Player  0 = Off");
	c_vip_kick_message = AutoExecConfig_CreateConVar("slot_vip_kick_message", "You joined on a Reserve Slot", "Message, when someone join on a Reserve Slot");
	c_vip_kick_message2 = AutoExecConfig_CreateConVar("slot_vip_kick_message2", "You get kicked, to let a VIP slot free", "Message for the random kicked person");
	c_vip_slots = AutoExecConfig_CreateConVar("slot_vip_slots", "0", "How many Reserve Slots should there be ?");
	
	AutoExecConfig_AutoExecConfig();
	AutoExecConfig_CleanFile();
}

public OnConfigsExecuted()
{
	let_free = GetConVarInt(c_let_free);
	
	GetConVarString(c_vip_kick_message, vip_kick_message, sizeof(vip_kick_message));
	GetConVarString(c_vip_kick_message2, vip_kick_message2, sizeof(vip_kick_message2));
	
	vip_slots = GetConVarInt(c_vip_slots);
}

public STAMM_OnClientReady(client)
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
		if (!STAMM_HaveClientFeature(client)) 
			KickClient(client, vip_kick_message);
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
				
				if (STAMM_IsClientValid(RandPlayer))
				{
					if (!STAMM_HaveClientFeature(RandPlayer) && !STAMM_IsClientAdmin(RandPlayer))
					{
						KickClient(RandPlayer, vip_kick_message2);
						
						playeringame = true;
					}
				}
			}
		}
	}
}