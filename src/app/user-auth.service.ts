import { Injectable } from '@angular/core';
import { environment } from 'src/environments/environment';
import { IcService } from './ic.service';

@Injectable({
  providedIn: 'root'
})
export class UserAuthService {
  // Just holds the users principal id
  public userWalletPrincipal: any;
  // Just holds the users balance
  public userWalletBalance: number;
  // Whitelist for PlugWallet connection
  private connWhitelist: string[] = [ environment.canisterId ];

  constructor(
    private icService: IcService
  ) {
    this.userWalletBalance = 0;
  }

  public getPlugWallet() {
    const _window: any = window;
    if (_window.ic?.plug) {
      return _window.ic?.plug;
    }
    return null;
  }

  public async getPlugWalletConnection() {
    const plug = this.getPlugWallet();
    if (plug) {
      // check if PlugWallet is connected
      const connected = await plug.isConnected();
      if (connected) {
        return await this.connectToPlugWallet();
      }
    }
    return false;
  }

  public async connectToPlugWallet() {
    const plug = this.getPlugWallet();
    if (!plug) return null;
    try {
      const _window: any = window;
      const whitelist = this.connWhitelist;
      await _window.ic.plug.requestConnect({ whitelist });
      const principalId = await plug.agent.getPrincipal();
      this.userWalletPrincipal = principalId.toString();
      return true;
    } catch (e) {
      console.warn(e);
      return false;
    }
  }

  public async refreshUserBalance() {
    const balance = await this.icService.get_balance(this.userWalletPrincipal);
    this.userWalletBalance = (balance ? balance : 0);
  }
}