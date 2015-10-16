//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//              ____                   ______      ____                     //
//             / __ \____  ___  ____  / ____/___  / / /___ ______           //
//            / / / / __ \/ _ \/ __ \/ /   / __ \/ / / __ `/ ___/           //
//           / /_/ / /_/ /  __/ / / / /___/ /_/ / / / /_/ / /               //
//           \____/ .___/\___/_/ /_/\____/\____/_/_/\__,_/_/                //
//               /_/                                                        //
//                                                                          //
//                        ,^~~~-.         .-~~~"-.                          //
//                       :  .--. \       /  .--.  \                         //
//                       : (    .-`<^~~~-: :    )  :                        //
//                       `. `-,~            ^- '  .'                        //
//                         `-:                ,.-~                          //
//                          .'                  `.                          //
//                         ,'   @   @            |                          //
//                         :    __               ;                          //
//                      ...{   (__)          ,----.                         //
//                     /   `.              ,' ,--. `.                       //
//                    |      `.,___   ,      :    : :                       //
//                    |     .'    ~~~~       \    / :                       //
//                     \.. /               `. `--' .'                       //
//                        |                  ~----~                         //
//                          Cage Home - 151016.3                            //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2015 Satomi Ahn, Nandana Singh, Joy Stipe,         //
//  Wendy Starfall, Sumi Perl, littlemousy, Romka Swallowtail et al.        //
// ------------------------------------------------------------------------ //
//  This script is free software: you can redistribute it and/or modify     //
//  it under the terms of the GNU General Public License as published       //
//  by the Free Software Foundation, version 2.                             //
//                                                                          //
//  This script is distributed in the hope that it will be useful,          //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the            //
//  GNU General Public License for more details.                            //
//                                                                          //
//  You should have received a copy of the GNU General Public License       //
//  along with this script; if not, see www.gnu.org/licenses/gpl-2.0        //
// ------------------------------------------------------------------------ //
//  This script and any derivatives based on it must remain "full perms".   //
//                                                                          //
//  "Full perms" means maintaining MODIFY, COPY, and TRANSFER permissions   //
//  in Second Life(R), OpenSimulator and the Metaverse.                     //
//                                                                          //
//  If these platforms should allow more fine-grained permissions in the    //
//  future, then "full perms" will mean the most permissive possible set    //
//  of permissions allowed by the platform.                                 //
// ------------------------------------------------------------------------ //
//         github.com/OpenCollar/opencollar/tree/master/src/spares          //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

// Based on original version and idea by Kaly Shinn & Tuco Solo

//OpenCollar Plugin Template
integer g_iDebugMode = FALSE;       // set to TRUE to enable Debug messages, if any

string  g_sParentMenu = "Apps";    // Name of the menu
string  g_sSubMenu = "Cage Home"; // Name of the g_sSubMenu

// MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_OBJECT = 506;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;

integer NOTIFY = 1002;
integer REBOOT  = -1000;
integer LINK_DIALOG = 3;
integer LINK_RLV    = 4;
integer LINK_SAVE   = 5;

integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
integer LM_SETTING_EMPTY = 2004;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD     = 6000;
integer RLV_REFRESH = 6001;
integer RLV_CLEAR   = 6002;
integer RLV_VERSION = 6003;
integer RLV_OFF = 6100;
integer RLV_ON = 6101;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";
string TEXTBOX = "Text Input";

// default settings, will be loaded upon script start. leave landing point values blank!
string DEFAULT_SETTINGS = "45|5|30|-1|arrived|released|@ will be summoned away in # seconds";

// State enumeration:
integer STATE_DEFAULT  = 0;
integer STATE_DISARMED = 1;
integer STATE_ARMED    = 2;
integer STATE_WARNING  = 3;
integer STATE_TELEPORT = 4;
integer STATE_CAGED    = 5;
integer STATE_RELEASED = 6;

// Dialog BUTtons:
string  BUT_CAGEHERE = "Cage Here";
string  BUT_ARM      = "Arm";
string  BUT_DISARM   = "Disarm";
string  BUT_RELEASE  = "Release";
string  BUT_SETTINGS = "Settings";
string  BUT_COMMANDS = "Commands";
string  BUT_CLEAR    = "Clear";
string  BUT_OPTIONS  = "Options";

string  BUT_TIME     = "Cage Time";
string  BUT_RADIUS   = "Cage Radius";
string  BUT_WARNTIME = "Warning Time";
string  BUT_CHANNEL  = "Channel";
string  BUT_ARRIVED  = "Arrived Msg";
string  BUT_RELEASED = "Released Msg";
string  BUT_WARNING  = "Warning Msg";

string  BUT_BLANK     = " ";
string  BUT_DEFAULT   = "DEFAULT";

string  g_sChatCmd = "ch";        // so the user can easily access it by type for instance *plugin
string  g_sPluginTitle = "Cage Home"; // to be used in various strings
string  CANT_DO = "Can not do - "; // used in various responses (to specify a negative response to an issued command)

