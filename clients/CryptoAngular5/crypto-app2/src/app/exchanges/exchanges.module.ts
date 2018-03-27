import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ExchangePricesComponent } from './components/exchange-prices/exchange-prices.component';
import { OrderBooksComponent } from './components/order-books/order-books.component';
import { OverallCoinPricesComponent } from './components/overall-coin-prices/overall-coin-prices.component';

@NgModule({
  imports: [
    CommonModule
  ],
  declarations: [ExchangePricesComponent, OrderBooksComponent, OverallCoinPricesComponent]
})
export class ExchangesModule { }
