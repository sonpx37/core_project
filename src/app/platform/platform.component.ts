import { Component, OnInit } from '@angular/core';
import { UserAuthService } from '../user-auth.service';

@Component({
  selector: 'app-platform',
  templateUrl: './platform.component.html',
  styleUrls: ['./platform.component.css']
})
export class NftPlatformComponent implements OnInit {
  public currentModule: string = 'all';

  constructor(
    public authService: UserAuthService
  ) { }

  ngOnInit(): void { }

}