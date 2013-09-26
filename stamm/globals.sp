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



// Max Features and Max Levels
#define MAXFEATURES 100
#define MAXLEVELS 100



// Updater
#define UPDATE_URL "http://popoklopsi.de/stamm/updater/update.php?plugin=stamm"



// This we need to save all information about a feature
enum FeatureEnum
{
	FEATURE_LEVEL[MAXLEVELS],
	/* TODO: IMPLEMENT
	FEATURE_POINTS[MAXLEVELS],*/
	FEATURE_BLOCKS,
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
new g_iCommands;
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
new String:g_sPluginVersion[10] = "2.2";
new String:g_sPluginVersionUpdate[10] = "2.2.0";
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
new String:g_sGiveFlagAdmin[26];
new String:g_sDatabaseVersion[12];
new String:g_sCommandName[MAXFEATURES][64];
new String:g_sCommand[MAXFEATURES][64];


// Level and Feature string globals
new String:g_sLevelName[MAXLEVELS][32];
new String:g_sLevelKey[MAXLEVELS][32];
new String:g_sLevelFlag[MAXLEVELS][26];





// Global bools
new bool:g_bClientReady[MAXPLAYERS + 1];
new bool:g_bPluginStarted;
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
new bool:g_bShowTextOnPoints;



// Global handles
/* TODO: IMPLEMENT new Handle:g_hBoughtBlock[MAXPLAYERS + 1][MAXFEATURES];*/
new Handle:g_hFeatureBlocks[MAXFEATURES];
new Handle:g_hHappyTimer;
new Handle:g_hHudSync;







// Define here the SQL querys
#define g_sCreateBackupQuery "CREATE TABLE IF NOT EXISTS `%s_backup` (`steamid` VARCHAR(20) NOT NULL DEFAULT '', `level` INT NOT NULL DEFAULT 0, `points` INT NOT NULL DEFAULT 0, `name` VARCHAR(64) NOT NULL DEFAULT '', `admin` TINYINT UNSIGNED NOT NULL DEFAULT 0, `version` FLOAT NOT NULL DEFAULT 0.0, `last_visit` INT UNSIGNED NOT NULL DEFAULT %i, PRIMARY KEY (`steamid`))"
#define g_sCreateTableQuery "CREATE TABLE IF NOT EXISTS `%s` (`steamid` VARCHAR(21) NOT NULL DEFAULT '', `level` TINYINT NOT NULL DEFAULT 0, `points` INT NOT NULL DEFAULT 0, `name` VARCHAR(64) NOT NULL DEFAULT '', `admin` TINYINT UNSIGNED NOT NULL DEFAULT 0, `version` FLOAT NOT NULL DEFAULT 0.0, `last_visit` INT UNSIGNED NOT NULL DEFAULT %i, PRIMARY KEY (`steamid`))"
#define g_sCreateBackupQueryMySQL "CREATE TABLE IF NOT EXISTS `%s_backup` (`steamid` VARCHAR(20) NOT NULL DEFAULT '', `level` INT NOT NULL DEFAULT 0, `points` INT NOT NULL DEFAULT 0, `name` VARCHAR(64) NOT NULL DEFAULT '', `admin` TINYINT UNSIGNED NOT NULL DEFAULT 0, `version` FLOAT NOT NULL DEFAULT 0.0, `last_visit` INT UNSIGNED NOT NULL DEFAULT %i, PRIMARY KEY (`steamid`)) COLLATE='utf8_general_ci'"
#define g_sCreateTableQueryMySQL "CREATE TABLE IF NOT EXISTS `%s` (`steamid` VARCHAR(21) NOT NULL DEFAULT '', `level` TINYINT NOT NULL DEFAULT 0, `points` INT NOT NULL DEFAULT 0, `name` VARCHAR(64) NOT NULL DEFAULT '', `admin` TINYINT UNSIGNED NOT NULL DEFAULT 0, `version` FLOAT NOT NULL DEFAULT 0.0, `last_visit` INT UNSIGNED NOT NULL DEFAULT %i, PRIMARY KEY (`steamid`)) COLLATE='utf8_general_ci'"

/* TODO: IMPLEMENT #define g_sCreateFeatureQuery "CREATE TABLE IF NOT EXISTS `%s_shop` (`steamid` VARCHAR(21) NOT NULL, `feature` varchar(64) NOT NULL, `block` varchar(64) NOT NULL, UNIQUE (steamid, feature, block))" */
#define g_sCreatHappyQuery "CREATE TABLE IF NOT EXISTS `%s_happy` (`end` INT UNSIGNED NOT NULL DEFAULT 2, `factor` TINYINT UNSIGNED NOT NULL DEFAULT 2)"


#define g_sDeleteOldQuery "DELETE FROM `%s` WHERE `last_visit` < %i"
#define g_sDeletePlayerQuery "DELETE FROM `%s` WHERE `steamid`='%s'"
#define g_sDeletePlayerShopQuery "DELETE FROM `%s_shop` WHERE `steamid`='%s' AND `feature`='%s' AND `block`='%s'"
#define g_sDeleteHappyQuery "DELETE FROM `%s_happy`"


#define g_sUpdatePlayerQuery "UPDATE `%s` SET `level`=%i WHERE `steamid`='%s'"
#define g_sUpdateSetPointsLevelZeroQuery "UPDATE `%s` SET `level`=0,`points`=0 WHERE `steamid`='%s'"
#define g_sUpdateSetPointsZeroQuery "UPDATE `%s` SET `points`=0 "
#define g_sUpdateSetPointsQuery "UPDATE `%s` SET `points`=%i WHERE `steamid`='%s'"
#define g_sUpdateAddPointsQuery "UPDATE `%s` SET `points`=`points`+(%i) "
#define g_sUpdateAddPointsSteamidQuery "UPDATE `%s` SET `points`=`points`+(%i) WHERE `steamid`='%s'"
#define g_sUpdatePlayer2Query "UPDATE `%s` SET `name`='%s', `admin` = %i, `version`=%s, `last_visit`=%i WHERE `steamid`='%s'"


#define g_sInsertHappyQuery "INSERT INTO `%s_happy` (`end`, `factor`) VALUES (%i, %i)"
#define g_sInsertMiddleQuery "%s FROM `%s` WHERE steamid = '%s'"
#define g_sInsertPlayerQuery "INSERT INTO `%s` (`steamid`, `name`, `admin`, `version`, `last_visit`) VALUES ('%s', '%s', %i, 0.0, %i)"
/* TODO: IMPLEMENT #define g_sInsertPlayerShopQuery "INSERT INTO `%s_shop` (`steamid`, `feature`, `block`) VALUES ('%s', '%s', '%s')" */
#define g_sInsertPlayerSaveQuery "INSERT INTO `%s` (`steamid`, `level`, `points`, `name`, `version`, `last_visit`) VALUES ('%s', %i, %i, '%s', %s, %i)"
#define g_sInsertPlayerSave2Query "INSERT INTO `%s` (`steamid`, `level`, `points`, `name`, `version`, `last_visit`) VALUES"
#define g_sInsertPlayerSave2DataQuery "('%s', %i, %i, '%s', %s, %i);"
#define g_sInsertPlayerSave2Data2Query "('%s', %i, %i, '%s', %s, %i),"
/* TODO: IMPLEMENT #define g_sInsertPlayerSave2QueryShop "INSERT INTO `%s_shop` (`steamid`, `feature`, `block`) VALUES" */
#define g_sInsertPlayerSave2DataQueryShop "('%s', '%s', '%s');"
#define g_sInsertPlayerSave2Data2QueryShop "('%s', '%s', '%s'),"
#define g_sInsertBackupQuery "INSERT INTO `%s_backup` (`steamid`, `name`, `level`, `points`) SELECT `steamid`, `name`, `level`, `kills`+`rounds`+`time` FROM `%s`"


#define g_sSelectVersionQuery "SELECT REPLACE(`version`, '.', '') FROM `%s` ORDER BY `version` DESC LIMIT 1"
#define g_sSelectHappyQuery "SELECT `end`, `factor` FROM `%s_happy` WHERE `end` > %i LIMIT 1"
#define g_sSelectPointsQuery "SELECT `points` FROM `%s` WHERE `steamid`='%s'"
#define g_sSelectAllPointsQuery "SELECT `VIP` FROM `%s` LIMIT 1"
#define g_sSelectTop10Query "SELECT `name`, `points` FROM `%s` WHERE `level` > 0 ORDER BY `points` DESC LIMIT 10"
#define g_sSelectRankQuery "SELECT COUNT(*) FROM `%s` WHERE `points` >= %i"
#define g_sSelectPlayerQuery "SELECT `steamid`, `level`, `points`, `name`, `version`, `last_visit` FROM `%s`"
/* TODO: IMPLEMENT #define g_sSelectPlayerShopAllQuery "SELECT `steamid`, `feature`, `block` FROM `%s_shop`" */
#define g_sSelectPlayerStartQuery "SELECT `points`, `level`, `version`"
/* TODO: IMPLEMENT #define g_sSelectPlayerShopQuery "SELECT `feature`, `block` FROM `%s_shop` WHERE steamid = '%s'" */


#define g_sAlterAdminQuery "ALTER TABLE `%s` ADD `admin` TINYINT UNSIGNED NOT NULL DEFAULT 0"
#define g_sAlterLastVisitQuery "ALTER TABLE `%s` ADD `last_visit` INT UNSIGNED NOT NULL DEFAULT %i"
#define g_sAlterVersionQuery "ALTER TABLE `%s` ADD `version` FLOAT NOT NULL DEFAULT 0.0"
#define g_sAlterPayedQuery "ALTER TABLE `%s` DROP `payed`"
#define g_sAlterRenameQuery "ALTER TABLE `%s` RENAME TO `%s_old`"
#define g_sAlterRename2Query "ALTER TABLE `%s_backup` RENAME TO `%s`"
#define g_sAlterFeatureQuery "ALTER TABLE `%s` ADD `%s` TINYINT NOT NULL DEFAULT %i"