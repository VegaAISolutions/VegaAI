import os

telegram_bot_token=os.environ['telegram_bot_token']
apiai_bearer=os.environ['apiai_bearer']
quandl_key = os.environ['quandl_key']
#Create a test account and get this info from your API key profile.
pol_key = os.environ['pol_key']
pol_secret = os.environ['pol_secret']
pol_url = 'https://poloniex.com/public?command=returnChartData&currencyPair={}&start={}&end={}&period={}'
taxreport_base = '/VegaIS/app/taxreports/'
reports_db = '/VegaIS/app/taxreports/'
uploads = '/VegaIS/app/taxreports/uploads/'
downloads = '/VegaIS/app/taxreports/downloads/'
telegram_ip = os.environ['telegram_ip']
telegram_port = os.environ['telegram_port']
telegram_webhook_url = os.environ['telegram_webhook_url']
telegram_final_webhook_url = os.environ['telegram_final_webhook_url']