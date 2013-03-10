#include <sourcemod>
#include <sdktools>
#include <colors>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

#define MODELPATH 0
#define MODELNAME 1
#define MODELTEAM 2
#define MODELLEVEL 3

new PlayerHasModel[MAXPLAYERS + 1];
new LastTeam[MAXPLAYERS + 1];
new modelCount;
new model_change;
new same_models;
new admin_model;
new lowest;

new String:PlayerModel[MAXPLAYERS + 1][PLATFORM_MAX_PATH + 1];

new String:models[64][4][PLATFORM_MAX_PATH + 1];

new String:model_change_cmd[32];

new Handle:c_model_change_cmd;
new Handle:c_model_change;
new Handle:c_same_models;
new Handle:c_admin_model;

new bool:Loaded;

public Plugin:myinfo =
{
	name = "Stamm Feature Vip Models",
	author = "Popoklopsi",
	version = "1.2.1",
	description = "Give VIP's VIP Models",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");

	if (!CColorAllowed(Color_Lightgreen))
	{
		if (CColorAllowed(Color_Lime))
			CReplaceColor(Color_Lightgreen, Color_Lime);
		else if (CColorAllowed(Color_Olive))
			CReplaceColor(Color_Lightgreen, Color_Olive);
	}
		
	STAMM_LoadTranslation();

	STAMM_AddFeature("VIP Models", "");
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:description[64];
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
	
	if (model_change && same_models)
		Format(description, sizeof(description), "%T", "GetModelChange", LANG_SERVER, model_change_cmd);
	else 
		Format(description, sizeof(description), "%T", "GetModel", LANG_SERVER);

	if (!FileExists("cfg/stamm/features/ModelSettings.txt"))
		SetFailState("Couldn't load Stamm Models. ModelSettings.txt missing.");
	
	new Handle:model_settings = CreateKeyValues("ModelSettings");

	lowest = STAMM_GetLevelCount();

	FileToKeyValues(model_settings, "cfg/stamm/features/ModelSettings.txt");

	if (KvGotoFirstSubKey(model_settings))
	{
		do
		{
			KvGetString(model_settings, "team", models[modelCount][MODELTEAM], sizeof(models[][]));
			KvGetString(model_settings, "model", models[modelCount][MODELPATH], sizeof(models[][]));

			if (!StrEqual(models[modelCount][MODELPATH], "") && !StrEqual(models[modelCount][MODELPATH], "0"))
				PrecacheModel(models[modelCount][MODELPATH], true);

			KvGetString(model_settings, "name", models[modelCount][MODELNAME], sizeof(models[][]));
			KvGetString(model_settings, "level", models[modelCount][MODELLEVEL], sizeof(models[][]), "none");

			if (StrEqual(models[modelCount][MODELLEVEL], "none"))
			{
				STAMM_WriteToLog(false, "ATTENTION: Level Config is now in ModelSettings.txt under the key \"level\"!");

				if (STAMM_GetLevel() == 0)
					STAMM_WriteToLog(false, "ATTENTION: Found no level for model %s. Zero assumed!!", models[modelCount][MODELNAME]);

				Format(models[modelCount][MODELLEVEL], sizeof(models[][]), "%i", STAMM_GetLevel());

				if (STAMM_GetLevel() < lowest)
					lowest = STAMM_GetLevel();
			}
			else
			{
				new levelNumber = STAMM_GetLevelNumber(models[modelCount][MODELLEVEL]);

				if (levelNumber != 0)
					Format(models[modelCount][MODELLEVEL], sizeof(models[][]), "%i", levelNumber);
				else if (StringToInt(models[modelCount][MODELLEVEL]) == 0)
				{
					STAMM_WriteToLog(false, "ATTENTION: Found incorrect level for model %s. One assumed!!", models[modelCount][MODELNAME]);
					Format(models[modelCount][MODELLEVEL], sizeof(models[][]), "1");
				}

				if (StringToInt(models[modelCount][MODELLEVEL]) < lowest)
					lowest = StringToInt(models[modelCount][MODELLEVEL]);
			}

			modelCount++;
		}
		while (KvGotoNextKey(model_settings));
	}
	
	CloseHandle(model_settings);
	
	STAMM_AddFeatureText(lowest, description);
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("vip_models", "stamm/features");

	c_model_change = AutoExecConfig_CreateConVar("model_change", "1", "0 = Players can only change models, when changing team, 1 = Players can always change it");
	c_admin_model = AutoExecConfig_CreateConVar("model_admin_model", "1", "Should Admins also get a VIP Skin 1 = Yes, 0 = No");
	c_model_change_cmd = AutoExecConfig_CreateConVar("model_change_cmd", "sm_smodel", "Command to change model");
	c_same_models = AutoExecConfig_CreateConVar("model_models", "0", "1 = VIP's can choose the model, 0 = Random Skin every Round");

	AutoExecConfig(true, "vip_models", "stamm/features");
	AutoExecConfig_CleanFile();
	
	HookEvent("player_team", eventPlayerTeam);
	HookEvent("player_spawn", eventPlayerSpawn);
	
	ModelDownloads();
	
	Loaded = false;
}

public OnConfigsExecuted()
{
	model_change = GetConVarInt(c_model_change);
	same_models = GetConVarInt(c_same_models);
	admin_model = GetConVarInt(c_admin_model);
	
	GetConVarString(c_model_change_cmd, model_change_cmd, sizeof(model_change_cmd));

	if (!Loaded)
	{
		RegConsoleCmd(model_change_cmd, CmdModel);

		Loaded = true;
	}

	if (!StrContains(model_change_cmd, "sm_") || StrContains(model_change_cmd, "!") != 0)
	{
		ReplaceString(model_change_cmd, sizeof(model_change_cmd), "sm_", "");
		Format(model_change_cmd, sizeof(model_change_cmd), "!%s", model_change_cmd);
	}
}

