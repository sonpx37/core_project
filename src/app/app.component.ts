import { Component, OnInit } from "@angular/core";
import { UserAuthService } from "./user-auth.service";

@Component({
  selector: "app-root",
  templateUrl: "./app.component.html",
  styleUrls: ["./app.component.css"],
})
export class AppComponent implements OnInit {
  public appTitle: string = "MOKOTO BOOTCAMP";
  public showAppContents: boolean = false;
  public showNftPlatform: boolean = false;
  public plugAuthProcessing: boolean = false;

  constructor(public authService: UserAuthService) {}

  ngOnInit(): void {
    this.checkWalletConnectionStatus();
  }

  public continueWithoutLogin() {
    this.showNftPlatform = true;
  }

  public logout() {
    // remove user public key
    delete this.authService.userWalletPrincipal;
    this.authService.userWalletBalance = 0;
    // show welcome screen
    this.showNftPlatform = false;
  }

  // public showNfts() {
  //   this.router.navigateByUrl("/collection");
  // }

  public async plugAuthentication() {
    this.plugAuthProcessing = true;
    const plugAuthStatus = await this.authService.connectToPlugWallet();
    if (plugAuthStatus) {
      await this.authService.refreshUserBalance();
      this.showNftPlatform = true;
      this.plugAuthProcessing = false;
    } else if (plugAuthStatus === null) {
      // open browser tab to PlugWallet website
      window.open("https://plugwallet.ooo/", "_blank");
      this.plugAuthProcessing = false;
    } else {
      this.plugAuthProcessing = false;
    }
  }

  private async checkWalletConnectionStatus() {
    const isLoggedIn = await this.authService.getPlugWalletConnection();
    if (isLoggedIn) {
      await this.authService.refreshUserBalance();
      this.showNftPlatform = true;
    }
    this.showAppContents = true;
  }
}
