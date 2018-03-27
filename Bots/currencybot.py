from datetime import datetime
import os
import requests
import urllib3

from Config import config
# The main URL for the Telegram API with our bot's token
from Bots.BaseBot import BaseBot
from Bots.MLBot import MLBot
from app.vegatrading.DataHelpers import DataHelper
from telegram.ext import Updater, CommandHandler, MessageHandler, Filters
import zmq

class CurrencyBot(BaseBot):
    def __init__(self, name):
        self.name = name
        self.BASE_URL = "https://api.telegram.org/bot{}".format(config.telegram_bot_token)
        self.c = zmq.Context()
        print("Connecting to the mt4 server.")
        self.socket = self.c.socket(zmq.REQ)
        self.socket.connect("tcp://127.0.0.1:5557")

    def parse_coin_data(self, query):
        url = self.intent_url_template.format(query, datetime.now())
        headers = {"Authorization": config.apiai_bearer}
        response = requests.get(url, headers=headers)
        js = response.json()
        print(js)
        coin = ""
        try:
            coin = js['result']['parameters']['coin2'].strip('/').strip('@').strip('|').strip()
            if coin == "":
                print("Coin was {}".format())
            return coin
        except Exception as e:
            print(e)
            print("Issue with getting data from the json")
        else:
            coin = ""
        return coin.strip()

    def receive_message(self, message):
        """Receive a raw message from Telegram"""
        try:
            text = str(message["message"]["text"]).strip().strip('/').strip('@')
            chat_id = message['message']['chat']['id']
            user = message['message']['from']['first_name']
            return text, chat_id, user
        except Exception as e:
            print(e)
            print(message)
            return (None, None,None)

    def handle_message(self, message, user_name='user_name'):
        """Retrieve data"""
        action = self.get_action(message)
        print(action)
        #For now return a status of a bull market.
        if action == "GetMarketStatus":
            coin = self.parse_coin_data(message)
            ml = MLBot('ML Bot')

            nd, pt = ml.predict_coin(coin,unit='month',api='spec',model_type='random_forest')
            return pt
        coin = self.parse_coin_data(message)
        data = DataHelper('quandl', '', config.quandl_key)

        if coin.upper() == 'BTC':
            # TODO, add more advanced analysis such as predicted price
            df = data.get_exchange_data_no_cache('BCHARTS/KRAKENUSD')
            open = df['Open'].tail(1).map('${:,.2f}'.format).astype(str)

            #For now since this currency bot will be inside AWS lamba, since the actual calculation is fairly intensive.
            #TODO, setup a Google or AWS database service.
            return "For {} the predicted Opening price is {}".format(coin, open.iloc[0])
        else:
            data = DataHelper('pol', '', config.pol_key)
            start = datetime.strptime('2015-01-01', '%Y-%m-%d')
            end = datetime.now()
            df = data.get_coin_data_pol(coin, start, end)
            open = df['open'].tail(1).map('${:,.2f}'.format).astype(str)
            return "For {} the predicted Opening price was {}".format(coin, open.iloc[0])

    def send_message(self, message, chat_id):
        """Send a message to the Telegram chat defined by chat_id"""
        data = {"text": message.encode("utf8"), "chat_id": chat_id}
        url = self.BASE_URL + "/sendMessage"
        try:
            response = requests.post(url, data).content
        except Exception as e:
            print(e)

    def get_response_action(self, message, user_name='user_name', thirdParty=False):
        if message != '':
            #action = self.get_action(message)
            response = self.get_js(message)
            action = response['result']['action']
            print(action)

            if action == '':
                bot_response = {'user_name': 'vegabot',
                                'message': '{}, I did not quite get that, please rephrase your question.'.format(
                                    user_name)}
                return bot_response
            # For now return a status of a bull market.
            #TODO:  Need to pull short-term market status from investing.com
            elif action == "GetMarketStatus":

                coin = self.parse_coin_data(message)
                #ml = MLBot('ML Bot')
                urls = []
                urls.append('https://www.tradingview.com/chart/cGDlSoxr/')
                #nd, pt = ml.predict_coin(coin, unit='month', api='spec', model_type='random_forest')
                pt = self.format_urls(urls,thirdParty)
                bot_response_list = []
                for link in pt:
                    bot_response = {'user_name': 'vegabot', 'message': '{}'.format(link)}
                    bot_response_list.append(bot_response)
                return bot_response_list

            elif action == 'GetMediaInfo':
                #TODO: work on the twitter data retrieval.
                #TODO: work on the coin filtering for coindesk.
                '''                
                coindesk ETH
                coindesk
                coindesk BTC
                Can I get some articles from coindesk for BTC?
                How its going on twitter for BTC?
                Can I get some articles from coindesk?
                '''
                d = DataHelper('','','')
                coin = self.parse_coin_data(message)
                if coin == '':
                    coin = 'BTC'
                media = self.get_media(message)
                top = 3

                #business logic on which source to hit.
                #TODO refactor later - 12/3/2017.
                if coin.strip().upper() == 'BTC':
                    if media.strip() =='coindesk' or media.strip() == 'coindesk.com':
                        div = {'class': 'category-content'}
                        url = "https://www.coindesk.com/category/technology-news/bitcoin/"
                        #filter = ' '
                    else:
                        div = {'class': 'articleItem'}
                        url= 'https://www.investing.com/crypto/bitcoin/'
                        #filter = 'bitcoin'
                elif coin.strip().upper() == 'ETH' or media.strip() == 'coindesk.com':
                    if media.strip() == 'coindesk':
                        div = {'class': 'category-content'}
                        url = "https://www.coindesk.com/category/technology-news/ethereum-technology-news/"
                    elif media.strip() == 'investing' or media == 'investing.com':
                        div = {'class': 'articleItem'}
                        url = 'https://www.investing.com/crypto/ethereum/'
                        #filter = 'ethereum'

                urls = d.get_coin_articles(base_url=url,top=top,attr=div)

                #work around, beautifulsoup can't seem to parse articles from investing.com
                #from looking at their site in dev tools, they are using some sort of 3rd party cache and beautiful soup
                #gets a 403 error.
                if urls == [] and coin == 'BTC':
                    urls.append('https://www.investing.com/news/cryptocurrency-news/for-security-agencies-blockchain-goes-from-suspect-to-potential-solution-945472')
                    urls.append('http://bitcoinist.com/yoyow-announces-yoyo-tokens-listed-bitfinex/')
                    urls.append('https://nypost.com/2017/12/02/the-launch-of-bitcoin-futures-is-getting-politicians-attention/')
                elif urls == [] and coin == 'ETH':
                    urls.append('https://cointelegraph.com/news/viral-cat-game-responsible-for-huge-portion-of-ethereum-transactions')
                    urls.append('http://www.zerohedge.com/news/2017-12-01/frustrated-investors-file-lawsuits-against-worlds-largest-ico')
                    urls.append('http://www.zerohedge.com/news/2017-12-01/signs-market-top-pole-dancing-instructor-now-bitcoin-guru')
                s = self.format_urls(urls, thirdParty)

                bot_response_list = []
                bot_response = {'user_name': 'vegabot','message': 'The top {} urls from {} for {} are:'.format(top, media, coin)}
                bot_response_list.insert(0, bot_response)
                for link in s:
                    bot_response = {'user_name': 'vegabot','message': '{}'.format(link)}
                    bot_response_list.append(bot_response)
                return bot_response_list
            elif action == 'GetTaxes':
                taxkeywords = response['result']['parameters']['taxkeywords']
                taxkeywords1 = response['result']['parameters']['taxkeywords1']
                query = response['result']['resolvedQuery']
                #Add scraper last
                regs = ['regulations', 'crackdown']
                forms8949 = ['8949', 'Form 8949 Instructions', 'Form 1099-K', 'Form 8949']
                forms1099K = ['Form 1099-K', 'Form 1099-K Instructions', '1099-K', '1099']

                if taxkeywords.strip() in regs or query.strip() in 'What are the new cryptocurrency regulations from the IRS?':
                    urls = ['http://fortune.com/2017/12/21/bitcoin-tax/',
                            'https://www.irs.gov/newsroom/irs-virtual-currency-guidance',
                            'https://www.investopedia.com/university/definitive-bitcoin-tax-guide-dont-let-irs-snow-you/']

                    s = self.format_urls(urls, thirdParty)
                    bot_response = {'user_name':'vegabot', 'message': 'Articles related to crypto currency regulation {}'.format(s)}
                elif taxkeywords.strip() in forms8949 or taxkeywords1.strip() in forms8949:
                    url = ['https://www.irs.gov/instructions/i8949']
                    s = self.format_urls(url,thirdParty=thirdParty)
                    bot_response = {'user_name': 'vegabot','message': '8949 info {}'.format(s)}
                elif taxkeywords.strip() in forms1099K or taxkeywords1.strip() in forms1099K:
                    url = ['https://www.irs.gov/businesses/understanding-your-1099-k']
                    s = self.format_urls(url,thirdParty=thirdParty)
                    bot_response = {'user_name': 'vegabot', 'message': '1099-K info {}'.format(s)}
                else:
                    bot_response = {'user_name':'vegabot', 'message':'I did not quite understand your question, please ask again.'}

                return bot_response
            elif action == 'GetWaveFiveTrade':
                bot_response_list = []
                d = DataHelper('','','')
                #urls = d.get_wavefive_articles(self)
                urls = []
                #formatted_urls = self.format_urls(urls, thirdParty)
                formatted_urls = []
                urls.append('http://www.wave5trade.com/education/w5t-monthly-webinar-february-2018/')
                urls.append('http://www.wave5trade.com/education/fl-short-stocks-swing-trading-idea/')
                formatted_urls = self.format_urls(urls, thirdParty)
                bot_response = {'user_name': 'vegabot','message': 'The top {} urls from {} are:'.format('2', 'wave5')}
                bot_response_list.insert(0,bot_response)
                for link in formatted_urls:
                    bot_response = {'user_name': 'vegabot','message':'{}'.format(link)}
                    bot_response_list.append(bot_response)
                return bot_response_list
            elif action == 'BuyAction':
                default_msg = response['result']['fulfillment']['speech']
                print(message)
                self.socket.send_string(message, encoding='utf-8')
                bot_response = {'user_name': 'vegabot', 'message': '{}, {}'.format(user_name, default_msg.strip('|'))}
                return bot_response
            elif action == 'SellAction':
                default_msg = response['result']['fulfillment']['speech']
                self.socket.send_string(message)
                bot_response = {'user_name': 'vegabot', 'message': '{}, {}'.format(user_name, default_msg)}
                return bot_response
            elif action == 'IndicatorAction':
                default_msg = response['result']['fulfillment']['speech']
                self.socket.send_string('start vegabot',encoding='utf-8')

                if self.socket.recv() != 'bot started':
                    default_msg = 'There was an issue starting the bot'

                bot_response = {'user_name': 'vegabot', 'message': '{}, {}'.format(user_name, default_msg)}
                return bot_response
            else:
                coin = self.parse_coin_data(message)
                mlbot = MLBot('Prediction Bot')
                predicted_price = mlbot.predict_coin_price(coin)
                predicted_price['TPrice'] = predicted_price['TPrice'].map('${:,.2f}'.format).astype(str)
                bot_response = {'user_name': 'vegabot',
                                'message': 'Ok, {} the predicted closing price for {} tomorrow is {}.'.format(
                                    user_name, coin, predicted_price.iloc[0][0])}
                return bot_response

        elif message == '':
            bot_response = {'user_name': 'vegabot','message': '{}, please enter a valid query.'.format(user_name)}
            return bot_response

    def format_urls(self,urls, thirdParty):
        s = []
        for item in urls:
            if not thirdParty:
                s.append('<a href="' + item + '">' + item + '</a><br> ')
            else:
                s.append(item + '\n ')
        return s
    def run(self, message, thirdParty=True):
        """Receive a message, handle it, and send a response"""
        try:
            message, chat_id, user = self.receive_message(message)
            if message != None and message != '/start' and message != 'start' and message != '':
                print(chat_id)
                response = self.get_response_action(message, thirdParty=thirdParty,user_name=user)
                if type(response) is list or type(response) is tuple:
                    for msg in response:
                        self.send_message(msg['message'], chat_id)
                else:
                    self.send_message(response['message'], chat_id)
            else:
                self.send_message('Welcome {}, please ask me questions related to crypto!'.format(user), chat_id)
        except Exception as e:
            print(e)
