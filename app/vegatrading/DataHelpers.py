'''
Author: Ryan Schreck
Date: 10/15/2017
Description: Helper methods class related to retrieving from the block chain in crypto currencies like ETC, BitCoin etc.
'''
import time
import pickle
import quandl
from pathlib import Path
from bs4 import BeautifulSoup
from Config import config
import requests
import json
import pandas as pd

class BaseHelper:
    api = ''
    api_id = ''
    cache_path = ''

    def set_cache_path(self, ex_id):
        cache_path = '{}.pkl'.format(ex_id).replace('/', '-')
        return cache_path

    def load_cache_file(self, cache_path):
        # if self.check_file(cache_path) == True:
        with open(cache_path, 'rb') as f:
            self.df = pickle.load(f)
            return self.df

    def load_df_by_api_cache(self, api, ex_id, cache_path, key):
        if api == 'quandl':
            quandl.ApiConfig.api_key = key
            self.df = quandl.get(ex_id, returns='pandas')
            self.df.to_pickle(cache_path)
            return self.df

    def load_df_by_api(self, api, ex_id, key):
        if api == 'quandl':
            quandl.ApiConfig.api_key = key
            self.df = quandl.get(ex_id, returns='pandas')
            return self.df

    def check_file(self, path):
        if path == '':
            return False
        file = Path(path)
        return file.is_file()


