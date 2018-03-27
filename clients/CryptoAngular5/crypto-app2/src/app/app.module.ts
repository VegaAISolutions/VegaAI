import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { HttpModule } from '@angular/http';
import { AppComponent } from './app.component';
import { AppHeaderComponent } from './app-header/app-header.component';
import { OrderBooksComponent } from './exchanges/components/order-books/order-books.component';
import { OverallCoinPricesComponent } from './exchanges/components/overall-coin-prices/overall-coin-prices.component';
import { ExchangePricesComponent } from './exchanges/components/exchange-prices/exchange-prices.component';
import { ExchangeDataServiceService } from './exchanges/services/exchange-data-service.service';
import { OrderDataService } from './exchanges/services/order-data.service';


@NgModule({
  declarations: [
    AppComponent,
    AppHeaderComponent,
    ExchangePricesComponent,
    OrderBooksComponent,
    OverallCoinPricesComponent
  ],
  imports: [
    BrowserModule,
    FormsModule,
    HttpModule
  ],
  providers: [ExchangeDataServiceService, OrderDataService],
  bootstrap: [AppComponent]
})
export class AppModule { }
