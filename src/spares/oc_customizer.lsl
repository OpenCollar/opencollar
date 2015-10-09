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
//                        Customizer - 150924.1                             //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2014 - 2015 Romka Swallowtail                             //
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

string g_sParentMenu = "Apps";
string g_sSubMenu = "Customizer";

//MESSAGE MAP
integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_SECOWNER = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;


integer NOTIFY = 1002;
//integer SAY = 1004;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer LINK_DIALOG = 3;
integer LINK_SAVE = 5;

string UPMENU = "BACK";
string SAVE = "SAVE";
string REMOVE = "REMOVE";
string RESET = "RESET";

key g_kWearer;

list g_lElementsList;
list g_lParams;

string g_sCurrentElement ;
list g_lCurrentParam ;

list g_lMenuIDs;//3-strided list of kAv, dialogid, menuname
integer g_iMenuStride = 3;

integer g_iTexture = FALSE;
integer g_iColor = FALSE;
integer g_iShiny = FALSE;
integer g_iGlow = FALSE;
integer g_iHide = FALSE;


/*
integer g_iProfiled=TRUE;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}
*/

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sMenuType)
{
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iMenuIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    list lAddMe = [kRCPT, kMenuID, sMenuType];
    if (iMenuIndex == -1) g_lMenuIDs += lAddMe;
    else g_lMenuIDs = llListReplaceList(g_lMenuIDs, lAddMe, iMenuIndex, iMenuIndex + g_iMenuStride - 1);
}

ElementMenu(key kAv, integer iPage, integer iAuth)
{
    BuildElementsList();
    string sPrompt = "\nChange the Elements descriptions, %DEVICETYPE%.\nSelect an element from the list";
    Dialog(kAv, sPrompt, llListSort(g_lElementsList, 1, TRUE), [REMOVE,RESET,UPMENU], iPage, iAuth, "ElementMenu");
}

CustomMenu(key kAv, integer iPage, integer iAuth)
{
    string sPrompt = "\nSelect an option for element '"+g_sCurrentElement+"':";
    sPrompt += "\n" + llDumpList2String(g_lCurrentParam, "~");
    list lButtons;
    if (g_iTexture) lButtons += ["▣ texture"];
    else lButtons += ["☐ texture"];
    if (g_iColor) lButtons += ["▣ color"];
    else lButtons += ["☐ color"];
    if (g_iHide) lButtons += ["▣ hide"];
    else lButtons += ["☐ hide"];
    if (g_iShiny) lButtons += ["▣ shine"];
    else lButtons +=  ["☐ shine"];
    if (g_iGlow) lButtons += ["▣ glow"];
    else lButtons += ["☐ glow"];
    Dialog(kAv, sPrompt, lButtons, [SAVE, UPMENU], iPage, iAuth, "CustomMenu");
}

GetParam(list params)
{
    if ( ~llListFindList(params,["texture"]) ) g_iTexture = TRUE;
    //else if ( !~llListFindList(params,["notexture"]) ) g_iTexture = TRUE;
    else g_iTexture = FALSE;

    if ( ~llListFindList(params,["color"]) ) g_iColor = TRUE;
    //else if ( !~llListFindList(params,["nocolor"]) ) g_iColor = TRUE;
    else g_iColor = FALSE;

    if ( ~llListFindList(params,["shiny"]) ) g_iShiny = TRUE;
    //else if ( !~llListFindList(params,["noshiny"]) ) g_iShiny = TRUE;
    else g_iShiny = FALSE;

    if ( ~llListFindList(params,["glow"]) ) g_iGlow = TRUE;
    //else if ( !~llListFindList(params,["noglow"]) ) g_iGlow = TRUE;
    else g_iGlow = FALSE;

    if ( ~llListFindList(params,["hide"]) ) g_iHide = TRUE;
    //else if ( !~llListFindList(params,["nohide"]) ) g_iHide = TRUE;
    else g_iHide = FALSE;
}

string ChangeParam(list params)
{
    integer index ;

    index = llListFindList(params,["notexture"]);
    if (index !=-1) params = llDeleteSubList(params,index,index);

    index = llListFindList(params,["nocolor"]);
    if (index !=-1) params = llDeleteSubList(params,index,index);

    index = llListFindList(params,["noshiny"]);
    if (index !=-1) params = llDeleteSubList(params,index,index);

    index = llListFindList(params,["noglow"]);
    if (index !=-1) params = llDeleteSubList(params,index,index);

    index = llListFindList(params,["nohide"]);
    if (index !=-1) params = llDeleteSubList(params,index,index);

    index = llListFindList(params,["texture"]);
    if (g_iTexture && index==-1) params += ["texture"];
    else if (!g_iTexture && index!=-1) params = llDeleteSubList(params,index,index);

    index = llListFindList(params,["color"]);
    if (g_iColor && index==-1) params += ["color"];
    else if (!g_iColor && index!=-1) params = llDeleteSubList(params,index,index);

    index = llListFindList(params,["shiny"]);
    if (g_iShiny && index==-1) params = llDeleteSubList(params,index,index);
    else if (!g_iShiny && index!=-1) params += ["shiny"];

    index = llListFindList(params,["glow"]);
    if (g_iGlow && index==-1) params = llDeleteSubList(params,index,index);
    else if (!g_iGlow && index!=-1) params += ["glow"];

    index = llListFindList(params,["hide"]);
    if (g_iHide && index==-1) params = llDeleteSubList(params,index,index);
    else if (!g_iHide && index!=-1) params += ["hide"];

    return llDumpList2String(params,"~");
}

SaveCurrentParam(string sElement)
{
    integer i = llGetNumberOfPrims();
    do
    {
        string description = llStringTrim(llList2String(llGetLinkPrimitiveParams(i,[PRIM_DESC]),0),STRING_TRIM);
        list lParts = llParseStringKeepNulls(description,["~"],[]);
        if (llList2String(lParts,0)==sElement) llSetLinkPrimitiveParamsFast(i,[PRIM_DESC,ChangeParam(lParts)]);
    } while (i-- > 2) ;
}

ResetScripts()
{
    if (llGetInventoryType("oc_disgraced_themes") == INVENTORY_SCRIPT) llResetOtherScript("oc_disgraced_themes");
}

BuildElementsList()
{
    g_lElementsList = [];
    g_lParams = [];
    integer count = llGetNumberOfPrims();
    do
    {
        string description = llStringTrim(llList2String(llGetLinkPrimitiveParams(count,[PRIM_DESC]),0),STRING_TRIM);
        list lParts = llParseStringKeepNulls(description,["~"],[]);
        string element = llList2String(lParts,0);
        if (description != "" && description != "(No Description)")
        {
            if (!~llListFindList(g_lElementsList,[element]))
            {
                g_lElementsList += [element];
                g_lParams += llDumpList2String(llDeleteSubList(lParts,0,0), "~");
            }
        }
    } while (count-- > 2) ;
}

UserCommand(integer iAuth, string sStr, key kID)
{
    if (iAuth > CMD_WEARER || iAuth < CMD_OWNER) return ; // sanity check

    if (sStr == "menu " + g_sSubMenu)
    {
        if (kID!=g_kWearer && iAuth!=CMD_OWNER)
        {
            llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"%NOACCESS%",kID);
            llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sParentMenu, kID);
        }
        else ElementMenu(kID, 0, iAuth);
    }
}

default
{
    state_entry()
    {
        g_kWearer = llGetOwner();
        BuildElementsList();
        //Debug("FreeMem: " + (string)llGetFreeMemory());
    }

    on_rez(integer iParam)
    {
        llResetScript();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum <= CMD_WEARER && iNum >= CMD_OWNER) UserCommand(iNum, sStr, kID);
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1)
            {
                //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

                if (sMenuType == "ElementMenu")
                {
                    if (sMessage == UPMENU)
                    {
                        llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sParentMenu, kAv);
                    }
                    else if (sMessage == RESET)
                    {
                        ResetScripts();
                        llMessageLinked(LINK_SAVE, iAuth, "load", kID);
                        g_sCurrentElement = "";
                        ElementMenu(kAv, iPage, iAuth);
                    }
                    else if (sMessage == REMOVE)
                    {
                        ResetScripts();
                        llMessageLinked(LINK_ROOT, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sParentMenu, kAv);
                        llRemoveInventory(llGetScriptName());
                    }
                    else if (~llListFindList(g_lElementsList, [sMessage]))
                    {
                        g_sCurrentElement = sMessage;
                        integer i = llListFindList(g_lElementsList,[g_sCurrentElement]);
                        g_lCurrentParam = llParseStringKeepNulls(llList2String(g_lParams ,i),["~"],[]);
                        GetParam(g_lCurrentParam);
                        CustomMenu(kAv, iPage, iAuth);
                    }
                    else
                    {
                        g_sCurrentElement = "";
                        ElementMenu(kAv, iPage, iAuth);
                    }
                }
                else if (sMenuType == "CustomMenu")
                {
                    if (sMessage == UPMENU) ElementMenu(kAv, iPage, iAuth);
                    else if (sMessage == SAVE)
                    {
                        SaveCurrentParam(g_sCurrentElement);
                        g_sCurrentElement = "";
                        g_lCurrentParam = [];
                        ElementMenu(kAv, iPage, iAuth);
                    }
                    else
                    {
                        if (sMessage == "☐ texture") g_iTexture = TRUE;
                        else if (sMessage == "▣ texture") g_iTexture = FALSE;
                        else if (sMessage == "☐ color") g_iColor = TRUE;
                        else if (sMessage == "▣ color") g_iColor = FALSE;
                        else if (sMessage == "☐ hide") g_iHide = TRUE;
                        else if (sMessage == "▣ hide") g_iHide = FALSE;
                        else if (sMessage == "☐ shine") g_iShiny = TRUE;
                        else if (sMessage == "▣ shine") g_iShiny = FALSE;
                        else if (sMessage == "☐ glow") g_iGlow = TRUE;
                        else if (sMessage == "▣ glow") g_iGlow = FALSE;
                        CustomMenu(kAv, iPage, iAuth);
                    }
                }
            }
        }
        else if (iNum == DIALOG_TIMEOUT)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1)
            {
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
            }
        }
    }

    changed(integer iChange)
    {
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_LINK) BuildElementsList();
/*
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled) {
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/
    }
}
