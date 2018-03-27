import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AppComponent } from './app.component';
import { CommonModule } from '@angular/common';
import { OrderBooksComponent } from './exchanges/components/order-books/order-books.component';

const routes: Routes = [
  {
    path: '',
    redirectTo: '',
    pathMatch: 'full'
  },
  {
    path: 'overall',
    component: AppComponent
  },
  { path: 'orderbook',
    component: OrderBooksComponent
  }
];

@NgModule({
  imports: [
    CommonModule, RouterModule.forRoot(routes)
  ],
  declarations: []
})
export class AppRoutingModule { }
