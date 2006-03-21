Envoyer la demande pour playerName, dataType
	Chacun fixe l opcode "RLR" (request last revision)
	Pas de fils -> envois au parent
	Un/des fils -> 
		Attente
		Les deux sont arrivés 
			- choisir le meilleur : revision puis poids
			- envois au parent
	Déco du perso -> reset
	Pas de parent : envois sur le canal demande de "UPD" (update) au meilleur
	Reception sur le channel
	
Une file d attente pour 
	- le traitement des commandes
	- l envois des messages
	
Probleme : 
	comment avoir la liste des onlines synchro
	
	
GuildAdsComm:SendUpdate


--[[
	Initialiaze
	OnChannelJoin
	OnChannelLeave
	OnConnection
	OnOnline
	OnItemInfoReady
	Register
	
	debug
	
	setConfigValue
	getConfigValue
	setProfileValue
	getProfileValue
	
	
]]