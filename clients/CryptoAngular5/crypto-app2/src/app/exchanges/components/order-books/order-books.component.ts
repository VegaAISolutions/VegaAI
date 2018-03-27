import { Component, OnInit } from '@angular/core';
import { OrderDataService } from '../../services/order-data.service';
import { OrderBookData } from '../../models/order-book-data';
// tslint:disable-next-line:import-blacklist
import { Observable } from 'rxjs/Rx';
import { Subscription } from 'rxjs/Subscription';

@Component({
  selector: 'app-order-books',
  templateUrl: './order-books.component.html',
  styleUrls: ['./order-books.component.css']
})
export class OrderBooksComponent implements OnInit {
private tick: number;
private subscription: Subscription;
  constructor(private orderDataService: OrderDataService) { }

  orderData: OrderBookData = new OrderBookData();
  timer = Observable.timer(1000, 10000);
  ngOnInit() {
    this.orderDataService.getOrderBookData('BTC', 'ETH', '10', 'Poloniex').subscribe(data => {
      this.orderData = data;
      console.log(this.orderData);
    });
    this.subscription = this.timer.subscribe(t => {
      this.tick = t;
      this.orderDataService.getOrderBookData('BTC', 'ETH', '10', 'Poloniex').subscribe(data => {
        if (data !== undefined) {
        this.orderData = data;
        console.log(this.orderData);
      }
      });
    });
  }


  // tslint:disable-next-line:use-life-cycle-interface
  ngOnDestroy() {
    this.subscription.unsubscribe();
  }

}
