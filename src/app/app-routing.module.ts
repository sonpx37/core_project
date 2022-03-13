import { NgModule } from "@angular/core";
import { RouterModule, Routes } from "@angular/router";
import { CollectionComponent } from "./collection/collection.component";

const routes: Routes = [
  { path: "collections", component: CollectionComponent },
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule],
})
export class AppRoutingModule {}
