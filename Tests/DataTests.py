import unittest
from datetime import datetime

from plotly.utils import pandas

from Config import config
from app.vegatrading.DataHelpers import DataHelper

'''
TODO: Start adding more test cases and mock stuff up. 
'''
class DataTests(unittest.TestCase):

    def test_exchange_data_kraken_data_retrieved(self):
        datahelper = DataHelper('quandl', '', config.quandl_key)
        result = datahelper.get_exchange_data('BCHARTS/KRAKENUSD')
        self.assertNotEqual(pandas.DataFrame.empty, result.empty)

    def test_poloniex(self):
        datahelper = DataHelper('pol','', config.pol_key)
        start = datetime.strptime('2015-01-01', '%Y-%m-%d')
        end = datetime.now()
        result = datahelper.get_coin_data_pol('BTC_ETH', start, end)
        self.assertNotEqual(pandas.DataFrame.empty, result.empty)

        coins = ['ETH', 'LTC', 'XRP', 'ETC', 'STR', 'DASH', 'SC', 'XMR', 'XEM']

        coin_data = datahelper.create_price_tables(coins, start, end)

        print(coin_data['ETH'].tail())

    '''
    Add more test cases later but this is just to make sure we get something back from the url. 
    '''
    def test_coin_desk(self):
        datahelper = DataHelper('','','')
        div = {'class': 'featured-holder'}
        url = "https://www.coindesk.com/"
        filter = ['bitcoin']
        list = datahelper.get_coin_articles(base_url=url,top=3)
        self.assertNotEqual(0,list.count)

        print(list)

class CurrencyBotTests(unittest.TestCase):

    def test_handle_currency_format(self):
        coin = 'BTC'
        datahelper = DataHelper('quandl', '', config.quandl_key)
        df = datahelper.get_exchange_data_no_cache('BCHARTS/KRAKENUSD')
        open = df['Open'].tail(1).map('${:,.2f}'.format).astype(str)

        # For now since this currency bot will be inside AWS lamba, since the actual calculation is fairly intensive.
        # TODO, setup AWS database service.
        self.assertNotEqual('',open.iloc[0])
        currencyformat = "For {} the predicted Open was {}".format(coin, open.iloc[0])
        print(currencyformat)
