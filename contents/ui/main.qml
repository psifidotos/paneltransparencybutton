/*
 * Copyright 2019  Michail Vourlakos <mvourlakos@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */

import QtQuick 2.2
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3

Item {
    id: main

    Layout.minimumWidth: !vertical ? minimumLength : -1
    Layout.maximumWidth: !vertical ? minimumLength : -1

    Layout.minimumHeight: vertical ? minimumLength : -1
    Layout.maximumHeight: vertical ? minimumLength : -1

    opacity: hidden ? 0 : 1

    readonly property bool vertical: plasmoid.location === PlasmaCore.Types.Vertical
    readonly property bool hidden: plasmoid.location !== PlasmaCore.Types.Planar
                                   && (!containmentInterface
                                       || (containmentInterface && containmentInterface.hasOwnProperty("editMode") && !containmentInterface.editMode)) /*Plasma>=5.18*/
                                       //! deprecated code for historical reference, Plasma <= 5.17
                                       //!/|| (containmentInterface && containmentInterface.immutability === PlasmaCore.Types.UserImmutable))

    readonly property int minimumLength: {
        if (hidden) {
            return 0;
        }

        return !vertical ? transparencySwitch.implicitWidth + 8 : transparencySwitch.height + 8
    }

    property Item containmentInterface

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation
    Plasmoid.status: containmentInterface && hidden ? PlasmaCore.Types.HiddenStatus : PlasmaCore.Types.PassiveStatus
    Plasmoid.onActivated: switchTransparency()

    Component.onCompleted: initializeAppletTimer.start()

    /*Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: "red"
    }*/

    PlasmaComponents3.Switch{
        id: transparencySwitch
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        checked:  containmentInterface ? containmentInterface.backgroundHints === PlasmaCore.Types.NoBackground : plasmoid.configuration.transparencyEnabled
        onClicked: switchTransparency()
    }

    function typeOf(obj, className){
        var name = obj.toString();
        return ((name.indexOf(className + "(") === 0) || (name.indexOf(className + "_QML") === 0));
    }

    function applyTransparency() {
        if (containmentInterface) {
            var newState = plasmoid.configuration.transparencyEnabled ? PlasmaCore.Types.NoBackground : PlasmaCore.Types.DefaultBackground;
            containmentInterface.backgroundHints = newState;
        }
    }

    function searchContainmentView() {
        if (main.parent) {
            var cItem = main.parent;
            var level=0;

            while(!containmentInterface && cItem && level<14) {
                if (typeOf(cItem,"ContainmentInterface")) {
                    console.log(" Transparency Button Applet :: ContainmentInterface found...");
                    containmentInterface = cItem;
                }

                cItem = cItem.parent;
                level = level + 1;
            }            
        }
    }

    function switchTransparency() {
        if (!containmentInterface) {
            searchContainmentView();
        }

        plasmoid.configuration.transparencyEnabled = !plasmoid.configuration.transparencyEnabled;
        applyTransparency();
    }

    Timer {
        id: initializeAppletTimer
        interval: 1200

        property int step: 0

        readonly property int maxStep:4

        onTriggered: {
            main.searchContainmentView();
            if (containmentInterface) {
                applyTransparency();
            } else if (step<maxStep) {
                step = step + 1;
                start();
            }
        }

    }
}
