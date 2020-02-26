pragma solidity ^0.5.0;

contract Azimuth {
    
    function getSponsoringCount(uint32) external view returns (uint256) {}
    
    function sponsoring(uint32, uint) public returns (uint32) {}
    
}

contract Ecliptic {

    function getKeys(uint32) external view returns(bytes32, bytes32, uint32, uint32) {}

}

contract Subscriptions {
    
    Azimuth azi = Azimuth(0x223c067F8CF28ae173EE5CafEa60cA44C335fecB);
    
    /// TODO listen for azimuth sponsor change events
    
    address payable internal owner;
    
    constructor(uint32 _point) public {
        owner = msg.sender;
        importSubscribers(_point);
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Error: not the contract owner.");
        _;
    }
    
    mapping(uint32 => uint256) internal balances;
    uint32[] internal subscribers;
    
    /// import subscriber list
    function importSubscribers(uint32 _point) internal onlyOwner {
        for (uint i = 0; i < azi.getSponsoringCount(_point); i++) {
            subscribers.push(azi.sponsoring(_point, i));
        }
    }
    
    /// TODO add a blacklist of points that may not resubscribe

    mapping(uint32 => bool) internal blacklist;

    function addBlacklist(uint32 _point) public onlyOwner {
        blacklist[_point] = true;
    }

    function unBlacklist(uint32 _point) public onlyOwner {
        blacklist[_point] = false;
    }
    
    /// check whether a point is a valid subscriber
    function isSubscriber(uint32 _point) internal view returns (bool _isSubscriber) {
        for (uint i = 0; i < subscribers.length; i += 1) {
            if (subscribers[i] == _point) {
                _isSubscriber = true;
            }
        }
        return _isSubscriber;
    }

    /// add a new subscriber, initialize their balance as the value sent, and send payment to contract owner
    function subscribe(uint32 _point) public payable {
        require(isSubscriber(_point) == false, "Error: this point is already a subscriber.");
        subscribers.push(_point);
        balances[_point] = msg.value;
        owner.transfer(msg.value);
    }
    
    /// receive payment from subscriber, update their balancre, and send payment to conract owner
    function pay(uint32 _point) public payable {
        require(isSubscriber(_point) == true, "Error: this point is not a valid subscriber.");
        balances[_point] += msg.value;
        owner.transfer(msg.value);
    }
    
    /// check subscriber balance. TODO: allow point owner to access this balance as well
    function checkBalance(uint32 _point) public view onlyOwner returns(uint _balance) {
        require(isSubscriber(_point) == true, "Error: this point is not a valid subscriber.");
        return (balances[_point]);
    }
    
    /// bill the subscribers
    /// a default billing rate of zero (no charge)
    uint internal billingRate = 0;
    
    /// is it desirable to automate this?
    function bill() public onlyOwner {
        for (uint i = 0; i < subscribers.length; i += 1) {
            if (balances[subscribers[i]] < billingRate) {
                boot(subscribers[i]);
            } else {
                balances[subscribers[i]] -= billingRate;
            }
        }
    }
    
    /// boot a subscriber
    function boot(uint32 _point) public onlyOwner {
        balances[_point] = 0;
        for (uint i = 0; i < subscribers.length; i++) {
            if (subscribers[i] == _point) {
                delete subscribers[i];
                break; /// check whether this is correct
            }
        }
    }
    
    /// adjust the billing rate
    function setRate(uint _amount) public onlyOwner {
        billingRate = _amount;
    }
}