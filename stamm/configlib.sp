/**
 * -----------------------------------------------------
 * File        configlib.sp
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



// Semicolon
#pragma semicolon 1



// Config handles 
new Handle:configlib_StammVersion;
new Handle:configlib_StammTag;
new Handle:configlib_AdminMenu;
new Handle:configlib_GiveFlagAdmin;
new Handle:configlib_InfoTime;
new Handle:configlib_ShowPoints;
new Handle:configlib_StammDebug;
new Handle:configlib_JoinShow;
new Handle:configlib_AdminFlag;
new Handle:configlib_ExtraPoints;
new Handle:configlib_LvlUpSound;
new Handle:configlib_MinPlayer;
new Handle:configlib_Delete;
new Handle:configlib_SeeText;
new Handle:configlib_ServerID;
new Handle:configlib_TextToWrite;
new Handle:configlib_VipType;
new Handle:configlib_TableName;
new Handle:configlib_HudText;
new Handle:configlib_TimePoint;
new Handle:configlib_VipList;
new Handle:configlib_Info;
new Handle:configlib_Change;
new Handle:configlib_VipRank;
new Handle:configlib_WantUpdate;
new Handle:configlib_StripTag;
new Handle:configlib_UseMenu;





// Create the config
public configlib_CreateConfig()
{
	// Set file
	AutoExecConfig_SetFile("stamm_config", "stamm");
	
	// Global versions cvar
	configlib_StammVersion = AutoExecConfig_CreateConVar("stamm_ver", g_sPluginVersion, "Stamm Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);




	// Add all the natives
	configlib_StammTag = AutoExecConfig_CreateConVar("stamm_tag", "{lightgreen}[ {green}Stamm {lightgreen}]", "Stamm Tag to use in Chat. For Source 2009 Games you can use morecolors.");
	configlib_AdminMenu = AutoExecConfig_CreateConVar("stamm_admin_menu", "sm_sadmin", "Command for Admin Menu");
	configlib_StammDebug = AutoExecConfig_CreateConVar("stamm_debug", "0", "1=Log in an extra File lot of information, 0=disable");
	configlib_ExtraPoints = AutoExecConfig_CreateConVar("stamm_extrapoints", "0", "1 = Give less Players more Points, with factor: ((max players on your server) - (current players)), 0 = disable");
	configlib_ShowPoints = AutoExecConfig_CreateConVar("stamm_showpoints", "480", "Shows every x Seconds all Players their Points (480 = 8 minutes), 0 = Off");
	configlib_GiveFlagAdmin = AutoExecConfig_CreateConVar("stamm_oflag", "0", "Flags a player needs to get instantly highest VIP see addons/sourcemod/configs/admin_levels.cfg for all flags), 0 = Off");
	configlib_Delete = AutoExecConfig_CreateConVar("stamm_delete", "0", "x = Days until a inactive player gets deleted, 0 = Off");
	configlib_AdminFlag = AutoExecConfig_CreateConVar("stamm_adminflag", "bt", "Flag a player needs to access the stamm admin menu (see addons/sourcemod/configs/admin_levels.cfg for all flags)");
	configlib_InfoTime = AutoExecConfig_CreateConVar("stamm_infotime", "300", "Info Message Interval in seconds (300 = 5 minutes), 0 = Off");
	configlib_JoinShow = AutoExecConfig_CreateConVar("stamm_join_show", "1", "1 = When a Player join, he see his points, 0 = OFF");
	configlib_LvlUpSound = AutoExecConfig_CreateConVar("stamm_lvl_up_sound", "stamm/lvlup.mp3", "Path to the level up sound, beginning after sound/, 0 = Off");
	configlib_MinPlayer = AutoExecConfig_CreateConVar("stamm_min_player", "0", "Number of Players, which have to be on the Server, to count points");
	configlib_SeeText = AutoExecConfig_CreateConVar("stamm_see_text", "1", "1 = All see the players points, 0 = only the player, who write it in the chat");
	configlib_ServerID = AutoExecConfig_CreateConVar("stamm_serverid", "1", "If you have more than one Server, type here your Server number in, e.g. 1. Server = 1");
	configlib_TextToWrite = AutoExecConfig_CreateConVar("stamm_texttowrite", "sm_stamm", "Command to see currently points");
	configlib_VipType = AutoExecConfig_CreateConVar("stamm_vip_type", "1", "How to get Points, 1=kills, 2=rounds, 3=time, 4=kills&rounds, 5=kills&time, 6=rounds&time, 7=kills&rounds&time");
	configlib_TimePoint = AutoExecConfig_CreateConVar("stamm_time_point", "1", "How much minutes are one point?");
	configlib_VipList = AutoExecConfig_CreateConVar("stamm_viplist", "sm_slist", "Command for VIP Top 10");
	configlib_TableName = AutoExecConfig_CreateConVar("stamm_table_name", "STAMM_DB", "Your Stamm Table Name. It appends '_<serverid>' at the end!");
	configlib_Info = AutoExecConfig_CreateConVar("stamm_info_cmd", "sm_sinfo", "Command to see infos about stamm");
	configlib_Change = AutoExecConfig_CreateConVar("stamm_change_cmd", "sm_schange", "Command to put ones features on/off");
	configlib_HudText = AutoExecConfig_CreateConVar("stamm_hudtext", "1", "(Only TF2) 1 = Show points always on HUD, 0 = Off");
	configlib_VipRank = AutoExecConfig_CreateConVar("stamm_viprank", "sm_srank", "Command for VIP Rank");
	configlib_WantUpdate = AutoExecConfig_CreateConVar("stamm_autoupdate", "1", "1 = Auto Update Stamm and it's features (Needs the Auto Updater), 0 = Off");
	configlib_StripTag = AutoExecConfig_CreateConVar("stamm_striptag", "0", "1 = Use level instead of VIP, 0 = Use term VIP");
	configlib_UseMenu = AutoExecConfig_CreateConVar("stamm_usemenu", "1", "1 = Player sees a menu when typing stamm command, 0 = Just a chat message");




	// Autoexec
	AutoExecConfig(true, "stamm_config", "stamm");
	
	AutoExecConfig_CleanFile();


	// Hook Changes
	SetConVarString(configlib_StammVersion, g_sPluginVersion);
	HookConVarChange(configlib_StammVersion, OnCvarChanged);
	HookConVarChange(configlib_StammTag, OnCvarChanged);
	HookConVarChange(configlib_StammDebug, OnCvarChanged);
	HookConVarChange(configlib_ExtraPoints, OnCvarChanged);
	HookConVarChange(configlib_GiveFlagAdmin, OnCvarChanged);
	HookConVarChange(configlib_AdminFlag, OnCvarChanged);
	HookConVarChange(configlib_JoinShow, OnCvarChanged);
	HookConVarChange(configlib_MinPlayer, OnCvarChanged);
	HookConVarChange(configlib_SeeText, OnCvarChanged);
	HookConVarChange(configlib_StripTag, OnCvarChanged);
	HookConVarChange(configlib_UseMenu, OnCvarChanged);
	HookConVarChange(configlib_WantUpdate, OnCvarChanged);
}






// Load the config
public configlib_LoadConfig()
{
	// Read all values from the cvars
	g_fInfoTime = GetConVarFloat(configlib_InfoTime);
	g_iShowPoints = GetConVarInt(configlib_ShowPoints);
	g_iDelete = GetConVarInt(configlib_Delete);
	g_iMinPlayer = GetConVarInt(configlib_MinPlayer);
	g_iTimePoint = GetConVarInt(configlib_TimePoint);
	g_iServerID = GetConVarInt(configlib_ServerID);
	g_iVipType = GetConVarInt(configlib_VipType);


	// Strings
	GetConVarString(configlib_StammTag, g_sStammTag, sizeof(g_sStammTag));
	GetConVarString(configlib_AdminMenu, g_sAdminMenu, sizeof(g_sAdminMenu));
	GetConVarString(configlib_LvlUpSound, g_sLvlUpSound, sizeof(g_sLvlUpSound));
	GetConVarString(configlib_TextToWrite, g_sTextToWrite, sizeof(g_sTextToWrite));
	GetConVarString(configlib_VipList, g_sVipList, sizeof(g_sVipList));
	GetConVarString(configlib_VipRank, g_sVipRank, sizeof(g_sVipRank));
	GetConVarString(configlib_Change, g_sChange, sizeof(g_sChange));
	GetConVarString(configlib_Info, g_sInfo, sizeof(g_sInfo));
	GetConVarString(configlib_TableName, g_sTableName, sizeof(g_sTableName));
	GetConVarString(configlib_AdminFlag, g_sAdminFlag, sizeof(g_sAdminFlag));
	GetConVarString(configlib_GiveFlagAdmin, g_sGiveFlagAdmin, sizeof(g_sGiveFlagAdmin));
	configlib_FixGiveFlagAdmin();



	// Bools
	g_bAutoUpdate = GetConVarBool(configlib_WantUpdate);
	g_bDebug = GetConVarBool(configlib_StammDebug);
	g_bExtraPoints = GetConVarBool(configlib_ExtraPoints);
	g_bJoinShow = GetConVarBool(configlib_JoinShow);
	g_bSeeText = GetConVarBool(configlib_SeeText);
	g_bHudText = GetConVarBool(configlib_HudText);
	g_bStripTag = GetConVarBool(configlib_StripTag);
	g_bUseMenu = GetConVarBool(configlib_UseMenu);




	// Format the tablename
	Format(g_sTableName, sizeof(g_sTableName), "%s_%i", g_sTableName, g_iServerID);

	


	// Found any level?
	if (g_iLevels <= 0 && g_iPLevels <= 0) 
	{
		LogToFile(g_sLogFile, "[ STAMM ] Attention! Found no Stamm levels!!");
	}
}






// A Convar Changed
public OnCvarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (cvar == configlib_StammVersion)
	{
		if (!StrEqual(newValue, g_sPluginVersion))
		{
			SetConVarString(configlib_StammVersion, g_sPluginVersion);
		}
	}

	else if (cvar == configlib_StammDebug)
	{
		g_bDebug = GetConVarBool(configlib_StammDebug);
	}

	else if (cvar == configlib_StammTag)
	{
		GetConVarString(configlib_StammTag, g_sStammTag, sizeof(g_sStammTag));
	}

	else if (cvar == configlib_ExtraPoints)
	{
		g_bExtraPoints = GetConVarBool(configlib_ExtraPoints);
	}

	else if (cvar == configlib_WantUpdate)
	{
		g_bAutoUpdate = GetConVarBool(configlib_WantUpdate);
	}

	else if (cvar == configlib_GiveFlagAdmin)
	{
		GetConVarString(configlib_GiveFlagAdmin, g_sGiveFlagAdmin, sizeof(g_sGiveFlagAdmin));
		configlib_FixGiveFlagAdmin();
	}

	else if (cvar == configlib_AdminFlag)
	{
		GetConVarString(configlib_AdminFlag, g_sAdminFlag, sizeof(g_sAdminFlag));
	}

	else if (cvar == configlib_JoinShow)
	{
		g_bJoinShow = GetConVarBool(configlib_JoinShow);
	}

	else if (cvar == configlib_MinPlayer)
	{
		g_iMinPlayer = GetConVarInt(configlib_MinPlayer);
	}

	else if (cvar == configlib_SeeText)
	{
		g_bSeeText = GetConVarBool(configlib_SeeText);
	}

	else if (cvar == configlib_StripTag)
	{
		g_bStripTag = GetConVarBool(configlib_StripTag);
	}

	else if (cvar == configlib_UseMenu)
	{
		g_bUseMenu = GetConVarBool(configlib_UseMenu);
	}
}





// Backwards Compatiblity
public configlib_FixGiveFlagAdmin()
{
	// Before we had numbers, now we have flags
	// Replace numbers with flags
	if (StrEqual(g_sGiveFlagAdmin, "1"))
	{
		Format(g_sGiveFlagAdmin, sizeof(g_sGiveFlagAdmin), "o");
	}

	else if (StrEqual(g_sGiveFlagAdmin, "2"))
	{
		Format(g_sGiveFlagAdmin, sizeof(g_sGiveFlagAdmin), "p");
	}

	else if (StrEqual(g_sGiveFlagAdmin, "3"))
	{
		Format(g_sGiveFlagAdmin, sizeof(g_sGiveFlagAdmin), "q");
	}

	else if (StrEqual(g_sGiveFlagAdmin, "4"))
	{
		Format(g_sGiveFlagAdmin, sizeof(g_sGiveFlagAdmin), "r");
	}

	else if (StrEqual(g_sGiveFlagAdmin, "5"))
	{
		Format(g_sGiveFlagAdmin, sizeof(g_sGiveFlagAdmin), "s");
	}

	else if (StrEqual(g_sGiveFlagAdmin, "6"))
	{
		Format(g_sGiveFlagAdmin, sizeof(g_sGiveFlagAdmin), "t");
	}
}