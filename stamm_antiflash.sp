#include <sourcemod>
#include <flashtools>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new Handle:antiteamflash_c;
new Handle:antiflash_c;

new antiteamflash;
new antiflash;

public Plugin:myinfo =
{
	name = "Stamm Feature Anti Flash",
	author = "Popoklopsi",
	version = "1.3",
	description = "Give VIP's anti flash",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	if (STAMM_GetGame() == GameTF2 || STAMM_GetGame() == GameDOD) 
		SetFailState("Can't Load Feature, not Supported for your game!");

	if (GetExtensionFileStatus("flashtools.ext") != 1)
		SetFailState("Can't Load Feature, you need to install flashtools!");
		
	STAMM_LoadTranslation();
		
	STAMM_AddFeature("VIP Anti Flash", "");
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:description[64];
	decl String:team[64];
	decl String:team2[64];

	if (antiteamflash) 
		Format(team, sizeof(team), "%T", "GetTeamAntiFlash", LANG_SERVER);
	else 
		Format(team, sizeof(team), "");

	if (antiflash) 
		Format(team2, sizeof(team2), "%T", "AntiTeamFlash", LANG_SERVER);
	else 
		Format(team2, sizeof(team2), "");
		
	Format(description, sizeof(description), "%T", "GetAntiFlash", LANG_SERVER, team, team2);
	
	STAMM_AddFeatureText(STAMM_GetLevel(), description);
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("anti_flash", "stamm/features");

	antiteamflash_c = AutoExecConfig_CreateConVar("vip_antiteamflash", "1", "1=Team will not be flashed by VIP's flashbang!, 0=Off");
	antiflash_c = AutoExecConfig_CreateConVar("vip_antiflash", "1", "1=VIP can't be flashed by anyone, 0=he can't be flashed by team");
	
	AutoExecConfig_AutoExecConfig();
	AutoExecConfig_CleanFile();
}

public OnConfigsExecuted()
{
	antiteamflash = GetConVarInt(antiteamflash_c);
	antiflash = GetConVarInt(antiflash_c);
}

public Action:OnGetPercentageOfFlashForPlayer(client, entity, Float:pos[3], &Float:percent)
{
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	new team = GetClientTeam(client);
	new team2 = GetClientTeam(owner);
	
	if (STAMM_IsClientValid(owner) && STAMM_IsClientValid(client))
	{
		if (team == team2 && owner != client && antiteamflash && STAMM_HaveClientFeature(owner)) 
			return Plugin_Handled;
	}

	if (STAMM_HaveClientFeature(client) && ((antiflash) || (team == team2)))
		return Plugin_Handled;
	
	return Plugin_Continue;
}