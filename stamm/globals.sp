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
	bool:FEATURE_CHANGE,
	bool:FEATURE_STANDARD,
	bool:FEATURE_ENABLE,
	bool:WANT_FEATURE[MAXPLAYERS + 1],
	String:FEATURE_BASE[64],
	String:FEATURE_BASEREAL[64],
	String:FEATURE_NAME[64],
	Handle:FEATURE_HANDLE,
	Handle:FEATURE_DESCS[MAXLEVELS],
}





// Games
enum StammGames
{
	GAME_UNSUPPORTED=0,
	GAME_CSS,
	GAME_CSGO,
	GAME_TF2,
	GAME_DOD,
}







// Save information about MAXFEATURES features
new g_FeatureList[MAXFEATURES][FeatureEnum];




// Cell globals
new g_iFeatures;
new g_iMinPlayer;
new g_iServerID;
new g_iVipType;
new g_iTimePoint;
new g_iShowPoints;
new g_iDelete;
new g_iLevels;
new g_iPLevels;
new g_iLevelPoints[MAXLEVELS];
new g_iPointsNumber[MAXPLAYERS + 1];
new g_iHappyNumber[MAXPLAYERS + 1];
new g_iHappyFactor[MAXPLAYERS + 1];
new g_iPlayerPoints[MAXPLAYERS + 1];
new g_iPlayerLevel[MAXPLAYERS + 1];
new g_iPoints;
new StammGames:g_iGameID;





// Float globals
new Float:g_fInfoTime;





// String globals
new String:g_sAdminMenu[32];
new String:g_sLogFile[PLATFORM_MAX_PATH + 1];
new String:g_sDebugFile[PLATFORM_MAX_PATH + 1];
new String:g_sLvlUpSound[PLATFORM_MAX_PATH + 1];
new String:g_sPluginVersion[10] = "2.18";
new String:g_sPluginVersionUpdate[10] = "2.1.8";
new String:g_sTableName[64];
new String:g_sTextToWrite[32];
new String:g_sTextToWriteF[32];
new String:g_sVipList[32];
new String:g_sVipListF[32];
new String:g_sVipRank[32];
new String:g_sVipRankF[32];
new String:g_sInfo[32];
new String:g_sInfoF[32];
new String:g_sChange[32];
new String:g_sChangeF[32];
new String:g_sStammTag[64];
new String:g_sAdminFlag[26];
new String:g_sDatabaseVersion[10];
new String:g_sGiveFlagAdmin[26];


// Level and Feature string globals
new String:g_sLevelName[MAXLEVELS][32];
new String:g_sLevelFlag[MAXLEVELS][26];
new String:g_sFeatureBlocks[MAXFEATURES][MAXLEVELS][32];






// Global bools
new bool:g_bClientReady[MAXPLAYERS + 1];
new bool:g_sPluginStarted;
new bool:g_bIsLate;
new bool:g_bAutoUpdate;
new bool:g_bJoinShow;
new bool:g_bSeeText;
new bool:g_bDebug;
new bool:g_bExtraPoints;
new bool:g_bHudText;
new bool:g_bStripTag;
new bool:g_bUseMenu;
new bool:g_bHappyHourON;
new bool:g_bMoreColors;



// Global handles
new Handle:g_hHappyTimer;
new Handle:g_hHudSync;