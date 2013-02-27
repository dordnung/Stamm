#include <sourcemod>
#include <sdktools>
#include <colors>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new maximum;
new Usages[MAXPLAYERS + 1];

new Handle:kv;
new Handle:weaponlist;

public Plugin:myinfo =
{
	name = "Stamm Feature Weapons",
	author = "Popoklopsi",
	version = "1.2",
	description = "Give VIP's weapons",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	decl String:description[64];

	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
		SetFailState("Can't Load Feature, not Supported for your game!");
		
	STAMM_LoadTranslation();
		
	Format(description, sizeof(description), "%T", "GetWeapons", LANG_SERVER);
	
	STAMM_AddFeature("VIP Weapons", description);
}

public OnPluginStart()
{
	decl String:path[PLATFORM_MAX_PATH + 1];

	if (!CColorAllowed(Color_Lightgreen) && CColorAllowed(Color_Lime))
 	 	CReplaceColor(Color_Lightgreen, Color_Lime);

	if (STAMM_GetGame() == GameCSGO)
		Format(path, sizeof(path), "cfg/stamm/features/WeaponSettings_csgo.txt");
	else
	 	Format(path, sizeof(path), "cfg/stamm/features/WeaponSettings_css.txt");

	if (!FileExists(path))
		SetFailState("Couldn't find the config %s", path);

	RegConsoleCmd("sm_sgive", GiveCallback, "Give VIP's Weapons");
	RegConsoleCmd("sm_sweapons", InfoCallback, "show Weaponlist");
	
	HookEvent("round_start", RoundStart);
	
	kv = CreateKeyValues("WeaponSettings");
	FileToKeyValues(kv, path);
	
	maximum = KvGetNum(kv, "maximum");
	
	weaponlist = CreateMenu(weaponlist_handler);
	SetMenuTitle(weaponlist, "!sgive <weapon_name>");
	
	if (KvGotoFirstSubKey(kv, false))
	{
		decl String:buffer[120];
		decl String:buffer2[120];

		do
		{
			KvGetSectionName(kv, buffer, sizeof(buffer));

			strcopy(buffer2, sizeof(buffer2), buffer);

			ReplaceString(buffer, sizeof(buffer), "weapon_", "");

			KvGoBack(kv);
			
			if (!StrEqual(buffer2, "maximum") && KvGetNum(kv, buffer2) == 1) 
				AddMenuItem(weaponlist, buffer, buffer);

			KvJumpToKey(kv, buffer2);
		} 
		while (KvGotoNextKey(kv, false));

		KvRewind(kv);
	}
}

public weaponlist_handler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (STAMM_IsClientValid(param1))
		{
			decl String:choose[64];
				
			GetMenuItem(menu, param2, choose, sizeof(choose));
			
			FakeClientCommandEx(param1, "sm_sgive %s", choose);
		}
	}
}

public RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	for (new x=0; x <= MaxClients; x++) 
		Usages[x] = 0;
}

public STAMM_OnClientReady(client)
{
	Usages[client] = 0;
}

public Action:InfoCallback(client, args)
{
	if (STAMM_IsClientValid(client) && STAMM_HaveClientFeature(client))
		DisplayMenu(weaponlist, client, 30);
	
	return Plugin_Handled;
}

public Action:GiveCallback(client, args)
{
	if (GetCmdArgs() == 1)
	{
		if (STAMM_IsClientValid(client))
		{
			if (STAMM_HaveClientFeature(client) && IsPlayerAlive(client))
			{
				if (Usages[client] < maximum)
				{
					decl String:WeaponName[64];
					
					GetCmdArg(1, WeaponName, sizeof(WeaponName));
					
					Format(WeaponName, sizeof(WeaponName), "weapon_%s", WeaponName);

					if (KvGetNum(kv, WeaponName))
					{
						GivePlayerItem(client, WeaponName);
						
						Usages[client]++;
					}
					else 
						CPrintToChat(client, "{lightgreen}[ {green}Stamm {lightgreen}] %T", "WeaponFailed", LANG_SERVER);
				}
				else
					CPrintToChat(client, "{lightgreen}[ {green}Stamm {lightgreen}] %T", "MaximumReached", LANG_SERVER);
			}
		}
	}

	return Plugin_Handled;
}