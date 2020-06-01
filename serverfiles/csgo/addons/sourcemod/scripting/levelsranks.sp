/***************************************************************************
****
****		Date of creation :			November 27, 2014
****		Date of official release :	April 12, 2015
****		Last update :				November 15, 2019
****
****************************************************************************
****
****		Authors:
****
****		RoadSide Romeo
****		( main development v1.0 - v3.0)
****
****		Wend4r
****		( main development v3.1)
****
****		Development assistance:
****
****		R1KO
****		( training - modular system, fix errors )
****
****		TiBarification (aka White Wolf)
****		( training - method of transaction, fix errors )
****
****		Kruzya
****		( fix errors and helpful advices )
****
****		Kaneki
****		( fix errors )
****
****		M0st1ce
****		( web-interface )
****
****		Grey
****		( manual new syntax )
****
****		Testers
****		( test of plugin )
****
****		Translation assistance:
****
****		Unity (aka valeologist) & mika
****		( translation of phrases in Ukrainian )
****
****		LemonPAKA
****		( translation of phrases in Chinese )
****
****		freakexeuLow & Wutz
****		( translation of phrases in German )
****
****		Hackmastr
****		( translation of phrases in Spanish )
****
***************************************************************************/

#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <sdktools>

#if SOURCEMOD_V_MINOR < 10
	#error This plugin can only compile on SourceMod 1.10.
#endif

#pragma newdecls required
#pragma tabsize 4

#include <lvl_ranks>

#if !defined PLUGIN_INT_VERSION || PLUGIN_INT_VERSION != 03010500
	#error This plugin can only compile on lvl_ranks.inc v3.1.5.
#endif

#define PLUGIN_NAME "Levels Ranks"
#define PLUGIN_AUTHORS "RoadSide Romeo & Wend4r"

#include "levels_ranks/defines.sp"

enum struct LR_PlayerInfo
{
	bool bHaveBomb;
	bool bInitialized;

	int  iAccountID;
	int  iStats[LR_StatsType];
	int  iSessionStats[LR_StatsType];
	int  iRoundExp;
	int  iKillStreak;
}

any				g_Settings[LR_SettingType],
				g_SettingsStats[LR_SettingStatsType];

bool			g_bAllowStatistic,
				g_bDatabaseSQLite;

int				g_iBonus[10],
				g_iCountRetryConnect,
				g_iDBCountPlayers;

char			g_sPluginName[] = PLUGIN_NAME,
				g_sPluginTitle[64],
				g_sTableName[32],
				g_sSoundUp[PLATFORM_MAX_PATH],
				g_sSoundDown[PLATFORM_MAX_PATH];

LR_PlayerInfo	g_iPlayerInfo[MAXPLAYERS+1],
				g_iInfoNULL;

GlobalForward	g_hForward_OnCoreIsReady;

PrivateForward	g_hForward_Hook[LR_HookType],
				g_hForward_CreatedMenu[LR_MenuType],
				g_hForward_SelectedMenu[LR_MenuType];

EngineVersion	g_iEngine;

ArrayList		g_hRankNames,
				g_hRankExp;

Cookie			g_hLastResetMyStats;

Database		g_hDatabase;

Transaction		g_hTransactionLossDB;

#include "levels_ranks/settings.sp"
#include "levels_ranks/database.sp"
#include "levels_ranks/commands.sp"
#include "levels_ranks/menus.sp"
#include "levels_ranks/custom_functions.sp"
#include "levels_ranks/events.sp"
#include "levels_ranks/api.sp"

public Plugin myinfo = 
{
	name = "[" ... PLUGIN_NAME ... "] Core", 
	author = PLUGIN_AUTHORS,
	version = PLUGIN_VERSION
};

public void OnPluginStart()
{
	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations(g_iEngine == Engine_SourceSDK2006 ? "lr_core_old.phrases" : "lr_core.phrases");
	LoadTranslations("lr_core_ranks.phrases");

	RegConsoleCmd("sm_lvl", Call_MainMenu, "Opens the statistics menu");
	RegAdminCmd("sm_lvl_reload", Call_ReloadSettings, ADMFLAG_ROOT, "Reloads core and module configuration files");
	RegServerCmd("sm_lvl_reset", Call_ResetData, "Сlearing all data in the database");
	RegAdminCmd("sm_lvl_del", Call_ResetPlayer, ADMFLAG_ROOT, "Resets player stats");

	HookEvents();
	SetSettings();
	ConnectDB();
}

public void OnMapStart()
{
	if(g_Settings[LR_IsLevelSound])
	{
		static char sSoundPath[PLATFORM_MAX_PATH + 6] = "sound/";

		strcopy(sSoundPath[6], sizeof(g_sSoundUp), g_sSoundUp);
		AddFileToDownloadsTable(sSoundPath);

		strcopy(sSoundPath[6], sizeof(g_sSoundDown), g_sSoundDown);
		AddFileToDownloadsTable(sSoundPath);

		if(g_iEngine == Engine_CSGO)
		{
			int iStringTable = FindStringTable("soundprecache");

			AddToStringTable(iStringTable, g_sSoundUp);
			AddToStringTable(iStringTable, g_sSoundDown);
		}
		else
		{
			PrecacheSound(g_sSoundUp);
			PrecacheSound(g_sSoundDown);
		}
	}

	OnCleanDB();
}

public void OnPluginEnd()
{
	for(int i = GetMaxPlayers(); --i;)
	{
		if(g_iPlayerInfo[i].bInitialized)
		{
			SaveDataPlayer(i, true);
		}
	}
}