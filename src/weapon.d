module weapon;

interface Weapon {
    @property string name();
    @property bool isAutomatic();
    @property float fireDelay();
    @property int cartridgeSize();    
}

class SimpleWeaponImpl : Weapon {
    
    private:
    string _name;
    bool _isAutomatic;
    float _fireDelay;
    int _cartridgeSize;
    
    protected this(string name, bool isAutomatic, float fireDelay, float cartridgeSize) {
        _name = name;
        _isAutomatic = isAutomatic;
        _fireDelay = fireDelay;
        _cartridgeSize = cartridgeSize;
    }
    
    public:     
    @property string name() { return _name; }
    @property bool isAutomatic() { return _isAutomatic; }
    @property float fireDelay() { return _fireDelay; }
    @property int cartridgeSize() { return _cartridgeSize; }
}

public class Pistol : SimpleWeaponImpl {
    public this() {
        super("Pistol", false, 0.33, 6);
    }
}

public class SMG : SimpleWeaponImpl {
    public this() {
        super("SMG", true, 0.05, 24);
    }
}