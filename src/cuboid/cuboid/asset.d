module cuboid.asset;

import std.file;
import std.zip;
import std.string;
import std.regex;

class AssetData {
    string name;
    string type;
    string[string] parameters;
    ubyte[] data;
}

interface AssetCollection {   
    public AssetData read(string type, string name);
}

class DirectoryAssetCollection : AssetCollection {
    
    private string basePath;
    
    public this(string path) {
        this.basePath = chomp(path);
    }
    
    public AssetData read(string typename, string path) {
        auto typepath = this.basePath ~ "/" ~ typename;
        
        if(
            std.file.exists(typepath) &&
            std.file.isDir(typepath)
        ) {
            auto filenamePattern = regex(r"/([\w_-]+)\.(\w+)$", "");
            
            foreach(string entry; dirEntries(typepath, SpanMode.depth)) {
                
                auto matchResult = match(entry, filenamePattern);
                
                if(matchResult) {                
                    auto data = new AssetData();
                    data.name = matchResult.captures[1];
                    data.type = typename;
                    data.parameters["fileext"] = matchResult.captures[2];
                    data.data = cast(ubyte[]) std.file.read(entry);
                    
                    return data;
                }
            }
            
        }
        return null;
    }
    
}

interface AssetLoader {
    
    void registerCollection(AssetCollection collection);
    void registerAssetType(AssetType assetType);
    
}

abstract class AssetType {
    
    final protected static AssetType load(string path);
}