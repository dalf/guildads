if ( GetLocale() == "frFR" ) then

GUILDADS_TITLE					= "GuildAds";

-- Minimap button
GUILDADS_BUTTON_TIP				= "Afficher/Cacher GuildAds";
GUILDADS_UPGRADE_TIP		= "Nouvelle version de GuildAds: ";
GUILDADS_UPGRADE_TIP		= "Une nouvelle version de GuildAds est disponible: ";
GUILDADS_STATUS_TIP		= "Recherches en cours:";

-- Options frame
GUILDADS_OPTIONS_TITLE		= "Options du canal GuildAds";
GUILDADS_CHAT_OPTIONS		= "Options du Chat";
GUILDADS_CHAT_USETHIS		= "Utiliser ce canal :";
GUILDADS_CHAT_CHANNEL		= "Nom";
GUILDADS_CHAT_PASSWORD		= "Mot de passe";
GUILDADS_CHAT_COMMAND		= "Commande '/'";
GUILDADS_CHAT_ALIAS 		= "Alias du canal";
GUILDADS_CHAT_SHOW_NEWEVENT	= "Afficher les nouveaux Evenements"
GUILDADS_CHAT_SHOW_NEWASK	= "Afficher les nouvelles Demandes";
GUILDADS_CHAT_SHOW_NEWHAVE	= "Afficher les nouvelles Offres";
GUILDADS_ADS_OPTIONS		= "Options des Annonces";
GUILDADS_PUBLISH		= "Publier mes Annonces";
GUILDADS_VIEWMYADS		= "Afficher mes Annonces";
GUILDADS_ICON_OPTIONS		= "Option du bouton Minimap";
GUILDADS_ICON			= "Bouton Minimap";
GUILDADS_ADJUST_ANGLE		= "Regler l'angle";
GUILDADS_ADJUST_RADIUS		= "Regler le radius";

GUILDADS_AUTOCHANNELCONFIG	= "Configuration automatique des canaux";
GUILDADS_MANUALCHANNELCONFIG	= "Configuration manuelle des canaux";

GUILDADS_ERROR_NOTINITIALIZED 	= "GuildAds n'est pas lance."

GUILDADS_ERROR_TOOMANYCHANNELS	= "Vous avez atteint le nombre maximum de canaux"; 
GUILDADS_ERROR_JOINCHANNELFAILED = "Erreur inconnue de connexion au canal";
GUILDADS_ERROR_WRONGPASSWORD 	= "Erreur de mot de passe";

GUILDADS_NEWDATATYPEVERSION	= "Type de données \"%s\" : %s a une nouvelle version %s. Mettez à jour votre version pour updater les données.";



-- Main frame
GUILDADS_MYADS				= "Mes Annonces";
GUILDADS_BUTTON_INVITE		= "Invite Groupe";
GUILDADS_BUTTON_ADDREQUEST	= "Demander";
GUILDADS_BUTTON_ADDAVAILABLE	= "Proposer";
GUILDADS_BUTTON_REMOVE		= REMOVE;
GUILDADS_QUANTITY			= "Quantité";
GUILDADS_SINCE				= "Depuis %s";
GUILDADS_SIMPLE_SINCE		= "Depuis";
GUILDADS_GROUPBYACCOUNT		= "Regrouper par compte";

GUILDADS_TRADE_PROVIDER		= "Par";
GUILDADS_TRADE_NUMBER		= "Nb";
GUILDADS_TRADE_OBJECT		= "Objet";
GUILDADS_TRADE_ACTIVE		= "Active";
GUILDADS_TRADE_TYPE			= "Type";
GUILDADS_TRADE_SHIFTCLICKHELP= "Pour placer un objet içi, click gauche sur un objet lorsque cette fenêtre est ouverte";
GUILDADS_TRADE_MINLEVEL		= "Level Min";

-- Column headers
GUILDADS_HEADER_REQUEST		= "Demande";
GUILDADS_HEADER_AVAILABLE	= "Propose";
-- GUILDADS_HEADER_INVENTORY : done by WOW
-- GUILDADS_HEADER_SKILL : done by WOW
-- GUILDADS_HEADER_ANNONCE : done by WOW
GUILDADS_HEADER_FACTION		= "Réputation";
GUILDADS_HEADER_EVENT		= "Evénements";
GUILDADS_HEADER_FORUM		= "Forum";

GUILDADS_GUILD_GROUPWITHACCOUNT	= "Associer %s avec le compte de %s";
GUILDADS_GUILD_DEGROUP			= "Dissocier du compte";
GUILDADS_GUILD_BLACKLIST		= "Bannir";

