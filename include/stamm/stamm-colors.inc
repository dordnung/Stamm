#if defined _stamm_colors_included
	#endinput
#endif
#define _stamm_colors_included

#include <morecolors_stamm>
#include <colors>


/* Global var to check whether colors are fixed or not */
new bool:g_bStammColorsFixed = false;





/**
 * Writes a message to a client with the correct stock for the game.
 *
 * @param client        Client index.
 * @param message       Message (formatting rules).
 *
 * @noreturn
 * @error               If the client is not connected an error will be thrown.
 */
stock STAMM_PrintToChat(client, const String:message[], any:...)
{
	decl String:buffer[MAX_MESSAGE_LENGTH_MORE];

	VFormat(buffer, sizeof(buffer), message, 3);


	if (!g_bStammColorsFixed)
	{
		STAMM_FixColors();
	}


	if (STAMM_GetGame() == GameCSGO)
	{
		CPrintToChat(client, buffer);
	}
	else
	{
		MCPrintToChat(client, buffer);
	}
}



/**
 * Writes a message to all clients with the correct stock for the game.
 *
 * @param message       Message (formatting rules).
 *
 * @noreturn
 */
stock STAMM_PrintToChatAll(const String:message[], any:...)
{
	decl String:buffer[MAX_MESSAGE_LENGTH_MORE];

	VFormat(buffer, sizeof(buffer), message, 2);


	if (!g_bStammColorsFixed)
	{
		STAMM_FixColors();
	}


	if (STAMM_GetGame() == GameCSGO)
	{
		CPrintToChatAll(buffer);
	}
	else
	{
		MCPrintToChatAll(buffer);
	}
}



/**
 * Returns whether you can use morecolors or not,
 *
 * @return       True when morecolors allowed, otherwise false.
 */
stock bool:STAMM_IsMoreColorsAvailable()
{
	return STAMM_GetGame() != GameCSGO;
}



/**
 * Fixes missing Lightgreen color.
 *
 * @noreturn
 */
stock STAMM_FixColors()
{
	g_bStammColorsFixed = true;

	// Replace lightgreen if not exists
	if (!CColorAllowed(Color_Lightgreen))
	{
		if (CColorAllowed(Color_Lime))
		{
			CReplaceColor(Color_Lightgreen, Color_Lime);
		}
		else if (CColorAllowed(Color_Olive))
		{
			CReplaceColor(Color_Lightgreen, Color_Olive);
		}
	}
}