#include <sourcemod>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

new Handle:c_cash;
new Handle:c_max;

new cash;
new maxm;

public Plugin:myinfo =
{
	name = "Stamm Feature Money",
	author = "Popoklopsi",
	version = "1.2.0",
	description = "Give VIP's every Round x Cash",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
		SetFailState("Can't Load Feature, not Supported for your game!");
		
	STAMM_LoadTranslation();
		
	STAMM_AddFeature("VIP Cash", "");
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:description[64];
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.couch-fighter.de/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
	
	Format(description, sizeof(description), "%T", "GetCash", LANG_SERVER, cash);
	
	STAMM_AddFeatureText(STAMM_GetLevel(), description);
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("cash", "stamm/features");

	c_cash = AutoExecConfig_CreateConVar("money_amount", "2000", "x = Cash, what a VIP gets, when he spawns");
	c_max = AutoExecConfig_CreateConVar("money_max", "1", "1 = Give not more than the max. Money, 0 = Off");
	
	AutoExecConfig_AutoExecConfig();
	AutoExecConfig_CleanFile();
	
	HookEvent("player_spawn", eventPlayerSpawn);
}

public OnConfigsExecuted()
{
	cash = GetConVarInt(c_cash);
	maxm = GetConVarInt(c_max);
}

public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (STAMM_IsClientValid(client))
	{
		if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && STAMM_HaveClientFeature(client))
		{
			new OldMoney = GetEntData(client, FindSendPropOffs("CCSPlayer", "m_iAccount"));
			new NewMoney = cash + OldMoney;
			
			if (STAMM_GetGame() == GameCSS && NewMoney > 16000 && maxm) 
				NewMoney = 16000;
				
			if (STAMM_GetGame() == GameCSGO && maxm)
			{
				new MaxMoney = GetConVarInt(FindConVar("mp_maxmoney"));
				
				if (NewMoney > MaxMoney)
					NewMoney = MaxMoney;
			}
			
			SetEntData(client, FindSendPropOffs("CCSPlayer", "m_iAccount"), NewMoney);
		}
	}
}