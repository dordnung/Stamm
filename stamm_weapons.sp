#include <sourcemod>
#include <sdktools>
#include <colors>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new maximum;
new level_need;
new Usages[MAXPLAYERS + 1];

new Handle:kv;
new Handle:weaponlist;

new String:basename[32];

public Plugin:myinfo =
{
	name = "Stamm Feature Weapons",
	author = "Popoklopsi",
	version = "1.0",
	description = "Give VIP's weapons",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) SetFailState("Can't Load Feature, Stamm is not installed!");
	
	if (GetStammGame() == 3) SetFailState("Can't Load Feature, not Supported for your game!");
}

public OnPluginStart()
{
	new Handle:myPlugin = GetMyHandle();
	
	GetPluginFilename(myPlugin, basename, sizeof(basename));
	ReplaceString(basename, sizeof(basename), ".smx", "");
	ReplaceString(basename, sizeof(basename), "stamm/", "");
	ReplaceString(basename, sizeof(basename), "stamm\\", "");
	
	RegConsoleCmd("sm_sgive", GiveCallback, "Give VIP's Weapons");
	RegConsoleCmd("sm_sweapons", InfoCallback, "show Weaponlist");
	
	HookEvent("round_start", RoundStart);
	
	kv = CreateKeyValues("WeaponSettings");
	FileToKeyValues(kv, "cfg/stamm/features/WeaponSettings.txt");
	
	KvJumpToKey(kv, "maximum");
	maximum = KvGetNum(kv, "max_use");
	KvGoBack(kv);
	
	weaponlist = CreateMenu(weaponlist_handler);
	SetMenuTitle(weaponlist, "!sgive <weapon_name>");
	
	if (KvGotoFirstSubKey(kv))
	{
		new String:buffer[120];
		
		do
		{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			ReplaceString(buffer, sizeof(buffer), "weapon_", "");
			
			if (!StrEqual(buffer, "maximum") && KvGetNum(kv, "enable") == 1) AddMenuItem(weaponlist, buffer, buffer);
		} 
		while (KvGotoNextKey(kv));
	}
}

public weaponlist_handler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (IsStammClientValid(param1))
		{
			new String:choose[64];
				
			GetMenuItem(menu, param2, choose, sizeof(choose));
			
			FakeClientCommandEx(param1, "sm_sgive %s", choose);
		}
	}
}

public RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	for (new x=0; x <= MaxClients; x++) Usages[x] = 0;
}

public OnStammClientReady(client)
{
	Usages[client] = 0;
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[256];
	
	Format(description, sizeof(description), "%T", "GetWeapons", LANG_SERVER);
	
	level_need = AddStammFeature(basename, "VIP Weapons", description);
	
	Format(description, sizeof(description), "%T", "YouGetWeapons", LANG_SERVER);
	AddStammFeatureInfo(basename, level_need, description);
}

public Action:InfoCallback(client, args)
{
	if (IsStammClientValid(client) && IsClientVip(client, level_need)) DisplayMenu(weaponlist, client, 30);
	
	return Plugin_Handled;
}

public Action:GiveCallback(client, args)
{
	if (GetCmdArgs() == 1)
	{
		if (IsStammClientValid(client) && ClientWantStammFeature(client, basename))
		{
			if (IsClientVip(client, level_need) && IsPlayerAlive(client))
			{
				if (Usages[client] < maximum)
				{
					decl String:WeaponName[64];
					
					GetCmdArg(1, WeaponName, sizeof(WeaponName));
					
					Format(WeaponName, sizeof(WeaponName), "weapon_%s", WeaponName);
					KvGoBack(kv);

					if (KvJumpToKey(kv, WeaponName))
					{
						if (KvGetNum(kv, "enable"))
						{
							GivePlayerItem(client, WeaponName);
							Usages[client]++;
						}
						else CPrintToChat(client, "{olive}[ {green}Stamm {olive}] %T", "WeaponFailed", LANG_SERVER);
					}
					else CPrintToChat(client, "{olive}[ {green}Stamm {olive}] %T", "WeaponFailed", LANG_SERVER);
				}
				else CPrintToChat(client, "{olive}[ {green}Stamm {olive}] %T", "MaximumReached", LANG_SERVER);
			}
		}
	}

	return Plugin_Handled;
}