public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (STAMM_IsClientValid(client))
	{
		if (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)
		{
			if (LastTeam[client] != GetClientTeam(client))
			{
				PlayerHasModel[client] = 0;
				
				Format(PlayerModel[client], sizeof(PlayerModel[]), "");
			}
			
			LastTeam[client] = GetClientTeam(client);

			if (STAMM_WantClientFeature(client))
			{
				if (same_models) 
					PrepareSameModels(client);
				else 
					PrepareRandomModels(client);
			}
		}
	}
}

public Action:eventPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (STAMM_IsClientValid(client))
	{
		PlayerHasModel[client] = 0;
		
		Format(PlayerModel[client], sizeof(PlayerModel[]), "");
	}
}

public ModelDownloads()
{
	if (!FileExists("cfg/stamm/features/ModelDownloads.txt"))
	{
		STAMM_WriteToLog(false, "Couldn't find ModelDownloads.txt");

		return;
	}

	new Handle:downloadfile = OpenFile("cfg/stamm/features/ModelDownloads.txt", "rb");
	
	if (downloadfile != INVALID_HANDLE)
	{
		while (!IsEndOfFile(downloadfile))
		{
			decl String:filecontent[PLATFORM_MAX_PATH + 10];
			
			ReadFileLine(downloadfile, filecontent, sizeof(filecontent));
			ReplaceString(filecontent, sizeof(filecontent), " ", "");
			ReplaceString(filecontent, sizeof(filecontent), "\n", "");
			ReplaceString(filecontent, sizeof(filecontent), "\t", "");
			ReplaceString(filecontent, sizeof(filecontent), "\r", "");
			
			if (!StrEqual(filecontent, "")) 
				AddFileToDownloadsTable(filecontent);
		}

		CloseHandle(downloadfile);
	}
}

public Action:CmdModel(client, args)
{
	if (STAMM_IsClientValid(client))
	{
		if (model_change && PlayerHasModel[client])
		{
			PlayerHasModel[client] = 0;
			
			Format(PlayerModel[client], sizeof(PlayerModel[]), "");
			
			CPrintToChat(client, "{lightgreen}[ {green}Stamm {lightgreen}] %t", "NewModel", client);
		}
	}
	
	return Plugin_Handled;
}

public ModelMenuCall(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (STAMM_IsClientValid(param1))
		{
			decl String:ModelChoose[128];
			
			GetMenuItem(menu, param2, ModelChoose, sizeof(ModelChoose));
			
			if (!StrEqual(ModelChoose, "standard"))
			{
				SetEntityModel(param1, ModelChoose);
				
				PlayerHasModel[param1] = 1;
				
				Format(PlayerModel[param1], sizeof(PlayerModel[]), ModelChoose);
			}
			if (StrEqual(ModelChoose, "standard")) 
			{
				PlayerHasModel[param1] = 1;
				
				Format(PlayerModel[param1], sizeof(PlayerModel[]), "");
			}
		}
	}
	else if (action == MenuAction_End) 
		CloseHandle(menu);
}


public PrepareSameModels(client)
{
	if (!PlayerHasModel[client] && (((!admin_model && !STAMM_IsClientAdmin(client)) || admin_model)))
	{ 
		decl String:ModelChooseLang[256];
		decl String:StandardModel[256];

		new bool:found = false;
		
		Format(ModelChooseLang, sizeof(ModelChooseLang), "%T", "ChooseModel", client);
		Format(StandardModel, sizeof(StandardModel), "%T", "StandardModel", client);
		
		new Handle:ModelMenu = CreateMenu(ModelMenuCall);
		
		SetMenuTitle(ModelMenu, ModelChooseLang);
		SetMenuExitButton(ModelMenu, false);

		for (new item = 0; item < modelCount; item++)
		{
			if (GetClientTeam(client) == StringToInt(models[item][MODELTEAM]) && STAMM_IsClientVip(client, StringToInt(models[item][MODELLEVEL])))
			{
				if (!StrEqual(models[item][MODELPATH], "") && !StrEqual(models[item][MODELPATH], "0"))
				{
					AddMenuItem(ModelMenu, models[item][MODELPATH], models[item][MODELNAME]);

					found = true;
				}
			}
		}
		
		AddMenuItem(ModelMenu, "standard", StandardModel);
		
		if (found)
			DisplayMenu(ModelMenu, client, MENU_TIME_FOREVER);
	}
	else if (PlayerHasModel[client] && !StrEqual(PlayerModel[client], ""))
		SetEntityModel(client, PlayerModel[client]);
}

public PrepareRandomModels(client)
{
	new randomValue;
	new found = 0;
	new modelsFound[64];

	for (new item = 0; item < modelCount; item++)
	{
		if (StringToInt(models[item][MODELTEAM]) == GetClientTeam(client) && STAMM_IsClientVip(client, StringToInt(models[item][MODELLEVEL])))
		{
			modelsFound[found] = item;
			found++;
		}
	}

	if (found > 0)
	{
		randomValue = GetRandomInt(1, found);
		
		if ((!admin_model && !STAMM_IsClientAdmin(client)) || admin_model)
		{
			if (!StrEqual(models[randomValue-1][MODELPATH], "") && !StrEqual(models[randomValue-1][MODELPATH], "0"))
				SetEntityModel(client, models[randomValue-1][MODELPATH]);
		}
	}
}