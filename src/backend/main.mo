import Array "mo:base/Array";
import D "mo:base/Debug";
import Error "mo:base/Error";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import P "mo:base/Prelude";
import Principal "mo:base/Principal";
import Trie "mo:base/Trie";

import T "dip721_types";

actor class DRC721(_name : Text, _symbol : Text) {

  //Using DIP721 standard, adapted from https://github.com/SuddenlyHazel/DIP721/blob/main/src/DIP721/DIP721.mo
  private stable var tokenPk : Nat = 0;

  private stable var tokenURIEntries : [(T.TokenId, Text)] = [];
  private stable var ownersEntries : [(T.TokenId, Principal)] = [];
  private stable var balancesEntries : [(Principal, Nat)] = [];
  private stable var tokenApprovalsEntries : [(T.TokenId, Principal)] = [];
  private stable var operatorApprovalsEntries : [(Principal, [Principal])] = [];  

  private let tokenURIs : HashMap.HashMap<T.TokenId, Text> = HashMap.fromIter<T.TokenId, Text>(tokenURIEntries.vals(), 10, Nat.equal, Hash.hash);
  private let owners : HashMap.HashMap<T.TokenId, Principal> = HashMap.fromIter<T.TokenId, Principal>(ownersEntries.vals(), 10, Nat.equal, Hash.hash);
  private let balances : HashMap.HashMap<Principal, Nat> = HashMap.fromIter<Principal, Nat>(balancesEntries.vals(), 10, Principal.equal, Principal.hash);
  private let tokenApprovals : HashMap.HashMap<T.TokenId, Principal> = HashMap.fromIter<T.TokenId, Principal>(tokenApprovalsEntries.vals(), 10, Nat.equal, Hash.hash);
  private let operatorApprovals : HashMap.HashMap<Principal, [Principal]> = HashMap.fromIter<Principal, [Principal]>(operatorApprovalsEntries.vals(), 10, Principal.equal, Principal.hash);

  private func _unwrap<T>(x : ?T) : T {
		switch x {
			case null { P.unreachable() };
			case (?x_) { x_ };
		}
	};

  // Added functions
  public type NftId = Nat32;
  public type Nft = {
    tokenId: Nat;
    principal: Principal;
    url: Text;
    creator: Principal;
  };

  public type NftToken = {
    tokenId: Nat;
    url: Text;
    creator: Principal;
    principal: Principal;
  };

  // counter for data-history 
  private stable var next : NftId = 1;

  // data storage 
  private stable var nftBelogsTo : Trie.Trie<NftId, Nft> = Trie.empty();

  // add a new mint nft to the data-history storage
  func addNft(nft : Nft){
    let nftId = next;
    next += 1;
    nftBelogsTo := Trie.replace(
      nftBelogsTo,
      key(nftId),
      Nat32.equal,
      ?nft,
    ).0;
  };

  // Update an Nft History
  func updateNft(nftId : NftId, newPrincipal : Principal) : Bool {
    let oldNftItem = Trie.get(nftBelogsTo, key(nftId), Nat32.equal);
    let exists = Option.isSome(oldNftItem);

    switch(oldNftItem) {
      case (null) {};
      case (?Nft) {
          if (exists) { 
            var _oldNftItem : Nft = Option.get(oldNftItem, Nft);
            var newNftItem : Nft = {
              tokenId = _oldNftItem.tokenId;
              principal = newPrincipal;
              url = _oldNftItem.url;
              creator = _oldNftItem.principal;
            };

            nftBelogsTo := Trie.replace(
              nftBelogsTo,
              key(nftId),
              Nat32.equal,
              ?newNftItem,
            ).0;
          };
      };
    };

    return exists;
  };

  // Get the total count of minted NFTs
  public query func getTotalCountOfNfts() : async Nat {
    Trie.size(nftBelogsTo);
  };

  // get all minted nft per proncipal
  public query func getPrincipalsToken (principal: Principal) : async [NftToken]  { 
    //D.print(debug_show(principal));
    let result : Trie.Trie<NftId, Nft> = Trie.filter<NftId, Nft>(nftBelogsTo, func (k, v) { v.principal == principal });  
    Trie.toArray<NftId, Nft, NftToken>(result, transformNft);
  };

  // get all minted nft 
  public query func getAllToken () : async [NftToken]  { 
    Trie.toArray<NftId, Nft, NftToken>(nftBelogsTo, transformNft);
  };

  // Create a trie key from an nft identifier
  private func key(x : NftId) : Trie.Key<NftId> {
    return { hash = x; key = x };
  };

  // Reduce an NFTs to less properties which are needed
  private func transformNft(nftId:NftId, nft:Nft): NftToken{
    let newToken : NftToken = {
      tokenId = nft.tokenId;
      url = nft.url;
      creator = nft.creator;
      principal = nft.principal;
    };
    return newToken;
  };

  // base functions
  public shared func balanceOf(p : Principal) : async ?Nat {
    return balances.get(p);
  };

  public shared func ownerOf(tokenId : T.TokenId) : async ?Principal {
    return _ownerOf(tokenId);
  };

  public shared query func tokenURI(tokenId : T.TokenId) : async ?Text {
    return _tokenURI(tokenId);
  };

  public shared query func name() : async Text {
    return _name;
  };

  public shared query func symbol() : async Text {
    return _symbol;
  };

  public shared func isApprovedForAll(owner : Principal, opperator : Principal) : async Bool {
    return _isApprovedForAll(owner, opperator);
  };

  public shared(msg) func approve(to : Principal, tokenId : T.TokenId) : async () {
    switch(_ownerOf(tokenId)) {
      case (?owner) {
        assert to != owner;
        assert msg.caller == owner or _isApprovedForAll(owner, msg.caller);
        _approve(to, tokenId);
      };
      case (null) {
        throw Error.reject("No owner for token")
      };
    }
  };

  public shared func getApproved(tokenId : Nat) : async Principal {
    switch(_getApproved(tokenId)) {
      case (?v) { return v };
      case null { throw Error.reject("None approved")}
    }
  };

  public shared(msg) func setApprovalForAll(op : Principal, isApproved : Bool) : () {
    assert msg.caller != op;

    switch (isApproved) {
      case true {
        switch (operatorApprovals.get(msg.caller)) {
          case (?opList) {
            var array = Array.filter<Principal>(opList,func (p) { p != op });
            array := Array.append<Principal>(array, [op]);
            operatorApprovals.put(msg.caller, array);
          };
          case null {
            operatorApprovals.put(msg.caller, [op]);
          };
        };
      };
      case false {
        switch (operatorApprovals.get(msg.caller)) {
          case (?opList) {
            let array = Array.filter<Principal>(opList, func(p) { p != op });
            operatorApprovals.put(msg.caller, array);
          };
          case null {
            operatorApprovals.put(msg.caller, []);
          };
        };
      };
    };
      
  };

  // adjustment function
  public shared(msg) func transferFrom(from : Principal, to : Principal, tokenId : Nat, nftId : NftId) : () {
    //assert _isApprovedOrOwner(msg.caller, tokenId);

    _transfer(from, to, tokenId);
    // update Nft
    var r = updateNft(nftId, to);
  };

  // adjustment function
  // Mint without authentication
  // Mint with plug auth
  public func mint_principal(uri : Text, principal : Principal) : async Nat {
    tokenPk += 1;
    _mint(principal, tokenPk, uri);
    
    let _nft : Nft = {
      tokenId = tokenPk; 
      principal = principal;
      url = uri;
      creator = principal;
    };
    
    //D.print(debug_show(_nft));
    addNft(_nft);
    return tokenPk;
  };

  // Mint requires authentication in the frontend as we are using caller.
  public shared ({caller}) func mint(uri : Text) : async Nat {
    tokenPk += 1;
    _mint(caller, tokenPk, uri);
    return tokenPk;
  };

  // Internal
  private func _ownerOf(tokenId : T.TokenId) : ?Principal {
    return owners.get(tokenId);
  };

  private func _tokenURI(tokenId : T.TokenId) : ?Text {
    return tokenURIs.get(tokenId);
  };

  private func _isApprovedForAll(owner : Principal, opperator : Principal) : Bool {
    switch (operatorApprovals.get(owner)) {
      case(?whiteList) {
        for (allow in whiteList.vals()) {
          if (allow == opperator) {
            return true;
          };
        };
      };
      case null {return false;};
    };
    return false;
  };

  private func _approve(to : Principal, tokenId : Nat) : () {
    tokenApprovals.put(tokenId, to);
  };

  private func _removeApprove(tokenId : Nat) : () {
    let _ = tokenApprovals.remove(tokenId);
  };

  private func _exists(tokenId : Nat) : Bool {
    return Option.isSome(owners.get(tokenId));
  };

  private func _getApproved(tokenId : Nat) : ?Principal {
    assert _exists(tokenId) == true;
    switch(tokenApprovals.get(tokenId)) {
      case (?v) { return ?v };
      case null {
        return null;
      };
    }
  };

  private func _hasApprovedAndSame(tokenId : Nat, spender : Principal) : Bool {
    switch(_getApproved(tokenId)) {
      case (?v) {
        return v == spender;
      };
      case null { return false}
    }
  };

  private func _isApprovedOrOwner(spender : Principal, tokenId : Nat) : Bool {
    assert _exists(tokenId);
    let owner = _unwrap(_ownerOf(tokenId));
    return spender == owner or _hasApprovedAndSame(tokenId, spender) or _isApprovedForAll(owner, spender);
  };

  private func _transfer(from : Principal, to : Principal, tokenId : Nat) : () {
    assert _exists(tokenId);
    assert _unwrap(_ownerOf(tokenId)) == from;

    // Bug in HashMap https://github.com/dfinity/motoko-base/pull/253/files
    // this will throw unless you patch your file
    _removeApprove(tokenId);

    _decrementBalance(to);
    _incrementBalance(from);
    owners.put(tokenId, to);
  };

  /**
   * 100 to mint a new nft
   */
  private func _incrementBalance(address : Principal) {
    switch (balances.get(address)) {
      case (?v) {
        balances.put(address, v + 100);
      };
      case null {
        balances.put(address, 100);
      }
    }
  };

  /**
   * 300 to buy a new nft
   */
  private func _decrementBalance(address : Principal) {
    switch (balances.get(address)) {
      case (?v) {
        balances.put(address, v - 300);
      };
      case null {
        balances.put(address, 0);
      }
    }
  };

  private func _mint(to : Principal, tokenId : Nat, uri : Text) : () {
    assert not _exists(tokenId);

    _incrementBalance(to);
    owners.put(tokenId, to);
    tokenURIs.put(tokenId,uri)
  };

  private func _burn(tokenId : Nat) {
    let owner = _unwrap(_ownerOf(tokenId));

    _removeApprove(tokenId);
    _decrementBalance(owner);

    ignore owners.remove(tokenId);
  };

  system func preupgrade() {
    tokenURIEntries := Iter.toArray(tokenURIs.entries());
    ownersEntries := Iter.toArray(owners.entries());
    balancesEntries := Iter.toArray(balances.entries());
    tokenApprovalsEntries := Iter.toArray(tokenApprovals.entries());
    operatorApprovalsEntries := Iter.toArray(operatorApprovals.entries());  
  };

  system func postupgrade() {
    tokenURIEntries := [];
    ownersEntries := [];
    balancesEntries := [];
    tokenApprovalsEntries := [];
    operatorApprovalsEntries := [];
  };
};