GUILDADS_FORUM_SUBJECT		= MAIL_SUBJECT_LABEL; --"Sujet:"
GUILDADS_FORUM_AUTHOR		= "Auteur";
GUILDADS_FORUM_DATE		= "Date";
GUILDADS_FORUM_NEWPOST		= "Nouveau";
GUILDADS_FORUM_EDITPOST		= "Editer";
GUILDADS_FORUM_REPLY		= REPLY_MESSAGE; --"Repondre"
GUILDADS_FORUM_STICKY		= "Post It";
GUILDADS_FORUM_LOCKED		= "Verrouille";
GUILDADS_FORUM_OFFICERPOST	= "Post d'Officier";
GUILDADS_FORUM_POST		= "Post";
GUILDADS_FORUM_EMPTYSUBJECT	= "<sans titre>";
GUILDADS_FORUM_DELETEPOST	= "Supprimer le post";



				
-- Item
-- arme, armure, conteneur, artisanat, projectile, carquois, recette, composant, divers
GUILDADS_ITEMS = {
	everything = "Tout",
	everythingelse = "Tout le reste",
	monster	= "Loot de mobs",
	classReagent = "Items pour les Classes",
	tradeReagent = "Items pour les Professions",
	vendor = "Vendeur",
	trade = "Produit par les Professions",
	gather = "Recolte",
};
				
GUILDADS_ITEMS_SIMPLE = {
	everything = "Tout"
};

-- Equipment
GUILDADS_EQUIPMENT		= "Equipement";


-- Tooltip requests
GUILDADS_ASKTOOLTIP		= "%s demande(s)";
				
-- Tradeskills
GUILDADS_TS_ASKITEMS		= "Demander les composants pour %i %s";
GUILDADS_TS_ASKITEMS_TT		= "Modifiez le nombre d'objets à créer pour indiquer les quantités.";

-- Bindings
BINDING_NAME_SHOW		= "Afficher GuildAds";
BINDING_NAME_SHOW_CONFIG	= "Afficher les préférences de GuildAds";

-- Race
GUILDADS_RACES = {
	[1] = "Humain",
	[2] = "Nain",
	[3] = "Elfe de la nuit",
	[4] = "Gnome",
	[5] = "Orc",
	[6] = "Mort-vivant",
	[7] = "Tauren",
	[8] = "Troll",
	[9] = "Draeneï",
	[10] = "Elfe de sang"
};
				
GUILDADS_CLASSES = {
	[1] = "Guerrier",
	[2] = "Chaman",
	[3] = "Paladin",
	[4] = "Druide",
	[5] = "Voleur",
	[6] = "Chasseur",
	[7] = "Démoniste",
	[8] = "Mage",
	[9] = "Prêtre",
	[10] = "Chevalier de la Mort"
};

-- Skill
GUILDADS_SKILLS = {
	[1]  = "Herboristerie",
	[2]  = "Minage",
	[3]  = "Dépeçage",
	[4]  = "Alchimie",
	[5]  = "Forge",
	[6]  = "Ingénierie",
	[7]  = "Travail du cuir",
	[8]  = "Couture",
	[9]  = "Enchantement",
	[10] = "Pêche",
	[11] = "Secourisme",
	[12] = "Cuisine",
	[13] = "Crochetage",
	[14] = "Joaillerie",
	[15] = "Calligraphie",

	[20] = "Armes de pugilat",
	[21] = "Dagues",
	[22] = "Epées",
	[23] = "Epées à deux mains",
	[24] = "Masse",
	[25] = "Masses à deux mains",
	[26] = "Haches",
	[27] = "Haches à deux mains",
	[28] = "Armes d'hast",
	[29] = "Bâtons",
	[30] = "Armes de jet",
	[31] = "Armes à feu",
	[32] = "Arcs",
	[33] = "Arbalètes",
	[34] = "Baguettes"
};



GUILDADSTOOLTIPS_ADS 			=  "Afficher les annonces en cours des membres";

GUILDADSTOOLTIPS_FACTION = "Afficher la Réputation des membres";

GUILDADSTOOLTIPS_SKILL =  "Afficher les Compétences et les Métiers des membres";

GUILDADSTOOLTIPS_GUILD = "Afficher la liste des membres";

GUILDADSTOOLTIPS_FORUM = "Afficher le forum in-game";



--Factions (only factions mentioned here can be synchronized)
-- Taken from http://www.wowwiki.com/Reputation#Reputation_sheet
-- Pour la traduction en francais : http://www.wowhead.com/?factions

