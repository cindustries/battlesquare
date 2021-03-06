module cuboid.assetdb;

import std.exception;
static import std.file;
import etc.c.sqlite3;
import std.string;

static this() {
    sqlite3_initialize();
}

static ~this() {
    sqlite3_shutdown();
}

class Database {
    
    private sqlite3* db;
    
    public this(string path) {
        enforce( sqlite3_open(toStringz(path), &sqldb) == SQLITE_OK );
    }
    
    public this() {
        this(":memory:");
    }
    
    public void execute(string sql) {
        enforce( sqlite3_exec(sqldb, query.toStringz(), null, null, null) == SQLITE_OK );
    }
    
    public Statement prepare(string sql) {
        auto statement = new this.Statement();
        enforce( sqlite3_prepare_v2(this.db, sql.toStringz(), sql.length, &statement.statement, null) == SQLITE_OK );
        return statement;
    }
    
    class Statement {
        
        private sqlite_stmt* statement;
        private this() {}
        private bool canAccessColumn;
        
        // Usage:
        // do { use Statement } while (stmt.step())
        public bool step() {
            return ( sqlite3_step(this.statement) == SQLITE_ROW );
        }
        
        // Column info retrieval methods
        public int columnCount() { return sqlite3_column_count(statement); }
        public string columnName(int col) { return to!string( sqlite_column_name(statement, col) ); }
        
        // Column data retrieval methods
        public void[] getBlob(int col) {
            void* datap = sqlite3_column_blob(statement, col);
            int datalen = sqlite3_column_bytes(statement, col);
            return cast(void[]) datap[0 .. datalen].dup;
        }
        public double getDouble(int col) { return sqlite3_column_double(statement, col); }
        public int  getInt(int col) { return sqlite3_column_int(statement, col); }
        public long getInt64(int col) { return sqlite3_column_int64(statement, col); }
        public char[] getText(int col) {
            char* datap = sqlite3_column_text(statement, col);
            int datalen = sqlite3_column_bytes(statement, col);
            return cast(char[]) datap[0 .. datalen].dup;
        }
        
        public int columnCount() {
            return sqlite3_column_count(statement);
        }
        
        public void finalise() {
            sqlite3_finalize(statement);            
        }
        
        ~this() {
            this.finalize();
        }
        
    }
}

class AssetDB {
    
    private enum ASSETDB_APPID = 6295604; // "cuboid"
    private enum ASSETDB_CURRENT_VERSION = 1;
    
    private Database db;
    
    private this(Database _db) {
        this.db = _db;
    }
    
    public static AssetDB open(string path) {
        
        sqlite3* sqldb;
        enforce( sqlite3_open(path.toStringz(), &sqldb) == SQLITE_OK );
        
        void exec(string query) {
            
        }
        
        // check to see if it's a valid package
        exec("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='packageinfo';");
        
        exec("SELECT value FROM packageinfo WHERE param='assetdb_version';");
        exec("SELECT value FROM packageinfo WHERE param='magic';");
        
        exec("
            CREATE TABLE packageinfo (
                id INTEGER PRIMARY KEY ASC AUTOINCREMENT,
                param TEXT,
                value TEXT
            )
        ");
        
        exec("
            CREATE TABLE asset (
                id INTEGER PRIMARY KEY ASC AUTOINCREMENT,
                namespace TEXT,
                name TEXT,
                type TEXT,
                data BLOB, 
                UNIQUE(namespace, name)
            )
        ");
        
        exec("
            CREATE TABLE asset_param (
                id INTEGER PRIMARY KEY ASC AUTOINCREMENT,
                asset_id INTEGER,
                param TEXT,
                value TEXT,
                FOREIGN KEY(asset_id) REFERENCES asset(id)
            )
        ");
        
        return new AssetDB(sqldb);
    }
    
    public void close() {
        if(this.db !is null)
            sqlite3_close(this.db);
    }
    
}