#if defined _stamm_blocks_included
	#endinput
#endif
#define _stamm_blocks_included






/**
 * Adds information about what a player get on a specific block with this feature.
 *
 * @param level         The block.
 * @param description   Description for this block.
 * @param ...           Format arguments.
 * @return              true = success, false = error.
 * @error               Block or feature is invalid.
 */
native bool:STAMM_AddBlockDescription(block, const String:description[], any:...);


/**
 * Returns the level a block needs (TODO: No Buying).
 *
 * @param block         Block to search for.
 * @return              The level to get that block. TODO: -1 if block is for buying.
 * @error               Block or feature is invalid TODO: it's a shop feature.
 */
native STAMM_GetLevel(block=1);


/**
 * TODO: 
 * Returns the points needed to buy that block (Buying).
 *
 * @param block         Block to search for.
 * @return              Points to buy that block. -1 if level needed.
 * @error               Block or feature is invalid or it's a level feature.
 
native STAMM_GetPoints(block=1); */


/**
 * TODO: 
 * Returns whether the block is for buying or not.
 *
 * @param block         Block to check.
 * @return              true when the block needs to be bought, otherwise false.
 * @error               Block or feature is invalid.
 
native bool:STAMM_IsShop(block=1); */


/**
 * Returns the number of a block by name.
 *
 * @param name          The name.
 * @return              The block number.
 * @error               Feature is invalid.
 */
native STAMM_GetBlockOfName(const String:name[]);


/**
 * Returns the number of blocks found in LevelSettings.
 *
 * @return              Number of blocks.
 * @error               Feature is invalid.
 */
native STAMM_GetBlockCount();


/**
 * Returns the highest block a client is in.
 *
 * @param client        Client.
 * @return              0 = no block, x = block.
 * @error               Client or feature is invalid.
 */
native STAMM_GetClientBlock(client);