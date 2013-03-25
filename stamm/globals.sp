/**
 * -----------------------------------------------------
 * File        globals.sp
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


// Use semicolon
#pragma semicolon 1


// This we need to save all information about a feature
enum FeatureEnum
{
	FEATURE_LEVEL[MAXLEVELS],
	FEATURE_ENABLE,
	FEATURE_DESCS[MAXLEVELS],
	bool:FEATURE_CHANGE,
	bool:FEATURE_STANDARD,
	bool:WANT_FEATURE[MAXPLAYERS + 1],
	String:FEATURE_BASE[64],
	String:FEATURE_BASEREAL[64],
	String:FEATURE_NAME[64],
	Handle:FEATURE_HANDLE,
}

// Save information about MAXFEATURES features
new g_FeatureList[MAXFEATURES][FeatureEnum];


// Cell globals
new g_giveflagadmin;
new g_join_show;
new g_features;
new g_min_player;
new g_see_text;
new g_serverid;
new g_debug;
new g_vip_type;
new g_time_point;
new g_showpoints;
new g_delete;
new g_levels;
new g_plevels;
new g_LevelPoints[MAXLEVELS];
new g_pointsnumber[MAXPLAYERS + 1];
new g_happynumber[MAXPLAYERS + 1];
new g_happyfactor[MAXPLAYERS + 1];
new g_playerpoints[MAXPLAYERS + 1];
new g_playerlevel[MAXPLAYERS + 1];
new g_points;
new g_extra_points;
new g_happyhouron;
new g_gameID;


// Float globals
new Float:g_infotime;



// String globals
new String:g_admin_menu[32];
new String:g_LogFile[PLATFORM_MAX_PATH + 1];
new String:g_DebugFile[PLATFORM_MAX_PATH + 1];
new String:g_StammFolder[PLATFORM_MAX_PATH + 1];
new String:g_lvl_up_sound[PLATFORM_MAX_PATH + 1];
new String:g_Plugin_Version[10] = "2.13";
new String:g_Plugin_Version2[10] = "2.1.3";
new String:g_tablename[64];
new String:g_texttowrite[32];
new String:g_texttowrite_f[32];
new String:g_viplist[32];
new String:g_viplist_f[32];
new String:g_viprank[32];
new String:g_viprank_f[32];
new String:g_sinfo[32];
new String:g_sinfo_f[32];
new String:g_schange[32];
new String:g_schange_f[32];
new String:g_StammTag[64];
new String:g_adminflag[3];
new String:g_databaseVersion[10];


// Level and Feature string globals
new String:g_LevelName[MAXLEVELS][128];
new String:g_LevelFlag[MAXLEVELS][10];
// This is VERY nasty, try to keep it as small as possible
new String:g_FeatureHaveDesc[MAXFEATURES][MAXLEVELS][5][64];
new String:g_FeatureBlocks[MAXFEATURES][MAXLEVELS][64];

// Global bools
new bool:g_ClientReady[MAXPLAYERS + 1];
new bool:g_pluginStarted;
new bool:g_isLate;
new bool:autoUpdate;

// Global handls
new Handle:g_HappyTimer;