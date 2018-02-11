import pandas as pd
from flask import Flask, render_template
from flask import request
from flask_socketio import SocketIO

from Bots.MLBot import MLBot
# https://flask-socketio.readthedocs.io/en/latest/
# https://github.com/socketio/socket.io-client
from Bots.currencybot import CurrencyBot
from app.vegatrading.DataHelpers import DataHelper
import urllib.request
import Config.config as config



app = Flask(__name__)
socketio = SocketIO(app)

@app.route('/trading')
def show_table(n=5):

    dh = DataHelper('', '', '')
    ml = MLBot('Price')

    current = dh.get_current_data()

    exch1 = dh.get_coin_from_coinmarketcap('BTC', '2018-02-01')

    # plot1 = dh.get_coin_plot('BTC','2017-12-07')
    exch2 = dh.get_coin_from_coinmarketcap('ETH', '2018-02-01')

    exch = pd.concat([exch1, exch2])

    exch = exch[['Date', 'Name', 'Open', 'High', 'Low', 'Close', 'Volume', 'Market Cap']]
    return render_template('./VegaChat.html', tables=[current.to_html(classes='table table-hover table-striped'),
                                                      exch.to_html(classes='table table-hover table-striped')],
                           titles=['Exchanges'])

def messageReceived():
    print('message was received!!!')

@socketio.on('userevent')
def handle_my_custom_event(jsoninput):
    print('received my event: ' + str(jsoninput))
    cbot = CurrencyBot('Vega Currency Bot')
    bot_response = {}
    if 'data' in jsoninput != None and jsoninput['data'] == 'User Connected':
        bot_response = {'user_name': 'vegabot',
                        'message': 'Welcome to the Vega Interactive demo, please enter a user name and type a question to proceed!'}
        socketio.emit('vbotresponse', bot_response, callback=messageReceived)
    elif 'message' in jsoninput != None and jsoninput['message'] != '':
        bot_response = {'user_name': 'vegabot', 'message': 'Please wait a moment while I process your request.....'}
        socketio.emit('vbotresponse', bot_response, callback=messageReceived)
        socketio.sleep(1)
        bot_response = cbot.get_response_action(jsoninput['message'], jsoninput['user_name'])

        if type(bot_response) is list or type(bot_response) is tuple:
            for msg in bot_response:
                socketio.emit('vbotresponse', msg, callback=messageReceived)
        else:
           socketio.emit('vbotresponse', jsoninput, callback=messageReceived)
           socketio.emit('vbotresponse', bot_response, callback=show_table(5))

# Testing locally with ngrok
# https://ngrok.com/docs
# use this command with arguments:
# ngrok http 127.0.0.1:5001
# then set the web hook:
# https://api.telegram.org/bot(Token)/setWebhook?url=(ngrok service that redirects traffic to this local host app)
@app.route("/", methods=["GET", "POST"])
def receive():
    cbot = CurrencyBot('Vega Currency bot')
    try:
        cbot.run(request.json)
        return ""
    except Exception as e:
        print(e)
        return ""


if __name__ == '__main__':
    #work around for setting the telegram webhook
    with urllib.request.urlopen(
            config.telegram_final_webhook_url.format(config.telegram_bot_token,
                                                     config.telegram_webhook_url)) as response:
        html = response.read()
        print(html)
    socketio.run(app, host='0.0.0.0', port=5001, debug=False)

