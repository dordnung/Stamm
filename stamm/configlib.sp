#pragma semicolon 1

new Handle:configlib_admin_menu;
new Handle:configlib_giveflagadmin;
new Handle:configlib_infotime;
new Handle:configlib_showpoints;
new Handle:configlib_stamm_debug;
new Handle:configlib_join_show;
new Handle:configlib_adminflag;
new Handle:configlib_extra_points;
new Handle:configlib_lvl_up_sound;
new Handle:configlib_min_player;
new Handle:configlib_delete;
new Handle:configlib_see_text;
new Handle:configlib_serverid;
new Handle:configlib_texttowrite;
new Handle:configlib_vip_type;
new Handle:configlib_tablename;
new Handle:configlib_time_point;
new Handle:configlib_viplist;
new Handle:configlib_sinfo;
new Handle:configlib_schange;
new Handle:configlib_viprank;

public configlib_CreateConfig()
{
	AutoExecConfig_SetFile("stamm_config", "stamm");
	
	AutoExecConfig_CreateConVar("stamm_ver", g_Plugin_Version, "Stamm Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	configlib_admin_menu = AutoExecConfig_CreateConVar("stamm_admin_menu", "sm_sadmin", "Command for Admin Menu");
	configlib_stamm_debug = AutoExecConfig_CreateConVar("stamm_debug", "0", "1=Log in an extra File lot of information, 0=disable");
	configlib_extra_points = AutoExecConfig_CreateConVar("stamm_extrapoints", "0", "1 = Give less Players more Points, with factor: ((max players on your server) - (current players)), 0 = disable");
	configlib_showpoints = AutoExecConfig_CreateConVar("stamm_showpoints", "480", "Shows every x Seconds all Players their Points (480 = 8 minutes), 0 = Off");
	configlib_giveflagadmin = AutoExecConfig_CreateConVar("stamm_oflag", "0", "not 0 = a Player with the a special Flag become VIP (1='o', 2='p' , 3='q', 4='r', 5='s', 6='t'), 0 = Off");
	configlib_delete = AutoExecConfig_CreateConVar("stamm_delete", "0", "x = Days until a inactive player gets deleted, 0 = Off");
	configlib_adminflag = AutoExecConfig_CreateConVar("stamm_adminflag", "t", "Flag a player needs to access the stamm admin menu (see addons/sourcemod/configs/admin_levels.cfg for all flags)");
	configlib_infotime = AutoExecConfig_CreateConVar("stamm_infotime", "300", "Info Message Interval in seconds (300 = 5 minutes), 0 = Off");
	configlib_join_show = AutoExecConfig_CreateConVar("stamm_join_show", "1", "1 = When a Player join, he see his points, 0 = OFF");
	configlib_lvl_up_sound = AutoExecConfig_CreateConVar("stamm_lvl_up_sound", "music/stamm/lvlup.mp3", "Path to the level up sound, beginning after sound/, 0 = Off");
	configlib_min_player = AutoExecConfig_CreateConVar("stamm_min_player", "0", "Number of Players, which have to be on the Server, to count points");
	configlib_see_text = AutoExecConfig_CreateConVar("stamm_see_text", "1", "1 = All see the players points, 0 = only the player, who write it in the chat");
	configlib_serverid = AutoExecConfig_CreateConVar("stamm_serverid", "1", "If you have more than one Server, type here your Server number in, e.g. 1. Server = 1");
	configlib_texttowrite = AutoExecConfig_CreateConVar("stamm_texttowrite", "sm_stamm", "Command to see currently points");
	configlib_vip_type = AutoExecConfig_CreateConVar("stamm_vip_type", "1", "How to get Points, 1=kills, 2=rounds, 3=time, 4=kills&rounds, 5=kills&time, 6=rounds&time, 7=kills&rounds&time");
	configlib_time_point = AutoExecConfig_CreateConVar("stamm_time_point", "1", "How much minutes are one point?");
	configlib_viplist = AutoExecConfig_CreateConVar("stamm_viplist", "sm_slist", "Command for VIP Top 10");
	configlib_tablename = AutoExecConfig_CreateConVar("stamm_table_name", "STAMM_DB", "Your Stamm Table Name. It appends '_<serverid>' at the end!");
	configlib_sinfo = AutoExecConfig_CreateConVar("stamm_info_cmd", "sm_sinfo", "Command to see infos about stamm");
	configlib_schange = AutoExecConfig_CreateConVar("stamm_change_cmd", "sm_schange", "Command to put ones features on/off");
	configlib_viprank = AutoExecConfig_CreateConVar("stamm_viprank", "sm_srank", "Command for VIP Rank");

	AutoExecConfig(true, "stamm_config", "stamm");
	
	AutoExecConfig_CleanFile();
}

public configlib_LoadConfig()
{
	g_giveflagadmin = GetConVarInt(configlib_giveflagadmin);
	g_infotime = GetConVarFloat(configlib_infotime);
	g_debug = GetConVarInt(configlib_stamm_debug);
	g_extra_points = GetConVarInt(configlib_extra_points);
	g_showpoints = GetConVarInt(configlib_showpoints);
	g_join_show = GetConVarInt(configlib_join_show);
	g_delete = GetConVarInt(configlib_delete);
	g_min_player = GetConVarInt(configlib_min_player);
	g_see_text = GetConVarInt(configlib_see_text);
	g_time_point = GetConVarInt(configlib_time_point);
	g_serverid = GetConVarInt(configlib_serverid);
	g_vip_type = GetConVarInt(configlib_vip_type);
	
	GetConVarString(configlib_admin_menu, g_admin_menu, sizeof(g_admin_menu));
	GetConVarString(configlib_lvl_up_sound, g_lvl_up_sound, sizeof(g_lvl_up_sound));
	GetConVarString(configlib_texttowrite, g_texttowrite, sizeof(g_texttowrite));
	GetConVarString(configlib_viplist, g_viplist, sizeof(g_viplist));
	GetConVarString(configlib_viprank, g_viprank, sizeof(g_viprank));
	GetConVarString(configlib_schange, g_schange, sizeof(g_schange));
	GetConVarString(configlib_sinfo, g_sinfo, sizeof(g_sinfo));
	GetConVarString(configlib_tablename, g_tablename, sizeof(g_tablename));
	GetConVarString(configlib_adminflag, g_adminflag, sizeof(g_adminflag));
	
	Format(g_tablename, sizeof(g_tablename), "%s_%i", g_tablename, g_serverid);
	
	if (g_levels <= 0 && g_plevels <= 0) 
		SetFailState("[ STAMM ] Error!! Found no Stamm levels!!");
}