list g_lMenuButtons = [
    BUT_CAGEHERE, BUT_ARM, BUT_DISARM, BUT_RELEASE, BUT_SETTINGS, BUT_COMMANDS,
    BUT_TIME, BUT_RADIUS, BUT_WARNTIME, BUT_CHANNEL,
    BUT_ARRIVED, BUT_RELEASED, BUT_WARNING
];

// available chat commands
list g_lChatCommands = [
  "here", "arm", "disarm", "release", "settings", "commands", // no-arg commands
  "cagetime", "radius", "warntime", "notifychannel",          // integer-arg commands
  "notifyarrive", "notifyrelease", "warnmessage"              // string-arg commands
];

integer CAGEHOME_NOTIFY = -11552; // internal link num to announce arrivals and releases on

integer g_iTimerOnLine  = 60;  // check every .. seconds for on-line  (timer/dataserver)
integer g_iTimerOffLine = 15;  // check every .. seconds for off-line (timer/dataserver)
integer g_iSensorTimer  = 3;   // check every .. seconds to see if cage owner is near (sensor)
integer g_iTP_Timer     = 30;  // try tp every .. seconds
integer g_iMaxTPtries   = 5;   // ...until exhausted tries

// plugin settings (dont change order as listed here, it's in 'protocol order'. see defaults below)
string  g_sCageRegion;      // landing point sim name
vector  g_vCagePos;         // landing point within region
vector  g_vRegionPos;       // regions global position.

vector  g_vLocalPos;        // used when caged

integer g_iCageTime;        // Time in minutes before the wearer is released, even if the owner is still online. Can be set to 0 for no auto release
integer g_iCageRadius;      // how far the wearer may wander from the cage point, and how close the owner must be to auto release = g_fCageRadius+1
integer g_iWarningTime;     // how much warning in seconds the wearer gets before being tped
integer g_iNotifyChannel;   // what channel to send captured and released messages on
string  g_sNotifyArrive;    // the message said on g_iNotifyChannel after the wearer has been TPed to the cage home
string  g_sNotifyRelease;   // the message said on g_iNotifyChannel after the wearer has been released from the cage home
string  g_sWarningMessage;  // the warning message, @ is replaced by the wearer full name, and # by g_iWarningTime

integer g_iState;        // keep track of current state
integer g_iCageAuth;
key     g_kCageOwnerKey;

integer g_iLoadState;

// global boolean setting
integer g_iRlvActive = TRUE; // we'll get updates from the rlv script(s)

// handles
list g_lMenuIDs;
integer g_iMenuStride = 3;

key     g_kSimPosRequestHandle; // UUID of the dataserver request
key     g_kOwnerRequestHandle;

integer g_iTargetHandle;
integer g_iTpTries;      // keep track of the number of TP attempts
integer g_iTimer ;

key     g_kWearer;
list    g_lLocalButtons = []; // extra buttons that we get inserted "from above"


list STATES = ["UNSET","DISARMED","ARMED","WARNING","TELEPORT","CAGED","RELEASED"];

DebugCurrentState(string sMsg) {
    if (g_iDebugMode) Debug(llList2String(STATES,g_iState) + " " + sMsg );
}
Debug(string sMsg) {
    if (g_iDebugMode) llOwnerSay(llGetScriptName()+" [DEBUG]: "+sMsg);
}


Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    llMessageLinked(LINK_DIALOG,NOTIFY,(string)iAlsoNotifyWearer+sMsg,kID);
}

Dialog(key kID, string sPrompt, list lChoices, list lUtility, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" +
    llDumpList2String(lChoices,"`") + "|" + llDumpList2String(lUtility,"`")+"|"+(string)iAuth,kMenuID);
    integer i = llListFindList(g_lMenuIDs, [kID]);
    if (~i) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], i, i + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

