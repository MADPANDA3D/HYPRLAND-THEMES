import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import "components"

Item {
    id: root

    height: Screen.height
    width: Screen.width
    property string backgroundSource: config.Background
    property bool isAnimatedBackground: backgroundSource.toLowerCase().match(/\.(gif|mng|webp)$/) !== null
    
    Image {
        id: background
        
        anchors.fill: parent
        height: parent.height
        width: parent.width
        fillMode: Image.PreserveAspectCrop

        source: root.isAnimatedBackground ? "" : root.backgroundSource

        asynchronous: false
        cache: true
        mipmap: true
        clip: true
    }

    AnimatedImage {
        id: animatedBackgroundImage

        anchors.fill: parent
        height: parent.height
        width: parent.width
        fillMode: Image.PreserveAspectCrop

        source: root.isAnimatedBackground ? root.backgroundSource : ""
        playing: true
        asynchronous: false
        cache: false
        clip: true
    }

    Item {
        id: contentPanel

        anchors {
            fill: parent
            topMargin: config.Padding
            rightMargin: config.Padding
            bottomMargin:config.Padding
            leftMargin: config.Padding
        }

        DateTimePanel {
            id: dateTimePanel

            anchors {
                top: parent.top
                right: parent.right
            }
        }
        
        LoginPanel {
            id: loginPanel
            
            anchors.fill: parent
        }
    }
}
