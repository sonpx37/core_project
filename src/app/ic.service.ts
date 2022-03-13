import { Injectable } from '@angular/core';
import { Principal } from '@dfinity/principal';

const ic_service = require('../declarations/backend').backend;

@Injectable({
  providedIn: 'root'
})
export class IcService {
  constructor() { }
  public async greet(name:string){
    return await ic_service.greet(name);
  }

  public async mint_principal(uri : string, principal : string){
    try {
      const p = Principal.fromText(principal);
      return await ic_service.mint_principal(uri, p);
    } catch (e){
      return false;
    }
  }

  public async getPrincipalsToken (principal : string){
    try {
      const p = Principal.fromText(principal);
      return await ic_service.getPrincipalsToken(p);
    } catch (e){
      return false;
    }
  }

  public async getAllToken (){
    try {
      return await ic_service.getAllToken();
    } catch (e){
      return false;
    }
  }

  public async get_balance(principal: string){
    try {
      const p = Principal.fromText(principal);
      const response = await ic_service.balanceOf(p);
      if (response?.length === 0) return 0;
      return response; 
    } catch (e){
      return false;
    }
  }

  public async transferFrom(owner: string, newOwner: string, tokenId: any){
    try {
      const from = Principal.fromText(owner);
      const to = Principal.fromText(newOwner);
      return await ic_service.transferFrom(from, to, tokenId, tokenId);
    } catch (e){
      //console.log(e)
      return false;
    }
  }

  public async mint(){

  }
}