MenuMain(key kID, integer iAuth) {
    string sPrompt = "\n";
    list lButtons;
    list lUtility = [BUT_SETTINGS,UPMENU];

    if (CheckAuth(iAuth)==TRUE && iAuth<CMD_WEARER) {
        if (g_sCageRegion=="") sPrompt +=
            "Have your sub auto teleport and caged the moment you log on again. The sub will be released if:" +
            "\n\tYou approach the cage\n\tYou summon the sub\n\tThe timer runs out\n";
        if (g_iState == STATE_DEFAULT) lButtons = [BUT_CAGEHERE,BUT_BLANK,BUT_BLANK];
        else if (g_iState == STATE_DISARMED) {
            if (g_sCageRegion) lButtons = [BUT_CAGEHERE,BUT_ARM,BUT_CLEAR];
            else lButtons = [BUT_CAGEHERE,BUT_BLANK,BUT_BLANK];
        }
        else if (g_iState == STATE_CAGED) lButtons = [BUT_BLANK,BUT_RELEASE,BUT_BLANK];
        else lButtons = [BUT_BLANK,BUT_DISARM,BUT_BLANK];
        if (g_iState < STATE_ARMED) lUtility = [BUT_OPTIONS]+lUtility;
    }
    string sSub;
    string sOwner;
    if (iAuth == CMD_WEARER) {sSub = "you"; sOwner = "your";}
    else {sSub = "the sub"; sOwner = "the";}
    sPrompt += "This feature will teleport " + sSub + " to a predefined location, set by " +
        sOwner + " owner, once " + sOwner + " owner logs on again.\n";

    sPrompt += "\nFeature currently: " + llList2String(STATES, g_iState) + " ";
    if (g_iState == STATE_CAGED) {
        if (g_iCageTime > 0) sPrompt += " time is " + (string)g_iTimer + " min.";
        else sPrompt += "no timer release";
    }
    if (g_sCageRegion) sPrompt += "\nCage location: " + Map(g_sCageRegion, g_vCagePos);
    if (g_kCageOwnerKey) sPrompt += "\nCage owner: " + Name(g_kCageOwnerKey);

    Dialog(kID, sPrompt, lButtons+g_lLocalButtons, lUtility, 0, iAuth, "menu~main");
    sPrompt = "";
    lButtons = [];
}

MenuSettings(key kID, integer iAuth) {
    string sPrompt = "Cage settings:\nCage Time: ";
    if (g_iCageTime > 0) sPrompt += (string)g_iCageTime + " min";
    else sPrompt += "no timer release";
    sPrompt +=
        "\tCage Radius: " + (string)g_iCageRadius + " m" +
        "\nWarning Time: " + (string)g_iWarningTime + " sec" +
        "\tNotify Channel: " + (string)g_iNotifyChannel +
        "\nArrived Message: " + g_sNotifyArrive +
        "\nReleased Message: " + g_sNotifyRelease +
        "\nWarning Message: " + g_sWarningMessage;
    list lButtons = llList2List(g_lMenuButtons, 6, -1);  // use settings buttons only
    Dialog(kID, sPrompt, lButtons, [BUT_DEFAULT,UPMENU], 0, iAuth, "menu~settings");
    sPrompt="";
    lButtons=[];
}

list g_lSetButtons =
["30 min","1 hour","1 day","+10 min","+1 hour","+1 day","-10 min","-1 hour","-1 day","0","1","5","10","+1","+5","+10","-1","-5","-10"];

list g_lNums = [30,60,1440,10,60,1440,10,60,1440,0,1,5,10,1,5,10,1,5,10];

MenuSet(key kID, integer iAuth, string sMenuButton) {
    list lButtons;
    string sPrompt = sMenuButton + ": ";
    integer i = llListFindList(g_lMenuButtons, [sMenuButton]);
    if (i == 6) sPrompt += (string)g_iCageTime+" min";
    else if (i == 7) sPrompt += (string)g_iCageRadius + " m";
    else if (i == 8) sPrompt += (string)g_iWarningTime + " sec";
    else if (i == 9) sPrompt += (string)g_iNotifyChannel;
    else if (i == 10) sPrompt += g_sNotifyArrive;
    else if (i == 11) sPrompt += g_sNotifyRelease;
    else if (i == 12) sPrompt += g_sWarningMessage;
    if (i == 6) lButtons = llList2List(g_lSetButtons,0,9);  // buttons for Cage ime
    else if (6 < i < 10) lButtons = llList2List(g_lSetButtons,10,-1); // buttons for others params
    if (i > 9) Dialog(kID,sPrompt,[],[],0,iAuth,"set~"+sMenuButton); // use textbox input directly
    else Dialog(kID,sPrompt,lButtons,[TEXTBOX,UPMENU],0,iAuth,"set~"+sMenuButton);
    sPrompt="";
    lButtons=[];
}

Set(key kID, integer iAuth, string sMenuButton, string sButton) {
    sButton = llStringTrim(sButton,STRING_TRIM);
    if (sButton==TEXTBOX) Dialog(kID,sMenuButton,[],[],0,iAuth,"set~"+sMenuButton);
    else {
        integer iMenu = llListFindList(g_lMenuButtons, [sMenuButton]);
        if (iMenu > 9) {
            //if (sButton)
            UserCommand(iAuth, g_sChatCmd +" "+ llList2String(g_lChatCommands,iMenu)+" "+sButton, kID);
            MenuSettings(kID, iAuth);
        } else if (iMenu < 10) {
            string sParam;
            integer iParam ;
            if (iMenu == 6) iParam = g_iCageTime;
            else if (iMenu == 7) iParam = g_iCageRadius;
            else if (iMenu == 8) iParam = g_iWarningTime;
            else if (iMenu == 9) iParam = g_iNotifyChannel;
            integer i = llListFindList(g_lSetButtons,[sButton]);
            if (~i) {
                integer iNum = llList2Integer(g_lNums,i);
                if (llGetSubString(sButton,0,0)=="-") {
                    iParam -= iNum;
                    if (iParam<0) iParam=0;
                } else if (llGetSubString(sButton,0,0)=="+") iParam += iNum;
                else iParam = iNum;
                sParam = (string)iParam;
            } else {
                if ((integer)sButton) sParam = sButton;
                else sParam = "";
            }
            if (iMenu > 6 && iMenu < 10 && sParam=="0") sParam = "";
            if (sParam) UserCommand(iAuth, g_sChatCmd+" "+llList2String(g_lChatCommands,iMenu)+" "+sParam, kID);
            MenuSet(kID, iAuth, sMenuButton);
        }
    }
}

