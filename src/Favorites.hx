package mods.favorite_friends;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;

class Favorites {
    final path:String;
    var ids:Array<String> = [];

    public function new(path:String) {
        this.path = path;
        var source = FileSystem.exists(path) ? path : path + ".bak";
        if (!FileSystem.exists(source)) return;
        var saved:Dynamic = Json.parse(File.getContent(source));
        if (!Std.isOfType(saved, Array)) throw "Expected an array of favorite player IDs";
        for (id in (cast saved : Array<Dynamic>)) {
            if (Std.isOfType(id, String) && !ids.contains(cast id)) ids.push(cast id);
        }
    }

    public function has(id:UInt):Bool return ids.contains(Std.string(id));

    public function toggle(id:UInt):Void {
        var next = ids.copy();
        var key = Std.string(id);
        if (!next.remove(key)) next.push(key);
        var temporary = path + ".tmp";
        File.saveContent(temporary, Json.stringify(next));
        // Windows cannot rename over an existing file. Keep the old save until the new one is in place.
        if (FileSystem.exists(path)) {
            var backup = path + ".bak";
            if (FileSystem.exists(backup)) FileSystem.deleteFile(backup);
            FileSystem.rename(path, backup);
        }
        FileSystem.rename(temporary, path);
        ids = next;
    }
}
