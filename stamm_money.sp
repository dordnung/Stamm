#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new Handle:c_cash;
new Handle:c_max;

new v_level;
new cash;
new max;

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature Money",
	author = "Popoklopsi",
	version = "1.1",
	description = "Give VIP's every Round x Cash",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) SetFailState("Can't Load Feature, Stamm is not installed!");
	
	if (GetStammGame() == GameTF2) SetFailState("Can't Load Feature, not Supported for your game!");
}

public OnPluginStart()
{
	new Handle:myPlugin = GetMyHandle();
	
	GetPluginFilename(myPlugin, basename, sizeof(basename));
	ReplaceString(basename, sizeof(basename), ".smx", "");
	ReplaceString(basename, sizeof(basename), "stamm/", "");
	ReplaceString(basename, sizeof(basename), "stamm\\", "");
	
	c_cash = CreateConVar("money_amount", "2000", "x = Cash, what a VIP gets, when he spawns");
	c_max = CreateConVar("money_max", "1", "1 = Give not more than the max. Money, 0 = Off");
	
	AutoExecConfig(true, "cash", "stamm/features");
	
	HookEvent("player_spawn", eventPlayerSpawn);
}

public OnConfigsExecuted()
{
	cash = GetConVarInt(c_cash);
	max = GetConVarInt(c_max);
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[64];

	Format(description, sizeof(description), "%T", "GetCash", LANG_SERVER, cash);
	
	v_level = AddStammFeature(basename, "VIP Cash", description);
	
	Format(description, sizeof(description), "%T", "YouGetCash", LANG_SERVER, cash);
	AddStammFeatureInfo(basename, v_level, description);
}

public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (IsStammClientValid(client))
	{
		if ((GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && ClientWantStammFeature(client, basename))
		{
			new OldMoney = GetEntData(client, FindSendPropOffs("CCSPlayer", "m_iAccount"));
			new NewMoney = cash + OldMoney;
			
			if (GetStammGame() == GameCSS && NewMoney > 16000 && max) NewMoney = 16000;
			if (GetStammGame() == GameCSGO && max)
			{
				new MaxMoney = GetConVarInt(FindConVar("mp_maxmoney"));
				if (NewMoney > MaxMoney) NewMoney = MaxMoney;
			}
			
			if (IsClientVip(client, v_level)) SetEntData(client, FindSendPropOffs("CCSPlayer", "m_iAccount"), NewMoney);
		}
	}
}