// Stores all settings (using the settings or database script, or whatever)
SaveSettings() {
    string sSaveString = llDumpList2String([g_iCageTime, g_iCageRadius, g_iWarningTime, g_iNotifyChannel, g_sNotifyArrive, g_sNotifyRelease, g_sWarningMessage], "|");
    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "cagehome_settings="+sSaveString, "");
}

SaveRegion() {
    string sSaveString = llDumpList2String([g_sCageRegion, g_vCagePos, g_vRegionPos], "|");
    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "cagehome_region="+sSaveString, "");
}

SaveState() {
    string sSaveString = (string)g_iState+"|"+(string)g_iCageAuth+"|"+(string)g_kCageOwnerKey;
    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "cagehome_state="+sSaveString, "");
}

// Parses sValue, that we received from the settings or database script earlier,
// into our global settings variables.
ParseSettings(string sValue) {
    list lValues = llParseStringKeepNulls(sValue, ["|"], []);
    if (llGetListLength(lValues) == 7) {
        g_iCageTime       = (integer)llList2String(lValues, 0);
        g_iCageRadius     = (integer)llList2String(lValues, 1);
        g_iWarningTime    = (integer)llList2String(lValues, 2);
        g_iNotifyChannel  = (integer)llList2String(lValues, 3);
        g_sNotifyArrive   = llList2String(lValues, 4);
        g_sNotifyRelease  = llList2String(lValues, 5);
        g_sWarningMessage = llList2String(lValues, 6);
    }
    //else Debug("parse error");
}

ParseRegion(string sValue) {
    list lValues = llParseStringKeepNulls(sValue, ["|"], []);
    if (llGetListLength(lValues) == 3) {
        g_sCageRegion         = llList2String(lValues, 0);
        g_vCagePos    = (vector)llList2String(lValues, 1);
        g_vRegionPos  = (vector)llList2String(lValues, 2);
    }
}

ParseState(string sValue) {
    list lValues = llParseString2List(sValue, ["|"], []);
    //g_iState = (integer)llList2String(lValues, 0);
    g_iLoadState = (integer)llList2String(lValues, 0);
    g_iCageAuth = (integer)llList2String(lValues, 1);
    g_kCageOwnerKey = (key)llList2String(lValues, 2);
}

// Reports current settings to kAv.
ReportSettings(key kAv) {
    string sMsg = g_sPluginTitle + " Settings:\nLocation: ";

    if (g_sCageRegion) sMsg += Map(g_sCageRegion, g_vCagePos) ;
    else sMsg += " not set," ;
    sMsg += "\nCurrent state: " + llList2String(STATES,g_iState);
    if (g_kCageOwnerKey) sMsg += "\nCage Owner: " + Name(g_kCageOwnerKey);
    sMsg += "\nCage Wait: ";
    if (g_iCageTime > 0) sMsg += (string)g_iCageTime + " min";
    else sMsg += "no timer release";
    sMsg += "\nCage Radius: " + (string)g_iCageRadius + " m" +
        "\nWarning Time: " + (string)g_iWarningTime + " sec" +
        "\nCage Notify Channel: " + (string)g_iNotifyChannel +
        "\nArrived Message: " + g_sNotifyArrive +
        "\nReleased Message: " + g_sNotifyRelease +
        "\nWarning Message: " + g_sWarningMessage;
    // we're using the new llRegionSayTo() instead of llInstantMessage(), for it has no delay penalty
    // and we know kAv is near
    llRegionSayTo(kAv, 0, sMsg);
}

ShowCommands(key kID) {
    // we're using the new llRegionSayTo() instead of llInstantMessage(), for it has no delay penalty
    llRegionSayTo(kID, 0, llDumpList2String([g_sPluginTitle + " Commands:"] + g_lChatCommands, "\n"));
}

SetRlvRestrictions() {
    SendRlvCommands(["tplm=n","tploc=n","tplure=n","tplure:"+(string)g_kCageOwnerKey+"=add", "sittp=n","rez=n"
        // ,"standtp=n"
    ]);
}

ClearRlvRestrictions() {
    SendRlvCommands(["tplm=y","tploc=y","tplure=y","sittp=y","rez=y"
        // ,"standtp=y"
    ]);
}