GUILDADS_FACTIONS = {
	[1]  = "Darnassus";  -- Alliance
	[2]  = "Exodar";
	[3]  = "Exil\195\169s de Gnomeregan";
	[4]  = "Forgefer";
	[5]  = "Hurlevent";
	[6]  = "Sentinelles d'Aile-argent";
	[7]  = "Garde Foudrepique";
	[8]  = "La Ligue d'Arathor";
	[9]  = "Trolls Sombrelance"; -- Horde
	[10] = "Orgrimmar";
	[11] = "Lune-d'argent";
	[12] = "Les Pitons du Tonnerre";
	[13] = "Fossoyeuse";
	[14] = "Clan Loup-de-givre";
	[15] = "Les Profanateurs";
	[16] = "Voltigeurs Chanteguerre";
	[17] = "Bastion de l'Honneur"; -- Outland
	[18] = "Thrallmar";
	[19] = "Kurenaï";
	[20] = "Mag'har";
	[21] = "Exp\195\169dition c\195\169narienne";
	[22] = "Sporeggar";
	[23] = "Le Consortium";
	[24] = "Aile-du-Néant";
	[25] = "Ogri'la";
	[26] = "Ligemort cendrelangue";
	[27] = "Ville basse"; -- Shattrath City
	[28] = "Garde-ciel sha'tari";
	[29] = "L'Aldor";
	[30] = "Les Clairvoyants";
	[31] = "Les Sha'tar";
	[55] = "Op\195\169ration Soleil bris\195\169";
	[32] = "Baie-du-Butin"; -- Cartel Gentepression
	[33] = "Long-guet";
	[34] = "Gadgetzan";
	[35] = "Cabestan";
	[36] = "Aube d'argent"; -- Autres
	[37] = "La Voile sanglante";
	[38] = "Prog\195\169niture de Nozdormu";
	[39] = "Cercle c\195\169narien";
	[40] = "Foire de Sombrelune";
	[41] = "Centaures (Gelkis)";
	[42] = "Les Hydraxiens";
	[43] = "Centaures (Magram)";
	[44] = "Ravenholdt";
	[45] = "Shen'dralar";
	[46] = "Syndicat";
	[47] = "Confr\195\169rie du thorium";
	[48] = "Les Grumegueules";
	[49] = "Éleveurs de sabres-d'hiver";
	[50] = "Tribu Zandalar";
	[51] = "Gardiens du Temps"; -- Other - BC
	[52] = "La Balance des sables";
	[53] = "Tranquillien";
	[54] = "L'\197\146il pourpre";
	[56] = "Les Chevaliers de l'Epée de Ebano", -- WotLK -- Other
	[57] = "La Croisade d'Argent", -- Northrend
	[58] = "La Ligue des Explorateurs",
	[59] = "La Tribu Frénécoeur",
	[60] = "Les Givre-nés",
	[61] = "La Main de la Vengeance",
	[62] = "Les Kalu'aks",
	[63] = "Les Oracles",
	[64] = "Les Fils de Hodir",
	[65] = "Les Taunkas",
	[66] = "Expédition de la Vaillance",
	[67] = "Offensive Chant-de-guerre",
	[68] = "L'Accord de Wyrm",
	[69] = "Le Kirin Tor", -- Dalaran
	[70] = "Le Concordat argenté",
	[71] = "Les Saccage-soleil"
}; -- The last one used is 71

GUILDADS_FACTION_OPTIONS		= "Paramètres des Factions";
GUILDADS_FACTION_HIDE_COLLAPSED = "Cacher les factions desactivées";
GUILDADS_FACTION_ONLY_LEVEL_70	= "Cacher les niveaux < 70";
GUILDADS_FACTION_ONLY_LEVEL_80	= "Cacher les niveaux < 80";
GUILDADS_FACTION_FACTION		= "Afficher Factions"; -- Should be updated runtime to either Horde or Alliance

GUILDADS_FACTION_SHOWFACTION = "Afficher Factions";
GUILDADS_FACTION_SHOWFACTIONFORCES = "Afficher Forces de la faction";
GUILDADS_FACTION_SHOWOUTLAND = "Afficher Outreterre";
GUILDADS_FACTION_SHOWSHATTRATHCITY = "Afficher Shattrath";
GUILDADS_FACTION_SHOWSTEAMWHEEDLECARTEL = "Afficher Cartel Gentepression";
GUILDADS_FACTION_SHOWOTHER = "Afficher Autres";
GUILDADS_FACTION_SHOWNORTHREND = "Afficher Northrend";
GUILDADS_FACTION_SHOWDALARAN = "Afficher Dalaran";
GUILDADS_FACTION_SHOWRAID = "Afficher Raid"

GUILDADS_OPTIONS = {
	["toggle"]			= BINDING_NAME_SHOW;
	["options"]			= BINDING_NAME_SHOW_CONFIG;
	["debug"] 			= "Activer/Desactiver les message de debug";
	["info"] 			= "Afficher les informations générales de debug";
	["reset"]			= "Reinitialiser toute la database!";
	["reset all"]		= "Reinitialiser toute la database excepté les informations du compte";
	["reset channel"]	= "Reinitialiser toutes les informations sur les canaux";
	["reset others"]	= "Reinitialiser toutes les informations sur les autres joueurs";
	["reset player"]	= "Reinitialiser les informations d'un joueur particulier";
	["clean"]			= "Nettoyer la database";
	["clean other"]		= "Supprimer les informations Métiers issus des autres comptes qui n'ont pas de lien vers une recette";
	["admin"]			= "Gérer le controle d'accès des joueurs et des guildes";
	["admin show"]		= "Afficher la liste des controles d'accès en cours";
	["admin deny"]		= "Interdire l'accès à un joueur ou à une guilde (les informations du joueur/guilde seront effacés)";
	["admin allow"]		= "Autoriser l'accès à un joueur ou à une guilde";
	["admin remove"]	= "Supprimer un joueur ou une guilde de la liste des controles d'accès";
	["admin allowed"]	= "Vérifier le controle d'accès d'un joueur";
}
end
