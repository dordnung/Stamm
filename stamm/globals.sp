#pragma semicolon 1

enum FeatureEnum
{
	FEATURE_LEVEL[80],
	FEATURE_ENABLE,
	FEATURE_DESCS[80],
	bool:FEATURE_CHANGE,
	bool:FEATURE_STANDARD,
	bool:WANT_FEATURE[MAXPLAYERS + 1],
	String:FEATURE_BASE[64],
	String:FEATURE_BASEREAL[64],
	String:FEATURE_NAME[64],
	Handle:FEATURE_HANDLE,
}

new g_FeatureList[120][FeatureEnum];

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
new g_LevelPoints[80];
new g_pointsnumber[MAXPLAYERS + 1];
new g_happynumber[MAXPLAYERS + 1];
new g_happyfactor[MAXPLAYERS + 1];
new g_playerpoints[MAXPLAYERS + 1];
new g_playerlevel[MAXPLAYERS + 1];
new g_points;
new g_extra_points;
new g_happyhouron;
new g_gameID;

new Float:g_infotime;

new String:g_admin_menu[32];
new String:g_LogFile[PLATFORM_MAX_PATH + 1];
new String:g_DebugFile[PLATFORM_MAX_PATH + 1];
new String:g_StammFolder[PLATFORM_MAX_PATH + 1];
new String:g_lvl_up_sound[PLATFORM_MAX_PATH + 1];
new String:g_Plugin_Version[10] = "2.1";
new String:g_Plugin_Version2[10] = "2.1.1";
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
new String:g_sme[32];
new String:g_sme_f[32];
new String:g_StammTag[64];
new String:g_adminflag[3];
new String:g_databaseVersion[10];

new String:g_LevelName[80][128];
new String:g_LevelFlag[80][10];
new String:g_FeatureHaveDesc[120][80][5][64];
new String:g_FeatureBlocks[120][80][64];

new bool:g_ClientReady[MAXPLAYERS + 1];
new bool:g_pluginStarted;
new bool:g_isLate;

new Handle:g_HappyTimer;