// Sends a list of RLV-commands to the collar script(s), one by one.
SendRlvCommands(list lRlvCommands) {
    integer i;
    for (i = 0; i < llGetListLength(lRlvCommands); i++) {
        llMessageLinked(LINK_RLV, RLV_CMD, llList2String(lRlvCommands, i), NULL_KEY);
    }
}

// Returns sSource with sReplace replaced for all occasions of sSearch
string StrReplace(string sSource, string sSearch, string sReplace) {
    return llDumpList2String(llParseStringKeepNulls((sSource = "") + sSource, [sSearch], []), sReplace);
}

string Name(key kID) {
    return "secondlife:///app/agent/"+(string)kID+"/inspect";
}
// Returns vector vVec in a string with form "x/y/z", where x, y and z are
// rounded down to the nearest integer.
string Vector2UrlCoordinates(vector vVec) {
    return llDumpList2String([(integer)vVec.x, (integer)vVec.y, (integer)vVec.z], "/");
}

string Map(string sRegion, vector vPos) {
    return "http://maps.secondlife.com/secondlife/" + llEscapeURL(sRegion) +"/"+ Vector2UrlCoordinates(vPos);
}

// Sends a message to kActor and the wearer about the captive change (armed, released, disarmed).
// A copy is sent to the wearer. If kActor is not the Cage Owner, the Cage Owner will receive a copy as well.
//
NotifyCaptiveChange(key kActor, integer iState) {
    string sActor = Name(kActor);
    string sMsg;
    if (iState == STATE_ARMED) sMsg = sActor+" armed "+g_sPluginTitle+" for %WEARERNAME%";
    else if (iState == STATE_DISARMED) sMsg = sActor+" disarmed %WEARERNAME%'s "+g_sPluginTitle;
    else if (iState == STATE_RELEASED) sMsg = sActor+" released %WEARERNAME% from "+g_sPluginTitle;
    Notify(kActor, sMsg, TRUE);
    if (kActor != g_kCageOwnerKey) Notify(g_kCageOwnerKey, sMsg, FALSE);
}

NotifyLocationSet(key kActor) {
    Notify(kActor, g_sPluginTitle+" Location set to "+Map(g_sCageRegion,g_vCagePos), TRUE);
}

CheckState() {
    if (g_iLoadState == STATE_CAGED) {
        if (llGetRegionName()==g_sCageRegion && llVecDist(g_vCagePos,llGetPos()) < 10) SetState(STATE_CAGED);
        else SetState(STATE_TELEPORT);
    } else SetState(g_iLoadState);
}

CheckTeleport() {
    //DebugCurrentState("CheckTeleport");
    if (g_iState == STATE_TELEPORT) {
        if (llGetRegionName()==g_sCageRegion && llVecDist(g_vCagePos,llGetPos()) < 10) {
            llSetTimerEvent(0);
            llResetTime();
            SetState(STATE_CAGED);
            return;
        } else {
            //llSetTimerEvent(g_iTP_Timer); // try tp every ... seconds
            SendRlvCommands(["tploc=y","unsit=y"]);
            //llOwnerSay("@tpto:"+Vector2UrlCoordinates(g_vRegionPos+g_vCagePos)+"=force");
            SendRlvCommands(["tpto:"+Vector2UrlCoordinates(g_vRegionPos+g_vCagePos)+"=force"]);
        }
    } else if (g_iState == STATE_CAGED) {
        if (llGetRegionName()!=g_sCageRegion || llVecDist(g_vCagePos,llGetPos())>10) {
            // TP has been blocked, expect for summons by cage owner
            //SetState(STATE_RELEASED);
            SetState(STATE_DISARMED);
            NotifyCaptiveChange(g_kCageOwnerKey, STATE_RELEASED);
        }
    } else if (g_iState == STATE_ARMED) {
       // if (llGetRegionName()==g_sCageRegion && llVecDist(g_vCagePos,llGetPos())<10) {
           //SetState(STATE_CAGED);
       // }
    }
}

