#include <cstrike>
#include <sourcemod>
#include "include/pugsetup.inc"
#include "pugsetup/generic.sp"

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
    name = "CS:GO PugSetup: load esl configs depending on team size",
    author = "ThaKilla",
    description = "Load esl XonX configs depending on selected team size.",
    version = PLUGIN_VERSION,
    url = "https://github.com/thakilla/csgo-pug-setup"
};

public void OnPluginStart() {
	PugSetup_MessageToAll("%t", "TestMessage");
}