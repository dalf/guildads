if ( GetLocale() == "frFR" ) then

GUILDADS_TITLE					= "GuildAds";

-- Minimap button
GUILDADS_BUTTON_TIP				= "Les Annonces de la guilde";

GUILDADSTOOLTIPS_ADS 			=  "Vous permet de voir les annonces";

-- Config
GUILDADS_CHAT_OPTIONS			= "Options du canal GuildAds";
GUILDADS_CHAT_USETHIS			= "Utiliser ce canal :";
GUILDADS_CHAT_CHANNEL			= "Nom";
GUILDADS_CHAT_PASSWORD			= "Mot de passe";
GUILDADS_CHAT_COMMAND			= 'Commande "/"';
GUILDADS_CHAT_ALIAS				= "Alias";
GUILDADS_CHAT_SHOW_NEWEVENT		= "Afficher les nouveaux evenements"
GUILDADS_CHAT_SHOW_NEWASK		= "Afficher les nouvelles demandes";
GUILDADS_CHAT_SHOW_NEWHAVE		= "Afficher les nouvelles propositions";
GUILDADS_ADS_OPTIONS			= "Options des annonces";
GUILDADS_PUBLISH				= "Publier mes annonces";
GUILDADS_VIEWMYADS				= "Voir mes annonces";
GUILDADS_ICON_OPTIONS			= "Options de l\'ic\195\180ne de la Minimap";
GUILDADS_ICON					= "Ic\195\180ne de la Minimap";
GUILDADS_ADJUST_ANGLE			= "Adjuster l'angle";
GUILDADS_ADJUST_RADIUS			= "Adjuster le rayon";

GUILDADS_AUTOCHANNELCONFIG		= "Configuration de canal automatique";
GUILDADS_MANUALCHANNELCONFIG	= "Configuration du canal manuelle";

GUILDADS_ERROR_TOOMANYCHANNELS		= "Vous avez d\195\169j\195\160 rejoint le nombre maximum de canaux (10)"; 
GUILDADS_ERROR_JOINCHANNELFAILED 	= "N'a pas joint le canal pour une raison inconnue";
GUILDADS_ERROR_WRONGPASSWORD 		= "Le mot de passe est incorrect";

-- Main frame
GUILDADS_MYADS				= "Mes Annonces";
GUILDADS_BUTTON_INVITE		= "Invite Groupe";
GUILDADS_BUTTON_ADDREQUEST	= "Demander";
GUILDADS_BUTTON_ADDAVAILABLE	= "Proposer";
GUILDADS_QUANTITY			= "Quantité";
GUILDADS_SINCE				= "Depuis %s";
GUILDADS_SIMPLE_SINCE		= "Depuis";
GUILDADS_GROUPBYACCOUNT		= "Regrouper par compte";

GUILDADS_TRADE_PROVIDER		= "Par";
GUILDADS_TRADE_NUMBER		= "Nb";
GUILDADS_TRADE_OBJECT		= "Objet";
GUILDADS_TRADE_ACTIVE		= "Active";
GUILDADS_TRADE_TYPE			= "Type";
GUILDADS_TRADE_SHIFTCLICKHELP= "Pour placer un objet içi, utiliser shift-click lorsque cette fenêtre est ouverte";

-- Column headers
GUILDADS_HEADER_REQUEST		= "Demande";
GUILDADS_HEADER_AVAILABLE	= "Propose";
-- GUILDADS_HEADER_INVENTORY : done by WOW
-- GUILDADS_HEADER_SKILL : done by WOW
-- GUILDADS_HEADER_ANNONCE : done by WOW
GUILDADS_HEADER_FACTION		= "Réputation";
GUILDADS_HEADER_EVENT		= "Evénements";

GUILDADS_GUILD_GROUPWITHACCOUNT	= "Associer %s avec le compte de %s";
GUILDADS_GUILD_DEGROUP			= "Dissocier du compte";
GUILDADS_GUILD_BLACKLIST		= "Interdire";

-- Equipment
GUILDADS_EQUIPMENT		= "Equipement";

-- Tooltip requests
GUILDADS_ASKTOOLTIP		= "%s demande(s)";
				
-- Item
-- arme, armure, conteneur, artisanat, projectile, carquois, recette, composant, divers
GUILDADS_ITEMS = {
	everything = "Tout",
	everythingelse = "Tout le reste",
	monster	= "Obtenu sur des monstres",
	classReagent = "Utilisé par une classe",
	tradeReagent = "Utilisé pour les professions",
	vendor = "Vendeur",
	trade = "Produit par les professions",
	gather = "Recolte",
};
				
GUILDADS_ITEMS_SIMPLE = {
	everything = "Tout"
};
				
-- Tradeskills
GUILDADS_TS_ASKITEMS		= "Demander les composants pour %i %s";
GUILDADS_TS_ASKITEMS_TT		= "Modifiez le nombre d'objets à créer pour préciser les quantités.";

-- Bindings
-- BINDING_HEADER_GUILDADS
BINDING_NAME_SHOW		= "Afficher GuildAds";
BINDING_NAME_SHOW_CONFIG	= "Afficher les préférences";

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
	[9] = "Prêtre"
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

GUILDADS_FACTION_OPTIONS		= "Paramètres Faction";
GUILDADS_FACTION_HIDE_COLLAPSED = "Cacher les factions réduites";
GUILDADS_FACTION_ONLY_LEVEL_70	= "Cacher les niveaux < 70";
GUILDADS_FACTION_FACTION		= "Afficher Factions"; -- Should be updated runtime to either Horde or Alliance

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
}; -- last one used is 55

GUILDADS_FACTION_SHOWFACTION = "Faction";
GUILDADS_FACTION_SHOWFACTIONFORCES = "Force de la faction";
GUILDADS_FACTION_SHOWOUTLAND = "Outreterre";
GUILDADS_FACTION_SHOWSHATTRATHCITY = "Shattrath";
GUILDADS_FACTION_SHOWSTEAMWHEEDLECARTEL = "Cartel Gentepression";
GUILDADS_FACTION_SHOWOTHER = "Autres";


end