SetState(integer iState) {
    @again;
    //DebugCurrentState("SetState");
    if (iState == g_iState) return;
    g_iState = iState;
    if (iState <= STATE_DISARMED) {
        g_iCageAuth = CMD_EVERYONE;
        g_kCageOwnerKey = "";
        llSetTimerEvent(0);
        llSensorRemove();
        llTargetRemove(g_iTargetHandle);
        llStopMoveToTarget();
        ClearRlvRestrictions();
    } else if (iState == STATE_ARMED) {
        g_kOwnerRequestHandle = llRequestAgentData(g_kCageOwnerKey, DATA_ONLINE);
    } else if (iState == STATE_WARNING) {
        if (g_iWarningTime > 1) {
            string sMsg = StrReplace(g_sWarningMessage, "@", Name(g_kWearer));
            sMsg = StrReplace(sMsg, "#", (string)g_iWarningTime);
            string sObjectName = llGetObjectName();
            llSetObjectName(g_sPluginTitle);
            llSay(0, sMsg);
            llSetObjectName(sObjectName);
            llSetTimerEvent(g_iWarningTime);
        } else {
            iState = STATE_TELEPORT;
            jump again;
        }
    } else if (iState == STATE_TELEPORT) {
        if (!g_iRlvActive || llGetAttached() == 0) {
            string sMsg = g_sPluginTitle + " can not teleport %WEARERNAME% for ";
            if (!g_iRlvActive) sMsg += "RLV was not detected.";
            else sMsg += "collar seems not attached.";
            Notify(g_kCageOwnerKey, sMsg + " AddOn now disarming itself.", TRUE);
            iState = STATE_DISARMED;
            jump again;
        } else {
            g_iTpTries = g_iMaxTPtries;
            llSetTimerEvent(5); // let the timer event do the TP thing
        }
    } else if (iState == STATE_CAGED) {
        SetRlvRestrictions();
        if (llGetRegionName()==g_sCageRegion) g_vLocalPos = g_vCagePos;
        else g_vLocalPos = llGetPos();
        Notify(g_kCageOwnerKey, "Your sub %WEARERNAME% has just been teleported by the "+g_sPluginTitle+
            " feature and is now waiting for you at "+Map(llGetRegionName(),g_vLocalPos), FALSE);
        g_iTargetHandle = llTarget(g_vLocalPos, (float)g_iCageRadius);
        string sMsg = g_sPluginTitle + " now active ";
        if (g_iCageTime > 0) {
            g_iTimer = g_iCageTime;
            llSetTimerEvent(60);
            sMsg += "on a " + (string)g_iCageTime + " minutes timer";
        } else sMsg += "with no time limit";
        Notify(g_kWearer, sMsg, FALSE);
        llSensorRepeat("", g_kCageOwnerKey, AGENT, g_iCageRadius+1, PI, g_iSensorTimer);
        if (g_iNotifyChannel != 0) llSay(g_iNotifyChannel, g_sNotifyArrive);
        llMessageLinked(LINK_THIS, CAGEHOME_NOTIFY, g_sNotifyArrive, "");
    } else if (iState == STATE_RELEASED) {
        ClearRlvRestrictions();
        llSensorRemove();
        llStopMoveToTarget();
        llTargetRemove(g_iTargetHandle);
        if (g_iNotifyChannel != 0) llSay(g_iNotifyChannel, g_sNotifyRelease);
        llMessageLinked(LINK_THIS, CAGEHOME_NOTIFY, g_sNotifyRelease, "");
        llSetTimerEvent(g_iTimerOnLine);
    }
    //DebugCurrentStateFreeMemory();
    SaveState();
}

// return TRUE if Auth rank above Cage owner
integer CheckAuth(integer iAuth) {
    if ((STATE_RELEASED>g_iState>STATE_DISARMED) && (g_iCageAuth>0) && (iAuth>g_iCageAuth)) return FALSE;
    else return TRUE;
}

