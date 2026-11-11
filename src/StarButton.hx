package mods.favorite_friends;

import openfl.display.Sprite;
import openfl.events.MouseEvent;

class StarButton extends Sprite {
    var selected:Null<Bool>;
    final toggle:Void->Void;

    public function new(toggle:Void->Void) {
        super();
        this.toggle = toggle;
        // Center in the gap between the native trophy and ascension badges.
        x = 0.5;
        y = -15;
        buttonMode = true;
        mouseChildren = false;
        addEventListener(MouseEvent.CLICK, click);
        setSelected(false);
    }

    function click(event:MouseEvent):Void {
        event.stopImmediatePropagation();
        toggle();
    }

    public function setSelected(value:Bool):Void {
        if (selected == value) return;
        selected = value;
        graphics.clear();
        graphics.beginFill(0, 0);
        graphics.drawRect(-8, -10, 16, 20);
        graphics.endFill();
        graphics.lineStyle(1.5, 0x382209);
        graphics.beginFill(value ? 0xFFD43B : 0xCCCCCC);
        for (i in 0...11) {
            var angle = i * Math.PI / 5 - Math.PI / 2;
            var radius = i % 2 == 0 ? 7.5 : 3.5;
            var px = Math.cos(angle) * radius;
            var py = Math.sin(angle) * radius;
            if (i == 0) graphics.moveTo(px, py);
            else graphics.lineTo(px, py);
        }
        graphics.endFill();
    }

    public function destroy():Void {
        removeEventListener(MouseEvent.CLICK, click);
        if (parent != null) parent.removeChild(this);
    }
}