class DataHelper(BaseHelper):
    def __init__(self, api, api_id, key):
        self.api = api
        self.api_id = api_id
        self.key = key

    def get_fullname(self, coin):
        if coin == 'BTC':
            fullcoin = 'bitcoin'
        else:
            fullcoin = 'ethereum'
        return fullcoin

    def get_exchange_data(self, ex_id):
        self.df = pd.DataFrame
        try:
            cache_path = self.set_cache_path(ex_id)
            cache_path = self.load_cache_file(cache_path)
            self.df = self.load_df_by_api_cache(self.api, ex_id, cache_path, self.key)
        except(OSError, IOError):
            self.df = self.load_df_by_api_cache(self.api, ex_id, cache_path, self.key)
        except:
            print('There was an issue loading the exchange data')
        finally:
            pass
        return self.df

    def get_exchange_data_no_cache(self, ex_id):
        self.df = pd.DataFrame
        try:
            self.df = self.load_df_by_api(self.api, ex_id, self.key)
        except(OSError, IOError):
            self.df = self.load_df_by_api(self.api, ex_id, self.key)
        except:
            print('There was an issue loading the exchange data')
        finally:
            pass
        return self.df

    def get_coin_data_pol(self, coin, start_date, end_date, pediod=86400):
        try:
            json_url = config.pol_url.format(coin, start_date.timestamp(), end_date.timestamp(), pediod)
            data_df = pd.read_json(json_url)
            data_df = data_df.set_index('date')
            return data_df
        except() as e:
            print("Error: {}".format(e))

    def create_price_tables(self, coin_list, start, end):
        coin_data = {}
        for altcoin in coin_list:
            coinpair = 'BTC_{}'.format(altcoin)
            crypto_price_df = self.get_coin_data_pol(coinpair, start, end)
            coin_data[altcoin] = crypto_price_df

        #Create a new column for tomorrow's price
        for currentcoin in coin_data.keys():
            coin_data[currentcoin]['tomorrows_price'] = 500

        return coin_data

    #Helper method for coinmarket, it requires no API key.
    #Refactor later for more coins so focus just on BTC and ETH
    def get_coin_from_coinmarketcap(self,coin,start='2017-11-19'):
        fullcoin = self.get_fullname(coin)

        market = pd.read_html("https://coinmarketcap.com/currencies/{}/historical-data/?start=20130428&end=".format(fullcoin) + time.strftime("%Y%m%d"))[0]

        # Convert to a better date format.
        market = market.assign(Date=pd.to_datetime(market['Date']))

        try:
            market.loc[market['Volume'] == '-', 'Volume'] = 0
            # convert to int
            market['Volume'] = market['Volume'].astype('int64')
        except Exception as e:
            print(e)

        fullcoin = "{} ({})".format(fullcoin.capitalize(), coin.upper())
        market['Name'] = market.apply(lambda x:fullcoin, axis=1)
        market = market[market['Date'] >= start]

        market.Open = pd.to_numeric(market.Open)
        market.High = pd.to_numeric((market.High))
        market.Low = pd.to_numeric(market.Low)
        market.Close = pd.to_numeric(market.Close)
        market.Volume = pd.to_numeric(market.Volume)
        market['Market Cap'] = pd.to_numeric(market['Market Cap'])

        market['Open'] = market['Open'].map('${:,.2f}'.format).astype(str)
        market['High'] = market['High'].map('${:,.2f}'.format).astype(str)
        market['Low'] =  market['Low'].map('${:,.2f}'.format).astype(str)
        market['Close'] = market['Close'].map('${:,.2f}'.format).astype(str)
        market['Volume'] = market['Volume'].map('${:,.2f}'.format).astype(str)
        market['Market Cap'] = market['Market Cap'].map('${:,.2f}'.format).astype(str)

        return market

    def get_current_data(self, coins=['BTC','ETH']):
        url = "https://api.coinmarketcap.com/v1/ticker/"
        response = requests.get(url)
        soup = BeautifulSoup(response.content, "html.parser")
        dic = json.loads(soup.prettify())

        # create an empty DataFrame
        df = pd.DataFrame(columns=["Ticker", "CurrentPriceUSD", "Volume24hUSD","MarketCapUSD","PC1h","PC24h","PC7d"],index=[])

        for i in range(len(dic)):
            df.loc[len(df)] = [dic[i]['symbol'], dic[i]['price_usd'], dic[i]['24h_volume_usd'], dic[i]['market_cap_usd']
                               ,dic[i]['percent_change_1h'], dic[i]['percent_change_24h'], dic[i]['percent_change_7d']]

        df.sort_values(by=['Ticker'])
        # apply conversion to numeric as 'df' contains lots of 'None' string as values
        df.CurrentPriceUSD = pd.to_numeric(df.CurrentPriceUSD)
        df.Volume24hUSD = pd.to_numeric((df.Volume24hUSD))
        df.MarketCapUSD = pd.to_numeric(df.MarketCapUSD)
        df.PC1h = pd.to_numeric(df.PC1h)
        df.PC24h = pd.to_numeric(df.PC24h)
        df.PC7d = pd.to_numeric(df.PC7d)
        df = df[(df['Ticker'].isin(coins))]

        df['CurrentPriceUSD'] = df['CurrentPriceUSD'].map('${:,.2f}'.format).astype(str)
        df['Volume24hUSD'] = df['Volume24hUSD'].map('${:,.2f}'.format).astype(str)
        df['MarketCapUSD'] = df['MarketCapUSD'].map('${:,.2f}'.format).astype(str)
        df['PC1h'] = df['PC1h'].map('%{:,.2f}'.format).astype(str)
        df['PC24h'] = df['PC24h'].map('%{:,.2f}'.format).astype(str)
        df['PC7d'] = df['PC7d'].map('%{:,.2f}'.format).astype(str)

        #Add call to method that determines market status.
        #df['Status'] = 'Bull'
        df = df[["Ticker", "CurrentPriceUSD", "Volume24hUSD","MarketCapUSD","PC1h","PC24h","PC7d"]]
        return df

    def merge_dfs_on_column(dataframes, labels, col):
        '''Merge a single column of each dataframe into a new combined dataframe'''
        series_dict = {}
        for index in range(len(dataframes)):
            series_dict[labels[index]] = dataframes[index][col]

        return pd.DataFrame(series_dict)

    '''
    Helper method for parsing articles from coin, desk.
    get all the hrefs from the main feature div on the coin desk main page.
    it is named <div class="featured-holder"> and its children are
    <div class="main-feature">
    <div class="article article-featured">
    '''
    def get_coin_articles(self,base_url,top=3,attr={'class': 'featured-holder'}):
        #cdesk = 'https://www.coindesk.com/'
        response = requests.get(base_url)
        page = BeautifulSoup(response.content, "html.parser")

        #data = page.find_all('div', attrs={'class': 'featured-holder'})
        data = page.find_all('div', attr)

        if data == []:
            data = page.find_all('a',href=True)
        list = []
        count = 0

        for div in data:
            links = div.findAll('a')
            for a in links:
                if count < top:
                   url = str(a['href'])
                   list.append(url)
                count+=1
            print(a['href'])

        return list