UserCommand(integer iAuth, string sStr, key kID) {
    if (iAuth < CMD_OWNER || iAuth > CMD_WEARER) return;

    if (sStr=="menu "+g_sSubMenu || sStr==g_sSubMenu || sStr==g_sChatCmd) MenuMain(kID,iAuth);
    else if (sStr == "settings") { // collar's command to request settings of all modules
        string sMsg = g_sPluginTitle+": "+llList2String(STATES, g_iState);
        if (g_sCageRegion!="") sMsg += ", TP Location: "+Map(g_sCageRegion, g_vCagePos);
        llSleep(0.5);
        Notify(kID, sMsg, FALSE);
    } else {
        // PLUGIN CHAT g_lChatCommands
        if (llSubStringIndex(sStr, g_sChatCmd+" ") != 0) return;
        sStr = llDeleteSubString(sStr, 0, llStringLength(g_sChatCmd));
        string sCommand = sStr;
        string sValue = "";
        integer i = llSubStringIndex(sStr, " ");
        if (i != -1) {
            sCommand = llDeleteSubString(sStr, i, -1);
            sValue = llDeleteSubString(sStr, 0, i);
        }
        sStr = "";
        i = llListFindList(g_lChatCommands, [sCommand]); // re-use variable i
        if (!~i) return;
        if (CheckAuth(iAuth)==FALSE) {
            Notify(kID, "%NOACCESS", FALSE);
            return;
        }
        if (i == 0) { // chhere
            if (g_iState <= STATE_DISARMED) {
                g_vCagePos = llGetPos();
                g_sCageRegion = llGetRegionName();
                g_kSimPosRequestHandle = llRequestSimulatorData(g_sCageRegion, DATA_SIM_POS);
                // script sleep 1.0 seconds
                if (g_iState == STATE_DEFAULT) SetState(STATE_DISARMED);
                NotifyLocationSet(kID);
            } else Notify(kID, CANT_DO+"still armed, disarm first", FALSE);
        } else if (i == 1) { // charm
            if (g_iState <= STATE_DISARMED) {
                g_kCageOwnerKey = kID;
                g_iCageAuth = iAuth;
                SetState(STATE_ARMED);
                NotifyCaptiveChange(kID, STATE_ARMED);
            } else if (g_iState >= STATE_ARMED) Notify(kID,CANT_DO+"already armed",FALSE);
            else if (g_iState < STATE_DISARMED) Notify(kID,CANT_DO+g_sPluginTitle+" Location not set",FALSE);
        } else if (i == 2) { // chdisarm
            if (g_iState <= STATE_DISARMED) Notify(kID,CANT_DO+"already disarmed",FALSE);
            else if ((g_iState > STATE_DISARMED && g_iState < STATE_CAGED) || g_iState == STATE_RELEASED) {
                SetState(STATE_DISARMED);
                NotifyCaptiveChange(kID, STATE_DISARMED);
            } else if (g_iState == STATE_CAGED) Notify(kID,CANT_DO+"release sub first",FALSE);
        } else if (i == 3) { // chrelease
            if (g_iState >= STATE_TELEPORT && g_iState <= STATE_CAGED) {
                SetState(STATE_RELEASED);
                NotifyCaptiveChange(kID, STATE_RELEASED);
            } else if (g_iState <= STATE_WARNING) Notify(kID,CANT_DO+"sub not caged",FALSE);
        } else if (i == 4) ReportSettings(kID); // chsettings
        else if (i == 5) ShowCommands(kID); // chcommands
        // next commands need an argument. check first for its existance:
        else if (i > 5 && sValue == "") Notify(kID, "Command "+sCommand+" requires an argument", FALSE);
        else {
            // notify once, created with strings sDescr and sAppend:
            string sDescr = "";
            string sAppend = "";
            // within this else-block: things with an argument (and then save)
            if (i == 6) { // chcagetime
                g_iCageTime = (integer)sValue;
                sDescr = "Cage Wait";
                sAppend = sValue + " min";
            } else if (i == 7) { // chradius
                g_iCageRadius = (integer)sValue;
                sDescr = "Cage Radius";
                sAppend = sValue + " m";
            } else if (i == 8) { // chwarntime
                g_iWarningTime = (integer)sValue;
                sDescr = "Warning Time";
                sAppend = sValue + " sec";
            } else if (i == 9) { // chnotifychannel
                g_iNotifyChannel = (integer)sValue;
                sDescr = "Cage Notify Channel";
                sAppend = sValue;
            } else {
                if (i == 10) { // cagenotifyarrive
                    g_sNotifyArrive = sValue;
                    sDescr = "Cage Notify Arrive";
                } else if (i == 11) { // cagenotifyrelease
                    g_sNotifyRelease = sValue;
                    sDescr = "Cage Notify Release";
                } else if (i == 12) { // cagewarningmessage
                    g_sWarningMessage = sValue;
                    sDescr = "Cage Warning Message";
                }
                sAppend = "'" + sValue + "'";
            }
            if (sDescr != "") Notify(kID, sDescr+" set to "+sAppend, TRUE);
            SaveSettings();
        }
    }
}


