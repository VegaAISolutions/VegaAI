telegram_bot_token=""
apiai_bearer="Bearer "
quandl_key = "quandl token goes here"
#Create a test account and get this info from your API key profile.
pol_key = "API key goes here"
pol_secret = "Secret goes here"
pol_url = 'https://poloniex.com/public?command=returnChartData&currencyPair={}&start={}&end={}&period={}'
taxreport_base = 'C:/VegaIS/app/taxreports/'
reports_db = 'C:/VegaIS/app/taxreports/'
uploads = 'C:/VegaIS/app/taxreports/uploads/'
downloads = 'C:/VegaIS/app/taxreports/downloads/'
telegram_ip = ''
telegram_port = ''
telegram_webhook_url = ''
telegram_final_webhook_url = 'https://api.telegram.org/bot{}/setWebhook?url={}'
#date format '2018-02-17' dsplit_date must be later dstart_date
dstart_date = '2018-01-16'
dsplit_date = '2018-02-17'
#recommended '100' to '1000'
rnn_ephocs = 1500