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
//       Remote Options - 151231.1       .*' /  .*' ; .*`- +'  `*'          //
//                                       `*-*   `*-*  `*-*'                 //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2014 - 2015 Nandana Singh, Jessenia Mocha, Alexei Maven,  //
//  Master Starship, Wendy Starfall, North Glenwalker, Ray Zopf, Sumi Perl, //
//  Kire Faulkes, Zinn Ixtar, Builder's Brewery, Romka Swallowtail et al.   //
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
//         github.com/OpenCollar/opencollar/tree/master/src/remote          //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

//Adjusted to OpenCollar name convention und format standards June 2015 Otto (garvin.twine)

integer CMD_TOUCH         = 100;
integer MENUNAME_REQUEST  = 3000;
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU           = 3002;
integer DIALOG            = -9000;
integer DIALOG_RESPONSE   = -9001;
integer DIALOG_TIMEOUT    = -9002;

string UPMENU     = "BACK";
string g_sParentMenu = "Main";
string g_sHudMenu    = "HUD Style";
string g_sSubMenu1   = "Buttons";
string g_sSubMenu2   = "Order";
string g_sSubMenu3   = "Tint";
string g_sCurrentMenu;

key g_kMenuID;

key Dialog(key kRcpt, string sPrompt, list lChoices, list lUtilityButtons, integer iPage) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRcpt + "|" + sPrompt + "|" + (string)iPage +
 "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`"), kID);
    return kID;
}

list g_lAttachPoints = [
    ATTACH_HUD_TOP_RIGHT,
    ATTACH_HUD_TOP_CENTER,
    ATTACH_HUD_TOP_LEFT,
    ATTACH_HUD_BOTTOM_RIGHT,
    ATTACH_HUD_BOTTOM,
    ATTACH_HUD_BOTTOM_LEFT,
    ATTACH_HUD_CENTER_1,
    ATTACH_HUD_CENTER_2
    ];

list g_lPrimOrder = [0, 1, 2, 5, 4, 3, 6];
//  List must always start with '0','1'
//  0:Spacer, 1:Root, 2:Menu, 3:Beckon, 4:Bookmarks, 5:Couples, 6:Leash
//  Spacer serves to even up the list with actual link numbers

integer g_iLayout;
integer g_iHidden;
integer g_iSPosition = 69; // Nuff'said =D
integer g_iOldPos;
integer g_iNewPos;
integer g_iTintable = FALSE;

PlaceTheButton(float fYoff, float fZoff) {
    integer i = 2;
    for (; i <= llGetListLength(g_lPrimOrder); ++i)
        llSetLinkPrimitiveParamsFast(llList2Integer(g_lPrimOrder,i), [PRIM_POSITION, <0.0, fYoff * (i - 1), fZoff * (i - 1)>]);
}

DoButtons(string sStyle) {
//  Texture Settings by Jessenia Mocha
//  Texture UUID's [ Root, Menu, Teleport, Cage, Couples, Leash ]
    list lLightTex=["b59f9932-5de4-fc23-b5aa-2ab46d22c9a6","52c3f4cf-e87e-dbdd-cf18-b2c4f6002a96","50f5c540-d0bb-00b0-ce6c-23eb7b70bfa4","1ac086de-3201-e526-e986-2e67d9de9202","38f0da26-b51c-477f-9071-bea17a6a3dac","752f586b-a110-b951-4c9e-23beb0f97d2f"];

    list lDarkTex=["e1482c7e-8609-fcb0-56d8-18c3c94d21c0","f3ec1052-6ec4-04ba-d752-937a4d837bf8","c3343ece-30ae-5168-0cc2-b89f670b6826","193208ce-18e5-45f2-19ed-0ea1cbbf46ca","17fc7b38-9d1e-3646-956d-85ed96a977d9","b0c44ba4-ec7f-8cc6-7c26-44efa4bcd89c"];

//  Upon a texture change we should also reset the 'tint'
    llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_COLOR, ALL_SIDES, <1, 1, 1>, 1.0]);
//  If we don't select "White" as the style, remove g_iTintable flag
    if (sStyle != "White") g_iTintable = FALSE;
    integer iPrimNum = 5;
    integer i = 0;
    if (sStyle == "Light") {
        do llSetLinkPrimitiveParamsFast(i+1,[PRIM_TEXTURE, ALL_SIDES, llList2String(lLightTex,i), <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0]);
        while((++i)<=iPrimNum);
    } else if (sStyle == "Dark") {
        do llSetLinkPrimitiveParamsFast(i+1,[PRIM_TEXTURE, ALL_SIDES, llList2String(lDarkTex,i), <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0]);
        while((++i)<=iPrimNum);
    }
}

DoHide() {
//  This moves the child prims under the root prim to hide them
    llSetLinkPrimitiveParamsFast(LINK_ALL_OTHERS, [PRIM_POSITION, <1.0, 0.0, 0.0>]);
}

DefinePosition() {
    integer iPosition = llListFindList(g_lAttachPoints, [llGetAttached()]);
//  Allows manual repositioning, without resetting it, if needed
    if (iPosition != g_iSPosition) {
        // Set up the six root prim locations which all other posistions are based from
       /* list lRootOffsets = [
            <0.0,  0.02, -0.04>,    // Top right        (Position 0)
            <0.0,  0.00, -0.04>,    // Top middle       (Position 1)
            <0.0, -0.02, -0.04>,    // Top left         (Position 2)
            <0.0,  0.02,  0.10>,    // Bottom right     (Position 3)
            <0.0,  0.00,  0.07>,    // Bottom middle    (Position 4)
            <0.0, -0.02,  0.07>];   // Bottom left      (Position 5)*/
        //llSetPos((vector)llList2String(RootOffsets, Position)); // Position the Root Prim on screen
        g_iSPosition = iPosition;
    }
    if (!g_iHidden) { // -- Fixes Issue 615: HUD forgets hide setting on relog.
        float fYoff = 0.054; float fZoff = 0.054; // This is the space between buttons
        if (g_iLayout == 0 || iPosition == 1 || iPosition == 4) {// Horizontal + top and bottom are always horizontal
            if (iPosition == 2 || iPosition == 5) // Left side needs to push buttons right
                fYoff = fYoff * -1;
            fZoff = 0.0;
        } else {// Vertical
            if (iPosition == 0 || iPosition == 2)  // Top needs push buttons down
                fZoff = fZoff * -1;
            fYoff = 0.0;
        }
        PlaceTheButton(fYoff, fZoff); // Does the actual placement
    }
}

DoButtonOrder() {   // -- Set the button order and reset display
    integer iOldPos = llList2Integer(g_lPrimOrder,g_iOldPos);
    integer iNewPos = llList2Integer(g_lPrimOrder,g_iNewPos);
    integer i = 2;
    list lTemp = [0,1];
    for(;i<llGetListLength(g_lPrimOrder);++i) {
        integer iTempPos = llList2Integer(g_lPrimOrder,i);
        if (iTempPos == iOldPos)
            lTemp += [iNewPos];
        else if (iTempPos == iNewPos)
            lTemp += [iOldPos];
        else
            lTemp += [iTempPos];
    }
    g_lPrimOrder = [];
    g_lPrimOrder = lTemp;
    g_iOldPos = -1;
    g_iNewPos = -1;

    DefinePosition();
}

DoReset() {   // -- Reset the entire HUD back to default
    integer i = llGetInventoryNumber(INVENTORY_SCRIPT) -1;
    string sScript;
    do {
        sScript = llGetInventoryName(INVENTORY_SCRIPT,i);
        if (sScript != llGetScriptName() && sScript != "")
            llResetOtherScript(sScript);
    } while (--i > 0);
    g_iLayout = 0;
    g_iSPosition = 69; // -- Don't we just love that position? *winks*
    g_iTintable = FALSE;
    g_iHidden = FALSE;
    DoButtons("Dark");
    llSleep(2.0);
    g_lPrimOrder = [0, 1, 2, 5, 4, 3, 6];
    DoHide();
    llSleep(1.0);
    DefinePosition();
    llSleep(2.0); // -- We want the position to be set before reset
    llOwnerSay("Finalizing HUD Reset... please wait a few seconds so all menus have time to initialize.");
    llResetScript();
}

