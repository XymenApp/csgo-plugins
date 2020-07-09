#include <sourcemod>
#define AUTHOR "-=XymenGaming=-"
#define MAX_CONFIG_COUNT 1000
#define PLUGIN_VERSION "1.3"
#define CONFIG_FILE_PATH "configs/xyg_ce.cfg"

int configCount;
char g_sConfigString[MAX_CONFIG_COUNT + 1][1024], g_sConfigFile[MAX_CONFIG_COUNT + 1][1024];

ConVar g_HostnameCvar;

public Plugin myinfo = 
{
	name = "[SM] Config Executor",
	author = AUTHOR,
	description = "Config Executer for CSGO Servers",
	version = PLUGIN_VERSION,
	url = "https://github.com/XymenApp/csgo-plugin-config-executor/"
}

public OnPluginStart()
{
	CreateConVar("sm_ce_version", PLUGIN_VERSION, "Show the version of the plugin", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_ce_execute", CmdReExecute, ADMFLAG_GENERIC, "Execute the config files insile the folder");
	PrintToServer("Plugin made with love by %s", AUTHOR);
	g_HostnameCvar = FindConVar("hostname");
  	if (g_HostnameCvar == INVALID_HANDLE)
    		SetFailState("Failed to find cvar \"hostname\"");
	loadConfigs();
}
public void loadConfigs(){
	char  configFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configFile, sizeof(configFile), CONFIG_FILE_PATH);
	if(!FileExists(configFile))
		SetFailState("Cannot find config file \"%s\"!", configFile);
	KeyValues kv = CreateKeyValues("CONFIGS");
	kv.ImportFromFile(configFile);
	configCount = 0;
	if(kv.GotoFirstSubKey()){
		char name[1024];
		char file[1024];
		do{
			kv.GetSectionName(name, sizeof(name));
			kv.GetString("file", file, sizeof(file));				
			strcopy(g_sConfigString[configCount], sizeof(g_sConfigString[]), name);
			strcopy(g_sConfigFile[configCount], sizeof(g_sConfigFile[]), file);
			configCount++;
		}while (kv.GotoNextKey());
	}
	kv.Rewind();
	delete kv;
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen){
	PrintToServer("[%s] OnClientConnect called with client = [%d]", AUTHOR, client);
	PrintToServer("[%s] Client Number: %d connected.", AUTHOR, client);
	int totalClientsInGame = GetClientCount(true);
	PrintToServer("[%s] Total Clients In Server(InGame) : [%d]", AUTHOR, totalClientsInGame);
	int totalClients = GetClientCount(false);
	PrintToServer("[%s] Total Clients In Server (InGame+Connecting) : [%d]", AUTHOR, totalClients);
	if(client == 1 && totalClients == 1){
		ExecCfg();
	}else{
		PrintToServer("[%s] Not invoked at startup. Aborting Config Executor!!", AUTHOR);
	}
	return true;
}

public bool ExecCfg()
{
	PrintToServer("[%s] ExecCfg called", AUTHOR);
	char hostname[1024];
  	g_HostnameCvar.GetString(hostname, sizeof(hostname));
  	int i, result;
  	for(i = 0;i < configCount; i++){
  		result = StrContains(hostname, g_sConfigString[i], false);
  		if(result > -1){
  			PrintToServer("[%s] Executing config: %s", AUTHOR, g_sConfigFile[i]);
			ServerCommand("exec \"%s\"", g_sConfigFile[i]);
			return true;
  		}
  	}
  	PrintToServer("[%s] Executing config: %s", AUTHOR, "xyg_default");
  	ServerCommand("exec xyg_default");
	return true;
}

public Action CmdReExecute(client, args)
{
	if(ExecCfg())
	{
		PrintToChat(client, "[%s] Server Configs have been executed!", AUTHOR);
	}
	else
	{
		PrintToChat(client, "[%s] An error ocurred while executing the configs!", AUTHOR);
	}
	return Plugin_Handled;
}
