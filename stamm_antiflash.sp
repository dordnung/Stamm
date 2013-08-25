#include <sourcemod>
#include <flashtools>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new Handle:antiteamflash_c;

new v_level;
new antiteamflash;

new String:basename[64];

public Plugin:myinfo =
{
	name = "Stamm Feature Anti Flash",
	author = "Popoklopsi",
	version = "1.2",
	description = "Give VIP's anti flash",
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
	
	antiteamflash_c = CreateConVar("vip_antiteamflash", "1", "1=Team will not be flashed by VIP's flashbang!, 0=Off");
	
	AutoExecConfig(true, "anti_flash", "stamm/features");
}

public OnConfigsExecuted()
{
	antiteamflash = GetConVarInt(antiteamflash_c);
}

public OnStammReady()
{
	LoadTranslations("stamm-features.phrases");
	
	new String:description[64];
	new String:team[64];
	
	if (antiteamflash) Format(team, sizeof(team), "%T", "GetTeamAntiFlash", LANG_SERVER);
	else Format(team, sizeof(team), "");
	
	Format(description, sizeof(description), "%T", "GetAntiFlash", LANG_SERVER, team);
	
	v_level = AddStammFeature(basename, "VIP Anti Flash", description);
	
	if (antiteamflash) Format(team, sizeof(team), "%T", "YouGetTeamAntiFlash", LANG_SERVER);
	else Format(team, sizeof(team), "");
	
	Format(description, sizeof(description), "%T", "YouGetAntiFlash", LANG_SERVER, team);
	AddStammFeatureInfo(basename, v_level, description);
}

public Action:OnGetPercentageOfFlashForPlayer(client, entity, Float:pos[3], &Float:percent)
{
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	new team = GetClientTeam(client);
	new team2 = GetClientTeam(owner);
	
	if (IsStammClientValid(owner) && IsStammClientValid(client))
	{
		if(team == team2 && owner != client && antiteamflash && IsClientVip(owner, v_level) && ClientWantStammFeature(owner, basename)) return Plugin_Handled;
		
		if (IsClientVip(client, v_level) && ClientWantStammFeature(client, basename)) return Plugin_Handled;
	}
	
	return Plugin_Continue;
}