#if defined _stamm_clients_included
  #endinput
#endif
#define _stamm_clients_included






/**
 * Executes when a player becomes VIP
 *
 * @param client		Client.
 */
forward STAMM_OnClientBecomeVip(client);


/**
 * Executes when a player is fully initialized by Stamm after connecting
 *
 * @param client		Client.
 */
forward STAMM_OnClientReady(client);


/**
 * Executes when a player is saved
 *
 * @param client		Client.
 */
forward STAMM_OnSaveClient(client);


/**
 * Executes when a player switched your feature on/off or bought/sold it
 *
 * @param client		Client.
 * @param turnedOn		true = Switched on (bought), false = Switched off (sold).
 * @param isShop		true = Was called from shop, false = Was called from menu
 */
forward STAMM_OnClientChangedFeature(client, bool:turnedOn, bool:isShop);


/**
 * Executes when a player gets Stamm points
 *
 * @param client		Client.
 * @param points		The number of points, the player get.
 */
forward STAMM_OnClientGetPoints(client, points);


/**
 * Executes before a player get Stamm points
 *
 * @param client		Client.
 * @param points		The number of points the player get.
 * @return  			Plugin_Continue, Plugin_Changed to give points, anything else to prevent it.
 */
forward Action:STAMM_OnClientGetPoints_PRE(client, &points);








/**
 * Adds points to a player
 *
 * @param client		Client.
 * @param points		Number of points to add.
 * @return				true = Success, false = fail.
 * @error 				Client is invalid.
 */
native bool:STAMM_AddClientPoints(client, points);


/**
 * Deletes points from a player
 *
 * @param client		Client.
 * @param points		Number of points to delete.
 * @return				true = Success, false = Fail.
 * @error 				Client is invalid.
 */
native bool:STAMM_DelClientPoints(client, points);


/**
 * Sets points of a player
 *
 * @param client		Client.
 * @param points		Number of points to set.
 * @return				true = Success, false = Fail.
 * @error 				Client is invalid.
 */
native bool:STAMM_SetClientPoints(client, points);


/**
 * Returns the level of a client
 *
 * @param client		Client.
 * @return				0=no VIP, x=Level
 * @error 				Client is invalid.
 */
native STAMM_GetClientLevel(client);


/**
 * Returns the points of a player
 *
 * @param client		Client.
 * @return				Points of player.
 * @error 				Client is invalid.
 */
native STAMM_GetClientPoints(client);


/**
 * Returns true when the specific player is VIP, otherwise false
 *
 * @param client		Client.
 * @param type			x = Level.
 * @param min			true = Minimum rang, false = Exact Rang.
 * @return				true if Client is VIP, otherwise false.
 * @error 				Client is invalid.
 */
native bool:STAMM_IsClientVip(client, type, bool:min=true);


/**
 * Returns true when the clients level is high enough for your feature or he bought it and wants it.
 *
 * @param client		Client.
 * @return				true if client have feature, otherwise false.
 * @error 				Client, feature or block is invalid.
 */
native bool:STAMM_HaveClientFeature(client, block=1);


/**
 * Returns true when the specific player is completely loaded by Stamm, otherwise false
 *
 * @param client		Client.
 * @return				true if fully loaded, otherwise false.
 */
native bool:STAMM_IsClientValid(client);


/**
 * Returns true when the specific player is a Stamm admin, otherwise false
 *
 * @param client		Client.
 * @return				true if admin, otherwise false.
 */
native bool:STAMM_IsClientAdmin(client);


/**
 * Returns true when the specific player enabled this feature, false otherwise
 *
 * @param client		Client.
 * @return				true if the player enabled it, otherwise false.
 * @error 				Client or feature is invalid.
 */
native bool:STAMM_WantClientFeature(client);
