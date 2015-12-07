//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//       _   ___     __            __  ___  _                               //
//      | | / (_)___/ /___ _____ _/ / / _ \(_)__ ___ ________ ________      //
//      | |/ / / __/ __/ // / _ `/ / / // / (_-</ _ `/ __/ _ `/ __/ -_)     //
//      |___/_/_/  \__/\_,_/\_,_/_/ /____/_/___/\_, /_/  \_,_/\__/\__/      //
//                                             /___/                        //
//                                                                          //
//                                        _                                 //
//                                        \`*-.                             //
//                                         )  _`-.                          //
//                                        .  : `. .                         //
//                                        : _   '  \                        //
//                                        ; *` _.   `*-._                   //
//                                        `-.-'          `-.                //
//                                          ;       `       `.              //
//                                          :.       .        \             //
//                                          . \  .   :   .-'   .            //
//                                          '  `+.;  ;  '      :            //
//                                          :  '  |    ;       ;-.          //
//                                          ; '   : :`-:     _.`* ;         //
//           Capture - 151027.1           .*' /  .*' ; .*`- +'  `*'          //
//                                       `*-*   `*-*  `*-*'                 //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2014 - 2015 littlemousy, Sumi Perl, Wendy Starfall,       //
//  Garvin Twine, SamRaven                                                  //
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
//         github.com/OpenCollar/opencollar/tree/master/src/collar          //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

// Based on OpenCollar - takeme 3.980
// Compatible with OpenCollar API 4.0
// and/or minimum Disgraced Version 1.3.2

// Adds support for timed captures
// Adds support for escape game

key     g_kWearer;

list    g_lMenuIDs;      //menu information, 5 strided list, userKey, menuKey, menuName, captorKey, captorName

//MESSAGE MAP
integer CMD_ZERO = 0;//*****
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

integer NOTIFY              =  1002;
integer SAY                 =  1004;
integer REBOOT              = -1000;//*****
integer LINK_AUTH           =  2;//*****
integer LINK_DIALOG         =  3;//*****
integer LINK_RLV            =  4;//*****
integer LINK_SAVE           =  5;//*****
integer LM_SETTING_SAVE     =  2000;
integer LM_SETTING_REQUEST  =  2001;
integer LM_SETTING_RESPONSE =  2002;
integer LM_SETTING_DELETE   =  2003;
integer LM_SETTING_EMPTY    =  2004;

integer MENUNAME_REQUEST    =  3000;
integer MENUNAME_RESPONSE   =  3001;

integer DIALOG              = -9000;
integer DIALOG_RESPONSE     = -9001;
integer DIALOG_TIMEOUT      = -9002;

list    g_lTempOwners;                   // locally stored list of temp owners
integer g_iRiskyOn     = FALSE;     // true means captor confirms, false means wearer confirms
integer g_iCaptureOn        = FALSE;     // on/off toggle for the app.  Switching off clears tempowner list
string  g_sSettingToken     = "capture_";
//string  g_sGlobalToken      = "global_";

// variables to support capture escape modes

//Constants affecting times and percentage chances - could be tweaked if desired though the time labels would make less sense then
integer g_iEscapesSoFar     = 0; // number of succefful escapes so far - release wearer once it equals g_iNumberRequired
integer g_iNumberRequired    = 2; // weighting factor - number of successful escape attempts required for release or number of hours of capture - default is 2
integer ESCAPE_CHANCE       = -5; // percentage escape chance each try (1/20) - made negative to distinguish from timings
integer EASY_ESCAPE_CHANCE  = -20; // 1/5 chance to escape each try 
integer PERMANENT           = 0; //marker for permanent capture mode to improve code readability
integer HOUR                = 3600; // hour in seconds 
// integer HOUR                = 300; // TEST MODE hour in seconds (5 mins)
integer DAY                 = 86400; // day in seconds
integer WEEK                = 604800; //// week in seconds
float   FIFTEEN_MINUTES       = 900.0; // fifteen minute constant means the timer's standard interval can be tweaked if desired but then some messages would need to change
// float   FIFTEEN_MINUTES       = 60.0; // TEST MODE value - one minute timer repeat

