import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "dayname"

    implicitHeight: dayNameText.height
    implicitWidth: dayNameText.width

    FontLoader {
        id: anuratiFont
        source: "file:///home/adityarajput/.local/share/fonts/illogical-impulse-google-sans-flex/ANURATI Free Font/Anurati-Regular.otf"
    }

    StyledText {
        id: dayNameText
        font {
            pixelSize: 50
            family: anuratiFont.name
            weight: Font.Normal
            letterSpacing: 28
        }
        color: Appearance.colors.colPrimary
        text: {
            const days = ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"];
            const today = new Date();
            return days[today.getDay()] ?? "--";
        }
    }
}