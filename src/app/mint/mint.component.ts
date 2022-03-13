import { Component, OnDestroy, OnInit } from '@angular/core';
import { IcService } from '../ic.service';
import { UserAuthService } from '../user-auth.service';

@Component({
  selector: 'app-mint',
  templateUrl: './mint.component.html',
  styleUrls: ['./mint.component.css']
})
export class MintNftComponent implements OnInit, OnDestroy {
  public nftUrl: string = '';
  public nftPrincipal: string = '';
  public mintInProcess: boolean = false;
  public showSuccessMsg: boolean = false;
  public showErrorMsg: boolean = false;
  public showSuccessMsgTimeout: any;

  constructor(
    public authService: UserAuthService,
    private icService: IcService
  ) { }

  ngOnInit(): void {
    if (this.authService.userWalletPrincipal) {
      this.nftPrincipal = this.authService.userWalletPrincipal;
    }
  }

  ngOnDestroy(): void {
    if (this.showSuccessMsgTimeout) {
      clearTimeout(this.showSuccessMsgTimeout);
      delete this.showSuccessMsgTimeout;
    }
  }

  public mintDisabled() {
    if (
      !this.mintInProcess &&
      this.nftUrl &&
      this.nftUrl !== '' &&
      this.nftPrincipal &&
      this.nftPrincipal !== ''
    ) {
      return false;
    }
    return true;
  }

  public async mintNft() {
    // Hide success/error message
    this.showSuccessMsg = false;
    this.showSuccessMsg = false;
    // Lock submit button while minting
    this.mintInProcess = true;

    // Service call - Promise
    const response = await this.icService.mint_principal(this.nftUrl, this.nftPrincipal);
    if (response === false) {
      // Error while minting - invalid principal - show error message
      this.showErrorMsg = true;
    } else {
      // Minting finished - refresh balance, clear NFT-URL input and show success message
      await this.authService.refreshUserBalance();
      this.nftUrl = '';
      this.showSuccessMsg = true;
    }
    this.mintInProcess = false;
    this.showSuccessMsgTimeout = setTimeout(() => {
      this.showSuccessMsg = false;
      this.showErrorMsg = false;
    }, 5000);
  }
}