default {

    on_rez(integer iParam) {
        g_iRlvActive = TRUE; // let the collar send new RLV-information upon rez
        g_iState = STATE_DEFAULT;
    }

    state_entry() {
        g_iState = STATE_DEFAULT;
        g_iCageAuth = CMD_EVERYONE;
        g_kWearer = llGetOwner();
        ParseSettings(DEFAULT_SETTINGS); // default settings do not include the home location
        //DebugCurrentStateFreeMemory();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum,sStr,kID);
        else if (iNum == RLV_REFRESH && g_iState == STATE_CAGED) SetRlvRestrictions();
        else if (iNum == RLV_VERSION) g_iRlvActive = TRUE;
        else if (iNum == RLV_CLEAR && g_iState == STATE_CAGED) SetState(STATE_RELEASED);
        else if (iNum == RLV_ON) g_iRlvActive = TRUE;
        else if (iNum == RLV_OFF) g_iRlvActive = FALSE;
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+g_sSubMenu, "");
            g_lLocalButtons = [] ; // flush submenu buttons
            llMessageLinked(LINK_THIS, MENUNAME_REQUEST, g_sSubMenu, "");
        } else if (iNum == MENUNAME_RESPONSE) { // a button is sent to be added to a menu
            list lParts = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParts, 0) == g_sSubMenu) { // someone wants to stick something in our menu
                string button = llList2String(lParts, 1);
                if (llListFindList(g_lLocalButtons,[button])==-1) g_lLocalButtons=llListSort(g_lLocalButtons+[button],1,TRUE);
            }
        } else if (iNum == MENUNAME_REMOVE) { // a button is sent to be added to a menu
            list lParts = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParts, 0) == g_sSubMenu) {
                integer i = llListFindList(g_lLocalButtons,[llList2String(lParts, 1)]);
                if (~i) g_lLocalButtons=llDeleteSubList(g_lLocalButtons, i, i);
            }
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "cagehome_settings") ParseSettings(sValue);
            else if (sToken == "cagehome_region") ParseRegion(sValue);
            else if (sToken == "cagehome_state") ParseState(sValue);
            else if (sStr == "settings=sent") CheckState();
        } else if (iNum == CMD_SAFEWORD && g_iState == STATE_CAGED) {
            SetState(STATE_RELEASED);
            NotifyCaptiveChange(g_kCageOwnerKey, STATE_RELEASED);
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex == -1) return;
            string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
            // got a menu response meant for us, extract the sValues
            list lMenuParams = llParseString2List(sStr, ["|"], []);
            key kAv = (key)llList2String(lMenuParams, 0);
            string sMsg = llList2String(lMenuParams, 1);
            //integer iPage = (integer)llList2String(lMenuParams, 2);
            integer iAuth = (integer)llList2String(lMenuParams, 3);
            if (sMenu == "menu~main") {
                // request to change to parent menu
                if (sMsg == UPMENU) llMessageLinked(LINK_THIS,iAuth,"menu "+g_sParentMenu,kAv);
                else if (~llListFindList(g_lLocalButtons,[sMsg])) llMessageLinked(LINK_THIS,iAuth,"menu "+sMsg,kAv);
                else if (sMsg == BUT_OPTIONS) MenuSettings(kAv, iAuth);
                else {
                    integer i = llListFindList(g_lMenuButtons, [sMsg]);
                    if (~i) UserCommand(iAuth, g_sChatCmd+" "+llList2String(g_lChatCommands, i), kAv);
                    else if (sMsg == BUT_CLEAR && g_iState == STATE_DISARMED) {
                        g_iState = STATE_DEFAULT;
                        g_iCageAuth = CMD_EVERYONE;
                        g_kCageOwnerKey = NULL_KEY;
                        g_sCageRegion = "";
                        g_vCagePos = ZERO_VECTOR;
                        g_vRegionPos = ZERO_VECTOR;
                        llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "cagehome_state", "");
                        llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "cagehome_region", "");
                    }
                    MenuMain(kAv, iAuth);
                }
            } else if (sMenu == "menu~settings") {
                if (sMsg == UPMENU) MenuMain(kAv, iAuth);
                else if (sMsg == BUT_DEFAULT) {
                    ParseSettings(DEFAULT_SETTINGS);
                    SaveSettings();
                    MenuSettings(kAv, iAuth);
                } else MenuSet(kAv, iAuth, sMsg);
            } else if (llSubStringIndex(sMenu,"set~") == 0) {
                string sMenuButton = llDeleteSubString(sMenu,0,llStringLength("set~")-1);
                if (sMsg == UPMENU) MenuSettings(kAv, iAuth);
                else Set(kAv, iAuth, sMenuButton, sMsg);
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }

    dataserver(key kQueryid, string data) {
        if (kQueryid == g_kSimPosRequestHandle) {
            g_vRegionPos = (vector)data;
            SaveRegion();
        } else if (kQueryid == g_kOwnerRequestHandle) { // cage owner went offline
            if (data == "0") {
                llSetTimerEvent(g_iTimerOffLine);
                SetState(STATE_ARMED);
            }
            if (data == "1" && g_iState != STATE_RELEASED) {
                llSetTimerEvent(g_iTimerOnLine);
                SetState(STATE_WARNING);
            }
        }
    }

    timer() {
        if (g_iState == STATE_ARMED || g_iState == STATE_RELEASED) {
            g_kOwnerRequestHandle = llRequestAgentData(g_kCageOwnerKey, DATA_ONLINE);
        } else if (g_iState == STATE_WARNING) SetState(STATE_TELEPORT);
        else if (g_iState == STATE_TELEPORT) {
            if (g_iTpTries > 0) {
                g_iTpTries--;
                CheckTeleport();
            } else {
                Notify(g_kWearer, "Number of TP tries exhausted. Caging you here.", FALSE);
                SetState(STATE_CAGED);
            }
        } else if (g_iState == STATE_CAGED) {
            g_iTimer--;
            if (g_iTimer <= 0) {
                Notify(g_kCageOwnerKey, "Time's up! %WEARERNAME% released from "+g_sPluginTitle, TRUE);
                SetState(STATE_RELEASED);
            }
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_TELEPORT) CheckTeleport();
    }

    sensor(integer iNum) {
        if (g_iState == STATE_CAGED) {
            Notify(g_kCageOwnerKey, "%WEARERNAME% released from "+g_sPluginTitle, TRUE);
            SetState(STATE_RELEASED);
        }
    }

    not_at_target() {
        if (g_iState == STATE_CAGED) llMoveToTarget(g_vLocalPos, 0.5);
    }

    at_target(integer iNum, vector vTargetPos, vector vOurPos) {
        if (g_iState == STATE_CAGED) llStopMoveToTarget();
    }
}