default
{
    state_entry() {
        //llSleep(1.0);
        //llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sHudMenu, "");
    }

    attach(key kAttached) {
        integer iAttachPoint = llGetAttached();
//      if being detached
        if (kAttached == NULL_KEY)
            return;
        else if (iAttachPoint < 31 || iAttachPoint > 38) {//http://wiki.secondlife.com/wiki/LlAttachToAvatar attach point integer values - 31-38 are hud placements
            llOwnerSay("Sorry, this device can only be placed on the HUD. Attach code: " + (string)iAttachPoint);
            llRequestPermissions(kAttached, PERMISSION_ATTACH);
            llDetachFromAvatar();
            return;
        }
        else // It's being attached and the attachment point is a HUD position, DefinePosition()
            DefinePosition();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sHudMenu, "");
        else if (iNum == SUBMENU && sStr == g_sHudMenu) {
            g_sCurrentMenu = g_sHudMenu;
            string sPrompt = "\nCustomize your Remote!";
            list lButtons = ["Horizontal","Vertical","RESET","Order","Buttons"];
            g_kMenuID = Dialog(llGetOwner(), sPrompt, lButtons, [UPMENU], 0);
        } else if (iNum == DIALOG_RESPONSE) {
            if (kID == g_kMenuID) {
                list lParams = llParseString2List(sStr, ["|"], []);
                kID = (key)llList2String(lParams, 0);
                string sButton = llList2String(lParams, 1);
                integer iPage = (integer)llList2String(lParams, 2);
                integer iPrimCount = llGetListLength(g_lPrimOrder);
                string sPrompt;
                list lButtons;
                if (g_sCurrentMenu == g_sHudMenu) {   // -- Inside the 'Options' menu, or 'submenu'
//                  If we press the 'Back' and we are inside the Options menu, go back to OwnerHUD menu
                    if (sButton == UPMENU)
                        llMessageLinked(LINK_SET, SUBMENU, g_sParentMenu, kID);
                    else if (sButton == "Horizontal") {
                        g_iLayout = 0;
                        DefinePosition();
                    } else if (sButton == "Vertical") {
                        g_iLayout = 69;
                        DefinePosition();
                    } else if (sButton == "Buttons") {
                        g_sCurrentMenu = g_sSubMenu1;
                        sPrompt = "\nThis is the menu for styles.\n";
                        sPrompt += "Selecting one of these options will\n";
                        sPrompt += "change the color of the HUD buttons.\n";
                        if (g_iTintable)
                            sPrompt+="Tint will allow you to change the HUD color\nto various shades via the 'Tint' menu.\n";
                        else
                            sPrompt += "If [White] is selected, an extra menu named 'Tint' will appear in this menu.\n";
                        lButtons = ["Light","Dark"];
                        if (g_iTintable) lButtons += ["Tint","-","-"];
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], iPage);
                    } else if (sButton == "Order") {
                        g_sCurrentMenu = g_sSubMenu2;
                        sPrompt = "\nThis is the order menu, simply select the\n";
                        sPrompt += "button which you want to re-order.\n\n";
                        lButtons = [];
                        integer i;
                        for (i=0;i<iPrimCount;++i)
                        {
                            integer _pos = llList2Integer(g_lPrimOrder,i);
                            if (_pos == 2) lButtons += ["Menu"];
                            else if (_pos == 3) lButtons += ["Couples"];
                            else if (_pos == 4) lButtons += ["Bookmarks"];
                            else if (_pos == 5) lButtons += ["Beckon"];
                            else if (_pos == 6) lButtons += ["Leash"];
                        }
                        lButtons += ["RESET"];
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], iPage);
                    } else if (sButton == "RESET") {
                        sPrompt = "\nConfirm reset of the entire HUD.\n\n";
                        lButtons = ["Confirm","Cancel"];
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], iPage);
                    }
                    else if (sButton == "Confirm")
                        DoReset();
                } else if (g_sCurrentMenu == g_sSubMenu1) {// -- Inside the 'Texture' menu, or 'submenu1'
                    if (sButton == UPMENU)
                        llMessageLinked(LINK_SET, SUBMENU, g_sHudMenu, kID);
                    else if ((sButton == "Light") || (sButton == "Dark"))
                        DoButtons(sButton);
                    else if (sButton == "White") {
                        g_iTintable = TRUE;
                        DoButtons(sButton);
                    }
                    else if (sButton == "Tint") {
                        g_sCurrentMenu = g_sSubMenu3;
                        sPrompt = "\nSelect the color you wish to tint the HUD.\n";
                        sPrompt += "If you don't see a color you enjoy, simply edit\n";
                        sPrompt += "and select a color under the menu you wish.\n";
                        lButtons = ["Orange","Yellow","Pink","Purple","Sky Blue","Light Green","Cyan","Mint"];
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], iPage);
                    }
                } else if (g_sCurrentMenu == g_sSubMenu2) {
                    if (sButton == UPMENU)
                        llMessageLinked(LINK_SET, SUBMENU, g_sHudMenu, kID);
                    else if (sButton == "Menu") {
                        g_iOldPos = llListFindList(g_lPrimOrder, [2]);
                        sPrompt = "\nSelect the new position for "+sButton+"\n\n";
                        lButtons = [];
                        integer i = 2;
                        for(;i<=iPrimCount;++i) {
                            if (g_iOldPos != i) {
                                integer iTemp = llList2Integer(g_lPrimOrder,i);
                                if (iTemp == 2) lButtons += ["Menu:"+(string)i];
                                else if (iTemp == 3) lButtons += ["Beckon:"+(string)i];
                                else if (iTemp == 4) lButtons += ["Bookmarks:"+(string)i];
                                else if (iTemp == 5) lButtons += ["Couples:"+(string)i];
                                else if (iTemp == 6) lButtons += ["Leash:"+(string)i];
                            }
                        }
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [], iPage);
                    } else if (sButton == "Beckon") {
                        g_iOldPos = llListFindList(g_lPrimOrder, [3]);
                        sPrompt = "\nSelect the new position for "+sButton+"\n\n";
                        lButtons = [];
                        integer i = 2;
                        for(;i<=iPrimCount;++i) {
                            if (g_iOldPos != i) {
                                integer iTemp = llList2Integer(g_lPrimOrder,i);
                                if (iTemp == 2) lButtons += ["Menu:"+(string)i];
                                else if (iTemp == 3) lButtons += ["Beckon:"+(string)i];
                                else if (iTemp == 4) lButtons += ["Bookmarks:"+(string)i];
                                else if (iTemp == 5) lButtons += ["Couples:"+(string)i];
                                else if (iTemp == 6) lButtons += ["Leash:"+(string)i];
                            }
                        }
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [], iPage);
                    } else if (sButton == "Bookmarks") {
                        g_iOldPos = llListFindList(g_lPrimOrder, [4]);
                        sPrompt = "\nSelect the new position for "+sButton+"\n\n";
                        lButtons = [];
                        integer i = 2;
                        for(;i<=iPrimCount;++i) {
                            if (g_iOldPos != i) {
                                integer iTemp = llList2Integer(g_lPrimOrder,i);
                                if (iTemp == 2) lButtons += ["Menu:"+(string)i];
                                else if (iTemp == 3) lButtons += ["Beckon:"+(string)i];
                                else if (iTemp == 4) lButtons += ["Bookmarks:"+(string)i];
                                else if (iTemp == 5) lButtons += ["Couples:"+(string)i];
                                else if (iTemp == 6) lButtons += ["Leash:"+(string)i];
                            }
                        }
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [], iPage);
                    } else if (sButton == "Couples") {
                        g_iOldPos = llListFindList(g_lPrimOrder, [5]);
                        sPrompt = "\nSelect the new position for "+sButton+"\n\n";
                        lButtons = [];
                        integer i = 2;
                        for(;i<=iPrimCount;++i)
                        {
                            if (g_iOldPos != i)
                            {
                                integer iTemp = llList2Integer(g_lPrimOrder,i);
                                if (iTemp == 2) lButtons += ["Menu:"+(string)i];
                                else if (iTemp == 3) lButtons += ["Beckon:"+(string)i];
                                else if (iTemp == 4) lButtons += ["Bookmarks:"+(string)i];
                                else if (iTemp == 5) lButtons += ["Couples:"+(string)i];
                                else if (iTemp == 6) lButtons += ["Leash:"+(string)i];
                            }
                        }
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [], iPage);
                    }
                    else if (sButton == "Leash")
                    {
                        g_iOldPos = llListFindList(g_lPrimOrder, [6]);
                        sPrompt = "\nSelect the new position for "+sButton+"\n\n";
                        lButtons = [];
                        integer i = 2;
                        for(;i<=iPrimCount;++i) {
                            if (g_iOldPos != i) {
                                integer iTemp = llList2Integer(g_lPrimOrder,i);
                                if (iTemp == 2) lButtons += ["Menu:"+(string)i];
                                else if (iTemp == 3) lButtons += ["Beckon:"+(string)i];
                                else if (iTemp == 4) lButtons += ["Bookmarks:"+(string)i];
                                else if (iTemp == 5) lButtons += ["Couples:"+(string)i];
                                else if (iTemp == 6) lButtons += ["Leash:"+(string)i];
                            }
                        }
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [], iPage);
                    } else if (sButton == "RESET") {
                        sPrompt = "\nConfirm reset of the button order to default.\n\n";
                        lButtons = ["Confirm","Cancel"];
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [], iPage);
                    } else if (sButton == "Confirm") {
                        g_lPrimOrder = [];
                        g_lPrimOrder = [0,1,2,3,4,5,6];
                        llOwnerSay("Order position reset to default.");
                        DefinePosition();
                    } else if (llSubStringIndex(sButton,":") >= 0) {   // Jess's nifty parsing trick for the menus
                        list lNewPosList = llParseString2List(sButton, [":"],[]);
                        g_iNewPos = llList2Integer(lNewPosList,1);
                        DoButtonOrder();
                    }
                } else if (g_sCurrentMenu == g_sSubMenu3) {    // -- Inside the 'Tint' menu, or 'g_sSubMenu3'
                    if (sButton == UPMENU) {
                        g_sCurrentMenu = g_sSubMenu1;
                        sPrompt = "\nThis is the menu for styles.\n";
                        sPrompt += "Selecting one of these options will\n";
                        sPrompt += "change the color of the HUD buttons.\n";
                        if (g_iTintable) sPrompt+="Tint will allow you to change the HUD color\nto various shades via the 'Tint' menu.\n";
                        else sPrompt += "If [White] is selected, an extra menu named 'Tint' will appear in this menu.\n";
                        lButtons = ["Light","Dark"];
                        if (g_iTintable) lButtons += ["Tint"," "," "];
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [], iPage);
                    } else if (sButton == "Orange")
                        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR, ALL_SIDES, <1, 0.49804, 0>, 1.0]);
                    else if (sButton == "Yellow")
                        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR, ALL_SIDES, <1, 1, 0>, 1.0]);
                    else if (sButton == "Light Green")
                        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR, ALL_SIDES, <0, 1, 0>, 1.0]);
                    else if (sButton == "Pink")
                        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR, ALL_SIDES, <1, 0.58431, 1>, 1.0]);
                    else if (sButton == "Purple")
                        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR, ALL_SIDES, <0.50196, 0, 1>, 1.0]);
                    else if (sButton == "Sky Blue")
                        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR, ALL_SIDES, <0.52941, 0.80784, 1>, 1.0]);
                    else if (sButton == "Cyan")
                        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR, ALL_SIDES, <0, 0.80784, 0.79216>, 1.0]);
                    else if (sButton == "Mint")
                        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR, ALL_SIDES, <0.49020, 0.73725, 0.49412>, 1.0]);
                }
            }
        } else if (iNum == CMD_TOUCH) {
            if (sStr == "hide") {
                if (g_iHidden) {
                    g_iHidden = !g_iHidden;
                    DefinePosition();
                } else {
                    g_iHidden = !g_iHidden;
                    DoHide();
                }
            }
        }
    }

    changed(integer iChange)
    {
        if (iChange & CHANGED_OWNER) {
            DoButtons("Dark");
            llResetScript();
        }
    }
}
