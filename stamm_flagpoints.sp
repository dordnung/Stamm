#include <sourcemod>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new Handle:flagneed_c;
new String:flagneed[12];

public Plugin:myinfo =
{
	name = "Stamm Feature FlagPoints",
	author = "Popoklopsi",
	version = "1.0",
	description = "Give only points to players with a specific flag",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnPluginStart()
{
	AutoExecConfig_SetFile("flagpoints", "stamm/features");

	flagneed_c = AutoExecConfig_CreateConVar("flag_need", "s", "Flag a player needs to collect points");
	
	AutoExecConfig_AutoExecConfig();
	AutoExecConfig_CleanFile();
}

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
		
	STAMM_AddFeature("VIP FlagPoints", "");
}

public OnConfigsExecuted()
{
	GetConVarString(flagneed_c, flagneed, sizeof(flagneed));
}

public Action:STAMM_OnClientGetPoints_PRE(client, &number)
{
	if (clientAllowed(client))
		return Plugin_Continue;

	return Plugin_Handled;
}

public bool:clientAllowed(client)
{
	if (STAMM_IsClientValid(client))
	{
		new AdminId:adminid = GetUserAdmin(client);
			
		if (StrEqual(flagneed, "a")) return GetAdminFlag(adminid, Admin_Reservation);
		if (StrEqual(flagneed, "b")) return GetAdminFlag(adminid, Admin_Generic);
		if (StrEqual(flagneed, "c")) return GetAdminFlag(adminid, Admin_Kick);
		if (StrEqual(flagneed, "d")) return GetAdminFlag(adminid, Admin_Ban);
		if (StrEqual(flagneed, "e")) return GetAdminFlag(adminid, Admin_Unban);
		if (StrEqual(flagneed, "f")) return GetAdminFlag(adminid, Admin_Slay);
		if (StrEqual(flagneed, "g")) return GetAdminFlag(adminid, Admin_Changemap);
		if (StrEqual(flagneed, "h")) return GetAdminFlag(adminid, Admin_Convars);
		if (StrEqual(flagneed, "i")) return GetAdminFlag(adminid, Admin_Config);
		if (StrEqual(flagneed, "j")) return GetAdminFlag(adminid, Admin_Chat);
		if (StrEqual(flagneed, "k")) return GetAdminFlag(adminid, Admin_Vote);
		if (StrEqual(flagneed, "l")) return GetAdminFlag(adminid, Admin_Password);
		if (StrEqual(flagneed, "m")) return GetAdminFlag(adminid, Admin_RCON);
		if (StrEqual(flagneed, "n")) return GetAdminFlag(adminid, Admin_Cheats);
		if (StrEqual(flagneed, "o")) return GetAdminFlag(adminid, Admin_Custom1);
		if (StrEqual(flagneed, "p")) return GetAdminFlag(adminid, Admin_Custom2);
		if (StrEqual(flagneed, "q")) return GetAdminFlag(adminid, Admin_Custom3);
		if (StrEqual(flagneed, "r")) return GetAdminFlag(adminid, Admin_Custom4);
		if (StrEqual(flagneed, "s")) return GetAdminFlag(adminid, Admin_Custom5);
		if (StrEqual(flagneed, "t")) return GetAdminFlag(adminid, Admin_Custom6);
		if (StrEqual(flagneed, "z")) return GetAdminFlag(adminid, Admin_Root);
	}
	
	return false;
}