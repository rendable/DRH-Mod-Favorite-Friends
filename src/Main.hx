package mods.favorite_friends;

import account.FriendInfo;
import facade.DBFacade;
import mods.api.Context;
import mods.api.Mod;
import openfl.Vector as FriendVector;
import openfl.display.MovieClip;
import openfl.events.Event;
import stateMachine.mainStateMachine.TownState;
import uI.leaderboard.LeaderboardFriendSlot;
import uI.leaderboard.UILeaderboard;

class Main extends Mod {
    var context:Context;
    var facade:DBFacade;
    var board:UILeaderboard;
    var favorites:Favorites;
    var stars:Array<StarButton> = [];
    var nextUpdate:Int = 0;

    override public function ready(context:Context):Void {
        this.context = context;
        favorites = new Favorites(context.data + "/favorites.json");
        facade = context.core.facade;
        context.overlay.addEventListener(Event.ENTER_FRAME, update);
        context.log("loaded: town leaderboard favorites");
    }

    function update(event:Event):Void {
        var now = openfl.Lib.getTimer();
        if (!context.core.alive) return;
        var current:UILeaderboard = null;
        var machine = facade.mainStateMachine;
        if (machine != null && machine.currentStateName == "TownState") {
            var town:TownState = cast Reflect.field(machine, "mTownState");
            if (town != null && town.townStateMachine != null) current = town.leaderboard;
        }
        if (current != board) {
            clearStars();
            board = current;
        }
        if (board == null || !board.initialized) return;
        if (now >= nextUpdate && !board.onlinePopup.visible && !board.offlinePopup.visible) {
            nextUpdate = now + 125;
            sortAndPopulate();
        }
        updateStars();
    }

    function updateStars():Void {
        var slots:FriendVector<LeaderboardFriendSlot> = cast Reflect.field(board, "mFriendSlots");
        for (i in 0...slots.length) {
            var slot = slots[i];
            var root:MovieClip = cast Reflect.field(slot, "mFriendSlot");
            if (root == null) continue;
            var star = stars[i];
            if (star == null) {
                star = new StarButton(function() toggle(slot));
                stars[i] = star;
                root.addChild(star);
            }
            var friend:FriendInfo = cast Reflect.field(slot, "mFriendInfo");
            star.visible = eligible(friend);
            if (star.visible) star.setSelected(favorites.has(friend.id));
        }
    }

    function eligible(friend:FriendInfo):Bool {
        return friend != null && friend.id != 0 && friend.id != facade.accountId;
    }

    function toggle(slot:LeaderboardFriendSlot):Void {
        if (board == null || Reflect.field(slot, "mLeaderboard") != board) return;
        var friend:FriendInfo = cast Reflect.field(slot, "mFriendInfo");
        if (!eligible(friend)) return;
        try {
            favorites.toggle(friend.id);
        } catch (error:Dynamic) {
            context.log("could not save favorites: " + Std.string(error));
            return;
        }
        board.hidePopup();
        sortAndPopulate();
        updateStars();
    }

    function sortAndPopulate():Void {
        // The first online entry is the local player (or an empty reserved slot).
        var onlineChanged = reorder(board.onlineFriends, 1);
        var offlineChanged = reorder(board.offlineFriends, 0);
        if (onlineChanged || offlineChanged) {
            Reflect.callMethod(board, Reflect.field(board, "populateFriendSlots"), []);
        }
    }

    function compare(a:FriendInfo, b:FriendInfo):Int {
        var aFavorite = favorites.has(a.id);
        var bFavorite = favorites.has(b.id);
        if (aFavorite != bFavorite) return aFavorite ? -1 : 1;
        return a.trophies == b.trophies ? 0 : (a.trophies > b.trophies ? -1 : 1);
    }

    function reorder(list:FriendVector<FriendInfo>, start:Int):Bool {
        for (i in start + 1...list.length) {
            if (compare(list[i - 1], list[i]) <= 0) continue;
            var order:Array<Int> = [];
            for (index in start...list.length) order.push(index);
            order.sort(function(a, b) {
                var difference = compare(list[a], list[b]);
                return difference == 0 ? a - b : difference;
            });
            var sorted = [for (index in order) list[index]];
            for (index in 0...sorted.length) list[start + index] = sorted[index];
            return true;
        }
        return false;
    }

    function clearStars():Void {
        for (star in stars) if (star != null) star.destroy();
        stars = [];
    }

    override public function dispose():Void {
        if (context != null) context.overlay.removeEventListener(Event.ENTER_FRAME, update);
        clearStars();
        board = null;
    }
}
