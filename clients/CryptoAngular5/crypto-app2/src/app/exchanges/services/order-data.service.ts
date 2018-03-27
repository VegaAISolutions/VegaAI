import { Injectable } from '@angular/core';
import { Observable } from 'rxjs/Observable';
import { OrderBookData } from '../models/order-book-data';
import { Http } from '@angular/http';
import 'rxjs/add/operator/map';
import 'rxjs/add/operator/catch';
import 'rxjs/add/observable/throw';

@Injectable()
export class OrderDataService {

  constructor(private httpClient: Http) { }

  getOrderBookData(from, to, depth, exchange): Observable<OrderBookData> {
    const orderBook = new OrderBookData();
    orderBook.FromCoinName = from;
    orderBook.ToCoinName = to;
    orderBook.Exchange = exchange;
    // The way the data looks coming from poloniex, first index of each tuple is the from and the second is the to
    // BTC to ETH
    orderBook.Asks = [['0.00001586', 241.09884045], ['0.00001588', 2305.34030398],
                    ['0.00001589', 7031.43685552], ['0.00001592', 43.07815723],
                    ['0.00001594', 9651.656], ['0.00001595', 20025.73290803],
                    ['0.00001598', 18542.53497648], ['0.00001600', 55822.61643582],
                    ['0.00001601', 22755.271], ['0.00001602', 106.01969366]];

    orderBook.Bids = [['0.00001574', 8749.18147704], ['0.00001573', 4956.92184277],
                      ['0.00001572', 1859.37875449], ['0.00001571', 31891.66488739],
                      ['0.00001570', 20484.32950675], ['0.00001569', 107151.3986307],
                      ['0.00001567', 6725.836], ['0.00001566', 2726.72733078],
                      ['0.00001565', 2509.11028173], ['0.00001564', 46415.75383888]];
    orderBook.IsFrozen = '0';
    orderBook.Seq = 509799096;
    orderBook.Depth = depth;
    const command = 'command=returnOrderBook';
    const currencyPair = 'currencyPair=' + from + '_' + to;
    const orderDepth = 'depth=' + depth;
    const url = 'https://poloniex.com/public?' + command + '&' + currencyPair + '&' + orderDepth;

    return this.httpClient.get(url).map(response => {
      const orders = response.json();
      orderBook.Asks = orders.asks;
      orderBook.Bids = orders.bids;
      orderBook.Seq = orders.seq;
      return orderBook;
    }).catch(this.handleError);
  }

  private handleError (error: Response | any) {
    console.error('ApiService::handleError', error);
    return Observable.throw(error);
  }

}