integer g_iCaptureMode      = 3600; // permanent was the default in 4.0 OC before this mod but I would suggest 3600 might be a better choice
// 0 = permanent , -1 = Escape mode, -10 = easy escape mode, 3600 = 1 hour (default), 86400 = 1 day, 604800 = 1 week (timer modes are numbers of seconds)
integer g_iIsChatty         = FALSE; // allows muting of the 15 minute capture announce
integer g_iStartingUnixTime = 0; // records the initial capture time for timed releases
integer g_iEscapeAttemptNow = FALSE; // notes whether an escape attempt is now possible (only once every 15 minutes - using timer)

// button names - stored as variables to prevent spelling related logic errors
string  g_sCaptureInactive   = "OFF";
string  g_sCaptureActive     = "ASK";// the OFF / ON thing confuses me - does off on a button mean it IS off or click this to switch it off, so I changed it :-)
string  g_sCaptureRisky      = "RISKY";

//string  g_sVulnerableYes    = "☒ vulnerable"; // vulnerability buttons changed to "variable scheme for consistency
//string  g_sVulnerableNo     = "☐ vulnerable";

string  g_sIncrease         = "increase";
string  g_sDecrease         = "decrease";  
string  g_sChattyOn         = "☒ chatty"; // allows muting of the 15 minute capture announce and some other spam
string  g_sChattyOff        = "☐ chatty"; 
string  g_sPermCaptureOn    = "● permanent"; // the standard setting for the default capture plugin
string  g_sPermCaptureOff   = "○ permanent"; // these settings are mutually exclusive radio buttons hence circles not squares
string  g_sEscapeOn         = "● escape"; // 1% chance of escape per attempt
string  g_sEscapeOff        = "○ escape";
string  g_sEasyEscapeOn `   = "● easy escape"; // 10% chance of escape per attempt
string  g_sEasyEscapeOff    = "○ easy escape";
string  g_sOneHourOn        = "● hour"; // one hour release timer - default for this plugin
string  g_sOneHourOff       = "○ hour";
string  g_sOneDayOn         = "● day"; // one day release timer
string  g_sOneDayOff        = "○ day";
string  g_sOneWeekOn        = "● week"; // one week release timer
string  g_sOneWeekOff       = "○ week";

/*
integer g_iProfiled;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+") :\n" + sStr);
}
*/

string NameURI(key kID){
    return "secondlife:///app/agent/"+(string)kID+"/about";
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName, key kCaptor, string sCaptor) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName, kCaptor, sCaptor], iIndex, iIndex + 4);
    else g_lMenuIDs += [kID, kMenuID, sName, kCaptor, sCaptor];
    //Debug("Menu:"+sName);
}

CaptureMenu(key kId, integer iAuth) {
    string sPrompt = "\n[http://www.opencollar.at/capture.html Capture]\n";
    list lMyButtons;
    if (llGetListLength(g_lTempOwners)){
        if (kId == g_kWearer){
            lMyButtons += "ESCAPE!";
        } else {
            lMyButtons += "Release";
        }
    } else {
        // check capture type and set appropriate radio buttons
        if (g_iCaptureMode == PERMANENT) lMyButtons += g_sPermCaptureOn; // permanent is the old default for capture
        else lMyButtons += g_sPermCaptureOff;
        
        if (g_iCaptureMode == ESCAPE_CHANCE) lMyButtons += g_sEscapeOn; // -1 indicates a 1% escape attempt per chance
        else lMyButtons += g_sEscapeOff;
        
        if (g_iCaptureMode == EASY_ESCAPE_CHANCE) lMyButtons += g_sEasyEscapeOn; // -10 indicates a ten percent escape chance per attempt
        else lMyButtons += g_sEasyEscapeOff;
        
        if (g_iCaptureMode == HOUR) lMyButtons += g_sOneHourOn; // 3600 is one hour in seconds
        else lMyButtons += g_sOneHourOff;
        
        if (g_iCaptureMode == DAY) lMyButtons += g_sOneDayOn; // 86400 is one day in seconds
        else lMyButtons += g_sOneDayOff;
        
        if (g_iCaptureMode == WEEK) lMyButtons += g_sOneWeekOn; // 604800 is one week in seconds
        else lMyButtons += g_sOneWeekOff;
        
        lMyButtons += ["level: "+(string)g_iNumberRequired]; // added a non-functional number button for menu clarity
        lMyButtons += g_sDecrease;
        lMyButtons += g_sIncrease;
        
        // Place the on/off button on bottom row left
        if (g_iCaptureOn){
            if (g_iRiskyOn) lMyButtons += g_sCaptureRisky;
                else lMyButtons += g_sCaptureActive;
        }
        else lMyButtons += g_sCaptureInactive;
        
        // add a button to allow the capture prompt every 15 minutes to be muted
        if (g_iIsChatty) lMyButtons += g_sChattyOn;
        else lMyButtons += g_sChattyOff;
        
    }
    if (llGetListLength(g_lTempOwners) > 0)
        sPrompt += "\n\nCaptureped by: "+NameURI(llList2Key(g_lTempOwners,0));
    Dialog(kId, sPrompt, lMyButtons, ["BACK"], 0, iAuth, "CaptureMenu", "", "");
}

saveTempOwners() {
    if (llGetListLength(g_lTempOwners)) {
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "auth_tempowner="+llDumpList2String(g_lTempOwners,","), "");
        llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, "auth_tempowner="+llDumpList2String(g_lTempOwners,","), "");
    } else {
        llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, "auth_tempowner=", "");
        llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "auth_tempowner", "");
        //llMessageLinked(LINK_SET, LM_SETTING_EMPTY, "auth_tempowner", "");
    }
}

doCapture(key kCaptor, string sCaptor, integer iIsConfirmed) {
    if (llGetListLength(g_lTempOwners)) {
        llMessageLinked(LINK_SET,NOTIFY,"0"+"%WEARERNAME% is already captured, try another time.",kCaptor);
        return;
    }
    if (llVecDist(llList2Vector(llGetObjectDetails( kCaptor,[OBJECT_POS] ),0),llGetPos()) > 10 ) { 
        llMessageLinked(LINK_SET,NOTIFY,"0"+"You could capture %WEARERNAME% if you get a bit closer.",kCaptor);
        return;
    }
    if (!iIsConfirmed) {
        Dialog(g_kWearer, "\nsecondlife:///app/agent/"+(string)kCaptor+"/about wants to capture you...", ["Allow","Reject"], ["BACK"], 0, CMD_WEARER, "AllowCaptureMenu", kCaptor, sCaptor);
    }
    else {
        llMessageLinked(LINK_SET, CMD_OWNER, "follow " + (string)kCaptor, kCaptor);
        llMessageLinked(LINK_SET, CMD_OWNER, "yank", kCaptor);
        llMessageLinked(LINK_SET, CMD_OWNER, "lock", kCaptor); // need to lock the collar on capture or capture is too easily escaped
        llMessageLinked(LINK_SET, NOTIFY, "0"+"You are at "+NameURI(kCaptor)+"'s whim.",g_kWearer);
        llMessageLinked(LINK_SET, NOTIFY, "0"+"%WEARERNAME% is at your mercy.\n\n/%CHANNEL%%PREFIX%menu\n/%CHANNEL%%PREFIX%pose\n/%CHANNEL%%PREFIX_restrictions\n/%CHANNEL%%PREFIX_sit\n/%CHANNEL%%PREFIX%help\n\nNOTE: During capture RP %WEARERNAME% cannot refuse your teleport offers and you will keep full control. To end the capture, please type: /%CHANNEL%%PREFIX%capture release\n\nHave fun!\n", kCaptor);
        g_lTempOwners+=[kCaptor,sCaptor];
        saveTempOwners();
        if (g_iCaptureMode > PERMANENT){ // 
            g_iStartingUnixTime = llGetUnixTime(); // set the start time if we have a timed release option set
            llMessageLinked(LINK_SET, NOTIFY, "0"+"Your capture will last until your timer runs out or you are released.",g_kWearer);
            llMessageLinked(LINK_SET, NOTIFY, "0"+"%WEARERNAME% has a capture timer running and will be released automatically once it expires. If you are around when this happens you can immediately recapture them by clicking their neck and using the capture menu again", kCaptor);
            llSetTimerEvent(FIFTEEN_MINUTES); // set the timer now to try to make the capture time as exact as possible   
        } else if (g_iCaptureMode < PERMANENT){
            llMessageLinked(LINK_SET, NOTIFY, "0"+"Your capture will last until you manage to escape by clicking the capture button to struggle at the right times (you need 5 successful struggles to escape) or"+NameURI(kCaptor)+" chooses to release you.",g_kWearer);
            llMessageLinked(LINK_SET, NOTIFY, "0"+"%WEARERNAME% likes to struggle and will be able to make an escape attempt from time to time. If they get loose and you are around you can immediately recapture them by clicking their neck and using the capture menu again. You can also use the menu to resecure them.", kCaptor);
            llSetTimerEvent(FIFTEEN_MINUTES); // set the timer now to prevent excape in the first fifteen minutes 
            g_iEscapeAttemptNow = FALSE; // ensure that immediate escape is not an option
            g_iEscapesSoFar = 0; // reset the escape counter
        } else {
            llMessageLinked(LINK_SET, NOTIFY, "0"+"Your capture is permanent until "+NameURI(kCaptor)+" chooses to release you.",g_kWearer);
            //llSetTimerEvent(0.0); 
        }
    }
}

DoEscapeAttempt() {
    llOwnerSay("Escape attempt = " +(string)g_iEscapeAttemptNow );
    if (g_iEscapeAttemptNow == TRUE){
        float f_fRandomNumber = llFrand(-100.00);
        llOwnerSay("f_fRandomNumber  = " +(string)f_fRandomNumber );
        if (f_fRandomNumber > (float) g_iCaptureMode) { // this will only ever be true for capture modes and then only 1% or 10% of the time
            llMessageLinked(LINK_SET,SAY,"1"+"%WEARERNAME% makes some progress in their escape attempt!They can try to build on this partial success in fifteen minutes.","");
            g_iEscapesSoFar += 1;
                        llSetTimerEvent(FIFTEEN_MINUTES); // restart a timer
        }
        else {
            llMessageLinked(LINK_SET,SAY,"1"+"%WEARERNAME% struggles, trying to escape their capture but is unsuccessful. They can try again in fifteen minutes.","");
            g_iEscapeAttemptNow = FALSE; // prevents a second attempt until the timer triggers
            llSetTimerEvent(FIFTEEN_MINUTES); // restart a timer
        }
    }
    else
    {
        llMessageLinked(LINK_SET,SAY,"1"+"%WEARERNAME% struggles weakly with no possibility of escape. They now need to wait fifteen minutes to have any chance of success.","");
        g_iEscapeAttemptNow = FALSE; // prevents a second attempt until the timer triggers
        llSetTimerEvent(FIFTEEN_MINUTES); // as we are cruel  reset the timer to fifteen minutes here. Button spammers will never escape! :-)
        // g_iEscapesSoFar = 0; SUPER harsh option resetting all current escape progress for escapees!
    }
    if (g_iEscapesSoFar >= g_iNumberRequired)
    {
            llMessageLinked(LINK_SET,SAY,"1"+"%WEARERNAME% has managed to escape their captor!","");
            g_lTempOwners=[];
            saveTempOwners();
            g_iEscapesSoFar = 0; // reset the escape attempt trigger
            g_iEscapeAttemptNow = FALSE; // reset for next capture - wearers cannot escape until the timer triggers after capture
            llSetTimerEvent(FIFTEEN_MINUTES);  // restart a timer as capture mode is still active
    }
}

DoRelease()
{
    g_lTempOwners=[];
    saveTempOwners();
    g_iEscapesSoFar = 0;
    llMessageLinked(LINK_SET,NOTIFY,"0"+"You are released from your capture as the allotted time has elapsed, Beware, you are immediately eligible for capture again!",g_kWearer);
    llSetTimerEvent (FIFTEEN_MINUTES);
}

UserCommand(integer iNum, string sStr, key kID, integer remenu) {
    string sStrLower=llToLower(sStr);
    if (llSubStringIndex(sStr,"capture TempOwner") == 0){
        list lSplit = llParseString2List(sStr, ["~"], []);
        key kCaptor=(key)llList2String(lSplit,2);
        string sCaptor=llList2String(lSplit,1);
        if (iNum==CMD_OWNER || iNum==CMD_TRUSTED || iNum==CMD_GROUP) { //do nothing, owners get their own menu but cannot capture
        }
        else Dialog(kID, "\nYou can try to capture %WEARERNAME%.\n\nReady for that?", ["Yes","No"], [], 0, iNum, "ConfirmCaptureMenu", kCaptor, sCaptor);
    }
    else if (sStrLower == "capture" || sStrLower == "menu capture") {
        if  (iNum!=CMD_OWNER && iNum != CMD_WEARER) {
            if (g_iCaptureOn) Dialog(kID, "\nYou can try to capture %WEARERNAME%.\n\nReady for that?", ["Yes","No"], [], 0, iNum, "ConfirmCaptureMenu", kID, llKey2Name(kID));
            else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);//Notify(kID,g_sAuthError, FALSE);
        } else CaptureMenu(kID, iNum); // an authorized user requested the plugin menu by typing the menus chat command
    }
    else if (iNum!=CMD_OWNER && iNum != CMD_WEARER){
        //silent fail, no need to do anything more in this case
    }
    else if (llSubStringIndex(sStrLower,"capture")==0) {
        if (llGetListLength(g_lTempOwners)>0 && kID==g_kWearer) {
            // if captured in escape mode the wearer can press the ESCAPE! button to try to escape
            if (g_iCaptureMode < PERMANENT){
                DoEscapeAttempt();
            }
            // and if they are in timed mode we let them know  that they will be released eventually
            else if (g_iCaptureMode > PERMANENT){
                llMessageLinked(LINK_SET,NOTIFY,"0"+"You will be released when your capture time expires.",g_kWearer);
            }
            // if captured in permanent mode the wearer is locked out of this menu
            else {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"You have been captured permanently, escape is not possible, you would have to use runaway",g_kWearer);
            }
            return;
        } else if (sStrLower == "capture off") {
            llMessageLinked(LINK_SET,NOTIFY,"1"+"Capture Mode is OFF",kID);
            if (g_iIsChatty) llMessageLinked(LINK_SET,NOTIFY,"0"+"You are no longer vulnerable to capture.",g_kWearer);
            g_lTempOwners=[]; // clear out the capture list
            saveTempOwners();
            llSetTimerEvent(0.0);
            g_iCaptureOn=FALSE;
            g_iRiskyOn = FALSE; //these are on one toggle now so when capture is switched off so is risk
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE,g_sSettingToken+"capture", "");
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE,g_sSettingToken+"vulnerable", "");
        } else if (sStrLower == "capture ask") {
            llMessageLinked(LINK_SET,NOTIFY,"1"+"Capture Mode is now ASK",kID);
            if (g_iIsChatty) llMessageLinked(LINK_SET,NOTIFY,"0"+"You are vulnerable to capture.",g_kWearer);
            if (g_iIsChatty) llMessageLinked(LINK_SET,SAY,"1"+"%WEARERNAME%: You can capture me if you touch my neck...","");
            llSetTimerEvent(FIFTEEN_MINUTES);  // set the timer anyway in case they change their discretion settings
            g_iCaptureOn=TRUE;
            g_iRiskyOn = FALSE; //these are on one toggle now so when capture is switched on, risk is off
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"capture=1", "");
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE,g_sSettingToken+"vulnerable", "");
        } else if (sStrLower == "capture risky") {
            llMessageLinked(LINK_SET,NOTIFY,"1"+"Capture Mode is now RISKY",kID);
            if (g_iIsChatty) llMessageLinked(LINK_SET,NOTIFY,"0"+"You are vulnerable to capture.",g_kWearer);
            if (g_iIsChatty) llMessageLinked(LINK_SET,SAY,"1"+"%WEARERNAME%: You can capture me if you touch my neck...","");
            llSetTimerEvent(FIFTEEN_MINUTES);
            g_iCaptureOn=TRUE;
            g_iRiskyOn = TRUE;
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"vulnerable=1", "");
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"capture=1", "");
        } else if (sStrLower == "capture release") {
            llMessageLinked(LINK_SET, CMD_OWNER, "unfollow", kID);
            llMessageLinked(LINK_SET,NOTIFY,"0"+NameURI(kID)+" has released you.",g_kWearer);
            llMessageLinked(LINK_SET,NOTIFY,"0"+"You have released %WEARERNAME%.",kID);
            g_lTempOwners=[];
            saveTempOwners();
            llSetTimerEvent(0.0);
            return;  //no remenu in case of release  
        } else if ((sStrLower == "capture chatty off")){
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"chatty_mode=0", "");
            g_iIsChatty = FALSE;
            llMessageLinked(LINK_SET,NOTIFY,"1"+"The capture module is now less chatty. Only important announcements will be made. Vulnerability to capture will not be publically announced.",kID);
        } else if ((sStrLower == "capture chatty on")){
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"chatty_mode=1", "");
            g_iIsChatty = TRUE;
            llMessageLinked(LINK_SET,NOTIFY,"1"+"The capture module is now chatty. All announcements will be made. Vulnerability to capture will be announced every 15 minutes.",kID);
        // added processing for different capture modes here
        // only "empty dot" responses need processing as this is a radio button setup, but we process filled dots to inform people of their rules when touched
        } else if ((sStrLower == "capture " + g_sPermCaptureOff) || (sStrLower == "capture " + g_sPermCaptureOn)){
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"capture_mode"+(string)ESCAPE_CHANCE, "");
            g_iCaptureMode = 0;
            llMessageLinked(LINK_SET,NOTIFY,"1"+"Captivity will be permanent until released by the captor.",kID);
        } else if ((sStrLower == "capture " + g_sEscapeOff) || (sStrLower == "capture " + g_sEscapeOn)) {
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"capture_mode="+(string)ESCAPE_CHANCE, "");
            g_iCaptureMode = ESCAPE_CHANCE;
            llMessageLinked(LINK_SET,NOTIFY,"1"+"Captivity escape attempts may be made with a five percent chance every fifteen minutes if the wearer presses the capture button. The wearer requires "+ (string)g_iNumberRequired +" successful attempts to escape.",kID);
        } else if ((sStrLower == "capture " + g_sEasyEscapeOff) || (sStrLower == "capture " + g_sEasyEscapeOn)){
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"capture_mode="+(string)EASY_ESCAPE_CHANCE, "");
            g_iCaptureMode = EASY_ESCAPE_CHANCE;
            llMessageLinked(LINK_SET,NOTIFY,"1"+"Captivity escape attempts may be made with a twenty percent chance every fifteen minutes if the wearer presses the capture button. The wearer requires "+ (string)g_iNumberRequired +" successful attempts to escape.",kID);
        } else if ((sStrLower == "capture " + g_sOneHourOff) || (sStrLower == "capture " + g_sOneHourOn)){
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"capture_mode="+(string)HOUR, "");
            g_iCaptureMode = HOUR;
            llMessageLinked(LINK_SET,NOTIFY,"1"+"Captivity will last for around "+ (string)g_iNumberRequired +" RL hours.",kID);
        } else if ((sStrLower == "capture " + g_sOneDayOff) || (sStrLower == "capture " + g_sOneDayOn)){
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"capture_mode="+(string)DAY, "");
            g_iCaptureMode = DAY;
            llMessageLinked(LINK_SET,NOTIFY,"1"+"Captivity will last for around "+ (string)g_iNumberRequired +" RL days.",kID);
        } else if ((sStrLower == "capture " + g_sOneWeekOff) || (sStrLower == "capture " + g_sOneWeekOn)){
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"capture_mode="+(string)WEEK, "");
            g_iCaptureMode = WEEK;
            llMessageLinked(LINK_SET,NOTIFY,"1"+"Captivity will last for around "+ (string)g_iNumberRequired +" RL weeks.",kID);
        } else if (sStrLower == "capture " + g_sIncrease){
            g_iNumberRequired += 1; //increment
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"number_required="+(string)g_iNumberRequired, "");
            llMessageLinked(LINK_SET,NOTIFY,"1"+"Level is now: "+ (string)g_iNumberRequired + ".",kID);
        } else if (sStrLower == "capture " + g_sDecrease){
            g_iNumberRequired -= 1; //decrement
            if (g_iNumberRequired <=0) g_iNumberRequired =1;// but do not allow to drop below 1
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"number_required="+(string)g_iNumberRequired, "");
            llMessageLinked(LINK_SET,NOTIFY,"1"+"Level is now: "+ (string)g_iNumberRequired + ".",kID);
        }
        if (remenu) CaptureMenu(kID, iNum);
    }
}

default{

    state_entry() {
        llSetMemoryLimit(32768); //2015-05-06 (4840 bytes free)
        g_kWearer = llGetOwner();
        llSetTimerEvent(FIFTEEN_MINUTES); // to prevent accidental trapping in timed capture modes the timer always runs
        //Debug("Starting");
    }

    on_rez(integer iParam) {
        if (llGetOwner()!=g_kWearer)  llResetScript();
        llSetTimerEvent(FIFTEEN_MINUTES); // to prevent accidental trapping in timed capture modes the timer always runs
    }

    touch_start(integer num_detected) {
        key kToucher = llDetectedKey(0);
        if (kToucher == g_kWearer) return;  //wearer can't capture
        if (~llListFindList(g_lTempOwners,[(string)kToucher])) return;  //temp owners can't capture
        if (llGetListLength(g_lTempOwners)) return;  //no one can capture if already captured
        if (!g_iCaptureOn) return;  //no one can capture if disabled
        if (llVecDist(llDetectedPos(0),llGetPos()) > 10 ) llMessageLinked(LINK_SET,NOTIFY,"0"+"You could capture %WEARERNAME% if you get a bit closer.",kToucher);
        else llMessageLinked(LINK_SET,0,"capture TempOwner~"+llDetectedName(0)+"~"+(string)kToucher,kToucher);
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == "Main") llMessageLinked(iSender, MENUNAME_RESPONSE, "Main|Capture", "");
        else if (iNum == CMD_SAFEWORD || (sStr == "runaway" && iNum == CMD_OWNER)) {
            if (iNum == CMD_SAFEWORD && g_iCaptureOn) llMessageLinked(LINK_SET,NOTIFY,"0"+"Capture Mode deactivated.", g_kWearer);
            if (llGetListLength(g_lTempOwners)) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Your capture role play with %WEARERNAME% is over.",llList2Key(g_lTempOwners,0));
            g_iCaptureOn=FALSE;
            g_iRiskyOn = FALSE;
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE,g_sSettingToken+"capture", "");
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE,g_sSettingToken+"vulnerable", "");
            g_lTempOwners=[];
            saveTempOwners();
            llSetTimerEvent(0.0);
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == g_sSettingToken+"capture") g_iCaptureOn = (integer)sValue;  // check if any values for use are received
            else if (sToken == g_sSettingToken+"vulnerable") g_iRiskyOn = (integer)sValue;
            else if (sToken == "auth_tempowner") g_lTempOwners = llParseString2List(sValue, [","], []); //store tempowners list
            else if (sToken == g_sSettingToken+"capture_mode") g_iCaptureMode = (integer)sValue; // store current capture mode of the capture addon
            else if (sToken == g_sSettingToken+"chatty_mode") g_iIsChatty= (integer)sValue; // store current chatty setting of the capture addon            
            else if (sToken == g_sSettingToken+"number_required") g_iNumberRequired= (integer)sValue; // store current level setting of the capture addon         
        } else if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID, FALSE);
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = llList2Integer(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex+1);
                key kCaptor=llList2Key(g_lMenuIDs, iMenuIndex + 2);
                string sCaptor=llList2String(g_lMenuIDs, iMenuIndex + 3);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
                if (sMenu=="CaptureMenu") {
                    if (sMessage == "BACK") llMessageLinked(LINK_THIS, iAuth, "menu Main", kAv);
                    else if (sMessage == g_sChattyOn) UserCommand(iAuth,"capture chatty off",kAv,TRUE);
                    else if (sMessage == g_sChattyOff) UserCommand(iAuth,"capture chatty on",kAv,TRUE);
                    else if (sMessage == g_sCaptureInactive) UserCommand(iAuth,"capture ask",kAv,TRUE);
                    else if (sMessage == g_sCaptureActive) UserCommand(iAuth,"capture risky",kAv,TRUE);
                    else if (sMessage == g_sCaptureRisky) UserCommand(iAuth,"capture off",kAv,TRUE);
                    else UserCommand(iAuth,"capture "+sMessage,kAv,TRUE);
                } else if (sMenu=="AllowCaptureMenu") {  //wearer must confirm when forced is off
                    if (sMessage == "BACK") llMessageLinked(LINK_THIS, iAuth, "menu capture", kAv);
                    else if (sMessage == "Allow") doCapture(kCaptor, sCaptor, TRUE);
                    else if (sMessage == "Reject") {
                        llMessageLinked(LINK_SET,NOTIFY,"0"+NameURI(kCaptor)+" didn't manage to capture you this time.",kAv);
                        llMessageLinked(LINK_SET,NOTIFY,"0"+"Looks like %WEARERNAME% managed to avoid your capture attempt.",kCaptor);
                    }
                } else if (sMenu=="ConfirmCaptureMenu") {  //captor must confirm when forced is on
                    if (sMessage == "BACK") llMessageLinked(LINK_THIS, iAuth, "menu capture", kAv);
                    else if (g_iCaptureOn) {  //in case app was switched off in the mean time
                        if (sMessage == "Yes") doCapture(kCaptor, sCaptor, g_iRiskyOn);
                        else if (sMessage == "No") llMessageLinked(LINK_SET,NOTIFY,"0"+"You let %WEARERNAME% be.",kAv);
                    } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%WEARERNAME% can no longer be captured",kAv);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        }
    }

    timer() {
        //llOwnerSay("g_iStartingUnixTime = " + (string) g_iStartingUnixTime); //TEST MODE reporting code
        //llOwnerSay("Current Unix Time = " + (string) llGetUnixTime());
        //llOwnerSay("Projected release time = " + (string) (g_iStartingUnixTime + g_iCaptureMode)); 
        if (llGetListLength(g_lTempOwners) == 0) {
            if (g_iIsChatty) llMessageLinked(LINK_SET,SAY,"1"+"%WEARERNAME%: You can capture me if you touch my neck...","");
        } else {
            if (g_iCaptureMode > 0){ // check if the timer has run out and if so release the wearer
                integer f_iCurrentUnixTime = llGetUnixTime();
                if (f_iCurrentUnixTime > g_iStartingUnixTime + (g_iCaptureMode * g_iNumberRequired)){
                    DoRelease();
                }
            } else if (g_iCaptureMode < 0){ // notify the wearer that they can make another escape attempt now
                if (g_iEscapeAttemptNow == TRUE){ // Don't just leave the escape window open, make them work :-)
                    llMessageLinked(LINK_SET,NOTIFY,"0"+"You missed your chance to escape and will have to wait fifteen minutes, struggling now will be counterproductive",g_kWearer);
                    g_iEscapeAttemptNow = FALSE;
                } else if (g_iEscapeAttemptNow == FALSE) { // but if they could not escape earlier, give them a chance
                    llMessageLinked(LINK_SET,NOTIFY,"0"+"You may make an escape to attempt to escape at any point in the next fifteen minutes",g_kWearer);
                    g_iEscapeAttemptNow = TRUE;
                }
            }
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_TELEPORT) {
            if (llGetListLength(g_lTempOwners) == 0) {
                if (g_iRiskyOn && g_iCaptureOn) { 
                    if (g_iIsChatty) { // announce status on arrival if chatty
                        llMessageLinked(LINK_SET,SAY,"1"+"%WEARERNAME%: You can capture me if you touch my neck...","");
                    }  
                llSetTimerEvent(FIFTEEN_MINUTES); // set the timer anyway in case they change their chatty setting
                }
            }
        }
        /*if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }*/
    }
}
