#include <sourcemod>
#include <sdktools>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new Handle:colors_c;
new Handle:mode_smoke_c;

new mode_smoke;
new String:colors[64];

public Plugin:myinfo =
{
	name = "Stamm Feature Colored Smokes",
	author = "Popoklopsi",
	version = "1.2",
	description = "Give VIP's colored smokes",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	decl String:description[64];
	
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	if (STAMM_GetGame() != GameCSS) 
		SetFailState("Can't Load Feature, not Supported for your game!");

	STAMM_LoadTranslation();
		
	Format(description, sizeof(description), "%T", "GetColoredSmokes", LANG_SERVER);
	
	STAMM_AddFeature("VIP Colored Smokes", description);
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("stamm/features/colored_smokes");

	mode_smoke_c = AutoExecConfig_CreateConVar("smoke_mode", "0", "The Mode: 0=Team Colors, 1=Random, 2=Party, 3=Custom");
	colors_c = AutoExecConfig_CreateConVar("smoke_color", "255 255 255", "When mode = 3: RGB colors of the smoke");
	
	AutoExecConfig(true, "colored_smokes", "stamm/features");
	AutoExecConfig_CleanFile();
	
	HookEvent("smokegrenade_detonate", eventHeDetonate);
}

public OnConfigsExecuted()
{
	mode_smoke = GetConVarInt(mode_smoke_c);
	
	GetConVarString(colors_c, colors, sizeof(colors));
}

public Action:eventHeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (STAMM_IsClientValid(client))
	{
		if (STAMM_HaveClientFeature(client))
		{
			new Float:origin[3];
			decl String:sBuffer[64];
			
			origin[0] = GetEventFloat(event, "x");
			origin[1] = GetEventFloat(event, "y");
			origin[2] = GetEventFloat(event, "z");
			
			new ent_light = CreateEntityByName("light_dynamic");
			
			if (ent_light != -1)
			{
				switch (mode_smoke)
				{
					case 0:
					{
						new team = GetClientTeam(client);
						
						if (team == 2) 
							DispatchKeyValue(ent_light, "_light", "255 0 0");
						else if (team == 3) 
							DispatchKeyValue(ent_light, "_light", "0 0 255");
					}
					case 1:
					{
						new color_r = GetRandomInt(0, 255);
						new color_g = GetRandomInt(0, 255);
						new color_b = GetRandomInt(0, 255);
						
						Format(sBuffer, sizeof(sBuffer), "%i %i %i", color_r, color_g, color_b);
						DispatchKeyValue(ent_light, "_light", sBuffer);
					}			
					case 2:
					{
						CreateTimer(0.2, PartyLight, ent_light, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}
					case 3:
					{
						DispatchKeyValue(ent_light, "_light", sBuffer);
					}
				}	
				
				DispatchKeyValue(ent_light, "pitch", "-90");
				DispatchKeyValue(ent_light, "distance", "256");
				DispatchKeyValue(ent_light, "spotlight_radius", "96");
				DispatchKeyValue(ent_light, "brightness", "3");
				DispatchKeyValue(ent_light, "style", "6");
				DispatchKeyValue(ent_light, "spawnflags", "1");
				DispatchSpawn(ent_light);
				
				AcceptEntityInput(ent_light, "DisableShadow");
				AcceptEntityInput(ent_light, "TurnOn");
				
				TeleportEntity(ent_light, origin, NULL_VECTOR, NULL_VECTOR);
				
				CreateTimer(20.0, delete, ent_light, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action:PartyLight(Handle:timer, any:light)
{
	if (!IsValidEntity(light)) 
		return Plugin_Stop;
	
	decl String:sBuffer[64];
				
	new color_r = GetRandomInt(0, 255);
	new color_g = GetRandomInt(0, 255);
	new color_b = GetRandomInt(0, 255);
	
	Format(sBuffer, sizeof(sBuffer), "%i %i %i 200", color_r, color_g, color_b);
	DispatchKeyValue(light, "_light", sBuffer);
	
	return Plugin_Continue;
}

public Action:delete(Handle:timer, any:light)
{
	if (IsValidEntity(light))
	{
		decl String:class[128];
		
		GetEdictClassname(light, class, sizeof(class));
		
		if (StrEqual(class, "light_dynamic")) 
			RemoveEdict(light);
	}
} 