#Vega project POC

This proof of concept uses several APIs to allow the user to gather crypto currency market data
and to interact with a AI bot. To run this demo locally you will need to 
1. Download and install python at url: https://www.python.org/downloads/
2. Create a Telegram bot and download ngrok to run locally  
3. Sign up with Google's dialogflow site 
4. Set the telegram bot and dialogflow tokens in the config.py
5. Run the reports.py or trading.py with python.exe 
    
#Telegram Bot
   1. Download telegram for your respective operating system at url: https://telegram.org/           
   2. Download ngrok at url: https://ngrok.com/download    
   3. Once telegram is installed you have to converse with the bot father
      to create your bot. Go to url: https://telegram.me/botfather .Once done the bot father will give you the bot's token. 
   4. If running the trades.py module, find the location of ngrok.exe
      and run ngrok http 127.0.0.1:5001
      a. Telegram requires the web hook url to use https so select the https version, 
         it will look like this url: https://a5a4732f.ngrok.io
      b. Find your bot token from the bot father and take the ngrok and then set the telegram web hook in a browser.
         https://api.telegram.org/bot801584284:AAEYehXk3Azn02EHqXjWqha8K3sci2QAQaF/setWebhook?url=https://a5a4732f.ngrok.io
         The values are fake for clarity so replace your respective values. Make sure to leave the bot prefix in front of the token.
         If successful, your browser will return the following json:
                     
   5. You should now be ready to start conversing with your bot and telegram should route your traffic to your local machine.       

#Dialog Flow Setup
   1. Google's dialog flow allows us to pass what the user typed into the telegram bot 
      and to parse out key values. Google has steps you need to follow to start creating intents at
      https://developers.google.com/actions/dialogflow/first-app
   2. Once you sign up and navigate to the console window at https://console.dialogflow.com/api-client
      you will see a link to create a new agent. Name it whatever you want and
      then click on the settings -> Export and Import
   3. Find the intents backup located in this project under Bots -> IntentsBackup -> Currency-Converter-1.zip
   4. Click on Restore from Zip and upload the zip file.
   5. You should now see the intents
   6. In the top right corner ask the agent a question and click on Copy Url
      which will give you a long curl command, navigate to the end of the line
      and you will see the Bearer token
      ```
      ...  -H 'Authorization:Bearer 88664e99886a55abd954c332bc3021z11'
      
   the value is fake for demo purposes of course. Take this value
   and insert it in the config.py value named apiai_bearer, see example:
    
       apiai_bearer="Bearer 8664e99886a55abd954c332bc3021z11"
   7. Once you start asking the telegram bot questions our code will send the message
      to google's dialog and it figures out the intent, action and parses out values such as 
      the coin you asked it.        
   8. Disclaimer, this is just a demo and you should not share these values with anyone. 

#Stand Alone command line
#make sure to run 
      pip install -r C:\VegaIS\requirements.txt
Check the config.py in C:\VegaIS\Config and set the path of the sqlite data base
    reports_db = 'C:/VegaIS/app/taxreports/'
        
   Assuming you have installed python version 3.3.2 or higher you can run the modules
    by themselves at the command prompt. 
    
    C:\Users\usr1\AppData\Local\Programs\Python\Python36\python.exe C:/VegaIS/app/vegatrading/trading.py
    Running trading:
        python.exe C:/VegaIS/app/vegatrading/trading.py
        console results when running:
    
        C:\WINDOWS\system32>C:\Users\usr1\AppData\Local\Programs\Python\Python36\python.exe C:/VegaIS/app/vegatrading/trading.py
        Using TensorFlow backend.
        INFO:engineio:Server initialized for eventlet.
    
    Running reports:
    C:\Users\usr1\AppData\Local\Programs\Python\Python36\python.exe C:/VegaIS/app/taxreports/reports.py
    
    python.exe C:/VegaIS/app/taxreports/reports.py

   
Adjust the paths depending on how you downloaded the project.
#You can configure the upload path and base in the config as well:
    ```
    taxreport_base = 'C:/VegaIS/app/taxreports/'
    reports_db = 'C:/VegaIS/app/taxreports/'
    uploads = 'C:/VegaIS/app/taxreports/uploads/'

#if both modules are running you should be able to navigate to a browser:
    url: http://127.0.0.1:5000/reports
    url: http://127.0.0.1:5001/trading 
       
#Resolving Module and package settings in windows
You may get an error related to importing Bot.currencybot or MLBOT when running reports.py or trading.py with python by itself.
To resolve this issue reference url: https://docs.python.org/3/using/windows.html 
Open a command prompt and set the root path of the folder that you 
downloaded the project to. 
```
example:
set PYTHONPATH=%PYTHONPATH%;C:\VegaIS
