from Config import config
import requests
from datetime import datetime

class BaseBot:
    intent_url_template = "https://api.dialogflow.com/v1/query?v=20170712&query={}&lang=en&sessionId={}"

    def __init__(self, name):
        self.name = name

    def get_js(self,query):
        print(query)
        print(type(query))
        # query = quote(query)
        url = self.intent_url_template.format(query, datetime.now())
        headers = {"Authorization": config.apiai_bearer}
        response = requests.get(url, headers=headers)

        return response.json()

    #TODO: Refactor this.
    def get_action(self, query):
        print(query)
        print(type(query))
        # query = quote(query)
        url = self.intent_url_template.format(query, datetime.now())
        headers = {"Authorization": config.apiai_bearer}
        response = requests.get(url, headers=headers)
        try:
            js = response.json()
            action = js['result']['action']
        except:
            print('No valid action came back from the intents api')
            action = ''
        return action

    def get_media(self, query):
        print(query)
        print(type(query))
        # query = quote(query)
        url = self.intent_url_template.format(query, datetime.now())
        headers = {"Authorization": config.apiai_bearer}
        response = requests.get(url, headers=headers)
        try:
            js = response.json()
            media = js['result']['parameters']['media']
        except:
            print('No valid media came back from the intents api')
            media = ''
        return media