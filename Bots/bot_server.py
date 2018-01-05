from flask import Flask
from flask import request
from Bots.currencybot import CurrencyBot

app = Flask(__name__)
 #This can be a stand alone service hosted in AWS lambda or other server.
@app.route("/", methods=["GET", "POST"])
def receive():
    cbot = CurrencyBot('Vega Currency bot')
    try:
        cbot.run(request.json, thirdParty=True)
        return ""
    except Exception as e:
        print(e)
        return ""

app.run(debug=True,host='127.0.0.1',port=5000,threaded=True)