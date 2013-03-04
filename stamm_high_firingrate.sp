#include <sourcemod>
#include <autoexecconfig>
#include <tf2items>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

new firerate;
new Handle:c_firerate;

public Plugin:myinfo =
{
	name = "Stamm Feature Higher Firing Rate",
	author = "Popoklopsi",
	version = "1.0",
	description = "Give VIP's higher firing Rate",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");

	if (STAMM_GetGame() != GameTF2) 
		SetFailState("Can't Load Feature, not Supported for your game!");
	
	STAMM_LoadTranslation();
	STAMM_AddFeature("VIP Higher Firing Rate", "");
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("higher_firingrate", "stamm/features");
	
	c_firerate = AutoExecConfig_CreateConVar("firing_rate", "10", "Firing rate increase in percent each block!");
	
	AutoExecConfig_AutoExecConfig();
	AutoExecConfig_CleanFile();
}

public OnConfigsExecuted()
{
	firerate = GetConVarInt(c_firerate);
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:haveDescription[64];
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.couch-fighter.de/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater"))
		Updater_AddPlugin(urlString);
		
	for (new i=1; i <= STAMM_GetBlockCount(); i++)
	{
		Format(haveDescription, sizeof(haveDescription), "%T", "GetHigherFiringRate", LANG_SERVER, firerate * i);
		
		STAMM_AddFeatureText(STAMM_GetLevel(i), haveDescription);
	}
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	new bool:change = false;
	
	if (STAMM_IsClientValid(client) && IsPlayerAlive(client))
	{
		for (new i=STAMM_GetBlockCount(); i > 0; i--)
		{
			if (STAMM_HaveClientFeature(client, i))
			{
				hItem = TF2Items_CreateItem(OVERRIDE_ALL);
				
				TF2Items_SetItemIndex(hItem, -1);

				new Float:newFire = 1.0 - float(firerate)/100.0 * i;

				if (newFire < 0.1)
					newFire = 0.1;
				
				TF2Items_SetAttribute(hItem, 0, 6, newFire);
					
				TF2Items_SetNumAttributes(hItem, 1);
				TF2Items_SetFlags(hItem, OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES);
				
				change = true;

				break;
			}
		}
	}
	
	if (change)
		return Plugin_Changed;
		
	return Plugin_Continue;
}