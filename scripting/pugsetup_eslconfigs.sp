#include <cstrike>
#include <sourcemod>
#include "include/pugsetup.inc"
#include "pugsetup/generic.sp"

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
    name = "CS:GO PugSetup: load esl configs depending on team size",
    author = "ThaKilla",
    description = "Load ESL XonX configs depending on selected team size.",
    version = PLUGIN_VERSION,
    url = "https://github.com/thakilla/csgo-pug-setup"
};

public void OnPluginStart() {
	g_hMessageFormat = CreateConVar("sm_pugsetup_eslconfigs_format", "--> Load ESL {TEAMSIZE}on{TEAMSIZE} Config", "Format of the eslconfigs output string.");
}

public void PugSetup_OnReadyToStart() {
    TeamType teamType;
    MapType mapType;
    int playersPerTeam;
    bool recordDemo; 
    bool knifeRound; 
    bool autoLive;
    PugSetup_GetSetupOptions(teamType, mapType, playersPerTeam, recordDemo, knifeRound, autoLive);

    ConVar configCvar = FindConVar("sm_pugsetup_live_cfg");
    char newConfig[PLATFORM_MAX_PATH];
    Format(newConfig, sizeof(newConfig), "live%don%d.cfg", playersPerTeam, playersPerTeam);
    configCvar.SetString(newConfig);

    PugSetup_MessageToAll(playersPerTeam, "LoadESLConfigMessage");
}