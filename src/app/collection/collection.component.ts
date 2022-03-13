import { Component, Input, OnChanges, SimpleChanges } from '@angular/core';
import { IcService } from '../ic.service';
import { UserAuthService } from '../user-auth.service';

@Component({
  selector: 'app-collection',
  templateUrl: './collection.component.html',
  styleUrls: ['./collection.component.css']
})
export class CollectionComponent implements OnChanges {
  @Input() public currentModule!: string;
  public collection: any[] | undefined;
  public principal: string = '';
  public getDataInProcess: boolean = false;
  public requestWasSent: boolean = false;
  public tokenPrice: number = 300;
  public buyNftData: any;
  public buyNftInProcess: boolean = false;

  constructor(
    private icService: IcService,
    public authService: UserAuthService
  ) { }

  ngOnChanges(changes: SimpleChanges): void {
    this.principal = '';
    delete this.collection;
    if (this.authService.userWalletPrincipal) {
      this.principal = this.authService.userWalletPrincipal;
    }
    if (this.principal !== '' || this.currentModule === 'all') {
      this.getNftCollectionData();
    }
  }

  public async getNftCollectionData(skipLoadingSpinner?: boolean) {
    this.requestWasSent = true;
    if (!skipLoadingSpinner) {
      this.getDataInProcess = true;
    }
    // Service call - Promise
    let response;
    if (this.currentModule === 'all') {
      // All NFTs
      response = await this.icService.getAllToken();
    } else {
      // NFTs of the current user
      response = await this.icService.getPrincipalsToken(this.principal);
    }
    if (response && response?.length) {
      const collection: any[] = [];
      response.forEach((nft: any) => {
        nft.creator = nft.creator.toString();
        nft.principal = nft.principal.toString();
        nft.tokenId = parseInt(nft.tokenId);
        
        collection.push(nft);
      });
      this.collection = collection;
    } else {
      delete this.collection;
    }
    if (!skipLoadingSpinner) {
      this.getDataInProcess = false;
    }
  }

  public async buyNft(nft: any) {
    await this.authService.refreshUserBalance();
    this.buyNftData = nft;
  }

  public async buyNftDoTransaction() {
    this.buyNftInProcess = true;
    // do transaction
    // transferFrom
   
    const response = await this.icService.transferFrom(this.buyNftData.principal, this.authService.userWalletPrincipal, this.buyNftData.tokenId);
   
    // get new Balance
    await this.authService.refreshUserBalance();
    // get new NFT list data
    await this.getNftCollectionData(true);
    // close and reset NftBuyData
    this.buyNftInProcess = false;
    this.resetNftBuyData();
  }

  public resetNftBuyData() {
    delete this.buyNftData;
  }

}