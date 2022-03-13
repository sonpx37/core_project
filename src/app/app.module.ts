import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { BrowserModule } from '@angular/platform-browser';

import { AppComponent } from './app.component';
import { MintNftComponent } from './mint/mint.component';
import { CollectionComponent } from './collection/collection.component';
import { NftPlatformComponent } from './platform/platform.component';

@NgModule({
  declarations: [
    AppComponent,
    MintNftComponent,
    CollectionComponent,
    NftPlatformComponent
  ],
  imports: [
    BrowserModule,
    FormsModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }