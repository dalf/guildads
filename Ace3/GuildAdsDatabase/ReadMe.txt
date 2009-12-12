GuildAdsDatabase by Galmok@Stormrage-EU (galmok@gmail.com)

This addon serves the purpose to backup the data of the players belonging to the 
currently configured GuildAds channel. This backup can be shared with other 
(new) players to let them be quickly updated with anything in the database (as 
updated as the player that made the backup).

To make a backup, type this:

/guildadsdb backup

To restore from a saved backup, type this:

/guildadsdb restore

To share your backup with someone else: 
1. Make a backup.
2. Browse to \World of Warcraft\WTF\Account\<Account name>\SavedVariables
3. Share the file called GuildAdsDatabase.lua with a new user of GuildAds.

To use a shared backup from someone else:
1. Copy the file to \World of Warcraft\Interface\Addons\GuildAdsDatabase\
2. Make sure you have GuildAds loaded and configured for the same channel and 
   am using the same version as the player that made the backup (normally this 
   is automatic)
3. Start the restore (see above).
5. Relog for free excess memory and to be sure everything is loaded properly.

During backup and restore you may experience a message saying to retry as 
GuildAds was busy. Just keep trying until it succeeds.
