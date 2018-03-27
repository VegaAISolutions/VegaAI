"""
 Copyright (C) 2017 Michael von den Driesch
 This file is just a simple implementation of a python class allowing for various
 *booking* types (LIFO, FIFO, AVCO)
 This *GIST* is free software: you can redistribute it and/or modify it
 under the terms of the BSD-2-Clause (https://opensource.org/licenses/bsd-license.html).
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE.  See the license for more details.

 retrieved from https://gist.github.com/mdriesch/da65371d512791f8ca6d2b3827cef38c
 Modified for use by Vega, LLC 2018
"""


from collections import deque
import pandas as pd
import numpy as np
import datetime as dt
from enum import Enum

refDate = pd.to_datetime('01.04.2016', format='%d.%m.%Y')


class Trade():
    def __init__(self, date: pd.datetime, quantity: np.float32, price: np.float32):
        self.date = date
        self.quantity = quantity
        self.price = price

    def printT(self):
        return print('Quantity: %i, Price: %f' % (self.quantity, self.price))


class Isin():
    def __init__(self, isin, notinalPerQuantity, listOfTrades, method='FIFO'):
        self._isin = isin
        self._notinalPerQuantity = notinalPerQuantity
        if method == 'LIFO':
            self._listOfTrades = listOfTrades.reverse()
        self._listOfTrades = listOfTrades

    def mtm(self, trade):
        return trade.quantity * trade.price * self._notinalPerQuantity

    def __next__(self):
        return self._listOfTrades.__next__()

    def __iter__(self):
        return self._listOfTrades.__iter__()


class transactionAccounting():
    def __init__(self, isin):
        """
        Initiliase with first entry from left
        """
        print('Initialize trade que')
        self._Isin = isin
        self._notinalPerQuantity = isin._notinalPerQuantity
        self._trades = isin._listOfTrades
        t0 = self._trades[0]
        self._avgprice = 0
        self._quantity = 0
        self._pnl = 0
        self._bookvalue = 0

    def printStat(self):
        print('Pos.Quantity: %i, AvgPrice: %f, PnL: %f, Book: %f' % (self._quantity,
                                                                     self._avgprice,
                                                                     self._pnl,
                                                                     self._bookvalue))

    def buy(self, trade):
        raise NotImplementedError

    def sell(self, trade):
        raise NotImplementedError


class FifoAccount(transactionAccounting):
    """
    checkout out this site for an example
    http://accountingexplained.com/financial/inventories/fifo-method
    """

    def __init__(self, trades):
        transactionAccounting.__init__(self, trades)
        self._deque = deque()
        #Make sure to append the buys first
        for trade in self._trades:
            if trade.quantity >= 0:
                self.buy(trade)
        for trade in self._trades:
            if trade.quantity <= 0:
                self.sell(trade)

    def buy(self, trade):
        print('Buy trade')
        trade.printT()
        self._deque.append(trade)
        self._bookvalue += self._Isin.mtm(trade)
        self._quantity += trade.quantity
        self._avgprice = self._bookvalue / self._quantity / self._notinalPerQuantity
        self.printStat()

    def sell(self, trade):
        print('Sell trade')
        trade.printT()
        sellQuant = -trade.quantity
        while (sellQuant > 0):
            lastTrade = self._deque.popleft()
            price = lastTrade.price
            quantity = lastTrade.quantity
            print('Cancel trade:')
            lastTrade.printT()
            if sellQuant >= quantity:
                self._pnl += -(price - trade.price) * quantity * self._notinalPerQuantity
                self._quantity -= quantity
                self._bookvalue -= price * quantity * self._notinalPerQuantity
                sellQuant -= quantity
            else:
                # from IPython.core.debugger import Tracer; Tracer()()
                self._pnl += -(price - trade.price) * sellQuant * self._notinalPerQuantity
                self._quantity -= sellQuant
                self._bookvalue -= price * sellQuant * self._notinalPerQuantity
                lastTrade.quantity -= sellQuant
                self._deque.appendleft(lastTrade)
                sellQuant = 0
            self.printStat()
            assert (self._quantity > 0)

    def get_pnl(self):
        return self._pnl

    def get_avgprice(self):
        return self._avgprice

    def get_bookvalue(self):
        return self._bookvalue

class LifoAccount(transactionAccounting):
    """
        checkout out this site for an example
        http://accountingexplained.com/financial/inventories/lifo-method
        """

    def __init__(self, trades):
        transactionAccounting.__init__(self, trades)
        #reverse the collection
        self._deque = deque()
        # Make sure to append the buys first
        for trade in self._trades:
            if trade.quantity >= 0:
                self.buy(trade)

        for trade in self._trades:
            if trade.quantity <= 0:
                self.sell(trade)

    def buy(self, trade):
        print('Buy trade')
        trade.printT()
        self._deque.append(trade)
        self._bookvalue += self._Isin.mtm(trade)
        self._quantity += trade.quantity
        self._avgprice = self._bookvalue / self._quantity / self._notinalPerQuantity
        self.printStat()

    def sell(self, trade):
        print('Sell trade')
        trade.printT()
        sellQuant = -trade.quantity
        while (sellQuant > 0):
            try:
                lastTrade = self._deque.popleft()
                price = lastTrade.price
                quantity = lastTrade.quantity
                print('Cancel trade:')
                lastTrade.printT()
                if sellQuant >= quantity:
                    self._pnl += -(price - trade.price) * quantity * self._notinalPerQuantity
                    self._quantity -= quantity
                    self._bookvalue -= price * quantity * self._notinalPerQuantity
                    sellQuant -= quantity
                else:
                    # from IPython.core.debugger import Tracer; Tracer()()
                    self._pnl += -(price - trade.price) * sellQuant * self._notinalPerQuantity
                    self._quantity -= sellQuant
                    self._bookvalue -= price * sellQuant * self._notinalPerQuantity
                    lastTrade.quantity -= sellQuant
                    self._deque.appendleft(lastTrade)
                    sellQuant = 0
                self.printStat()
                assert (self._quantity > 0)
            except Exception as e:
                print(e)
                break

    def get_pnl(self):
        return self._pnl

    def get_avgprice(self):
        return self._avgprice

    def get_bookvalue(self):
        return self._bookvalue