//adapted from template: https://github.com/darwinex/DarwinexLabs/blob/master/tools/MQL4/ZeroMQ_MT4_EA_Template.mq4
#include <Zmq/Zmq.mqh>
#include <stdlib.mqh>
#include <stderror.mqh>
//#include <Bots/vegabot.mqh>
//+------------------------------------------------------------------+
//| Bot server in MQL                                        |
//| Binds REP socket to tcp://*:5555                                 |
//+------------------------------------------------------------------+
int start_bot = 0;
extern string BOT_NAME = "Vega Bot";
extern string ZEROMQ_PROTOCOL = "tcp";
extern string HOSTNAME = "127.0.0.1";
extern int REP_PORT = 5557;
extern int PUSH_PORT = 5558;
extern int MILLISECOND_TIMER = 1;

 Context context(BOT_NAME);

   //Reply socket
   Socket repSocket(context,ZMQ_REP);

   Socket pushSocket(context, ZMQ_PUSH);
   uchar data[];
    ZmqMsg request;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Print("Vega bot starting");
   EventSetMillisecondTimer(MILLISECOND_TIMER);     // Set Millisecond Timer to get client socket input

   Print("[REP] Binding MT4 Server to Socket on Port " + REP_PORT + "..");
   Print("[PUSH] Binding MT4 Server to Socket on Port " + PUSH_PORT + "..");

   repSocket.bind(StringFormat("%s://%s:%d", ZEROMQ_PROTOCOL, HOSTNAME, REP_PORT));
   pushSocket.bind(StringFormat("%s://%s:%d", ZEROMQ_PROTOCOL, HOSTNAME, PUSH_PORT));

   /*
       Maximum amount of time in milliseconds that the thread will try to send messages
       after its socket has been closed (the default value of -1 means to linger forever):
   */

   repSocket.setLinger(1000);  // 1000 milliseconds

   /*
      If we initiate socket.send() without having a corresponding socket draining the queue,
      we'll eat up memory as the socket just keeps enqueueing messages.

      So how many messages do we want ZeroMQ to buffer in RAM before blocking the socket?
   */

   repSocket.setSendHighWaterMark(5);     // 5 messages only.

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
   Print("[REP] Unbinding MT4 Server from Socket on Port " + REP_PORT + "..");
   repSocket.unbind(StringFormat("%s://%s:%d", ZEROMQ_PROTOCOL, HOSTNAME, REP_PORT));

   Print("[PUSH] Unbinding MT4 Server from Socket on Port " + PUSH_PORT + "..");
   pushSocket.unbind(StringFormat("%s://%s:%d", ZEROMQ_PROTOCOL, HOSTNAME, PUSH_PORT));

}

void ProcessRequest()
{
   // Get client's response, but don't wait.
   repSocket.recv(request,true);

   ZmqMsg reply = MessageHandler(request);

   repSocket.send(reply);
}
//+------------------------------------------------------------------+

ZmqMsg MessageHandler(ZmqMsg &request) {

   // Output object
   ZmqMsg reply;

   // Message components for later.
   string components[];

   if(request.size() > 0) {
      Print("Message received");
      // Get data from request
      ArrayResize(data, request.size());
      request.getData(data);
      string dataStr = CharArrayToString(data);

      // Process data
      ParseZmqMessage(dataStr, components);

      // Interpret data
      InterpretZmqMessage(&pushSocket, components);

      // Construct response
      ZmqMsg ret(StringFormat("[SERVER] Processing: %s", dataStr));
      reply = ret;

   }
   else {
      // NO DATA RECEIVED
      //Print("No data");
   }

   return(reply);
}

void OnStart()
  {
   uchar data[];
   int stop = 0;
   while(!IsStopped())
     {
     ProcessRequest();
     }
     OnDeinit(1);
     return;
  }
//+------------------------------------------------------------------+

// Interpret Zmq Message and perform actions
void InterpretZmqMessage(Socket &pSocket, string& compArray[]) {

   Print("ZMQ: Interpreting Message..");

   // Message Structures:

   // 1) Trading
   // TRADE|ACTION|TYPE|SYMBOL|PRICE|SL|TP|COMMENT|TICKET
   // e.g. TRADE|OPEN|1|EURUSD|0|50|50|R-to-MetaTrader4|12345678

   // The 12345678 at the end is the ticket ID, for MODIFY and CLOSE.

   // 2) Data Requests

   // 2.1) RATES|SYMBOL   -> Returns Current Bid/Ask

   // 2.2) DATA|SYMBOL|TIMEFRAME|START_DATETIME|END_DATETIME

   // NOTE: datetime has format: D'2015.01.01 00:00'

   /*
      compArray[0] = TRADE or RATES
      If RATES -> compArray[1] = Symbol

      If TRADE ->
         compArray[0] = TRADE
         compArray[1] = ACTION (e.g. OPEN, MODIFY, CLOSE)
         compArray[2] = TYPE (e.g. OP_BUY, OP_SELL, etc - only used when ACTION=OPEN)

         // ORDER TYPES:
         // https://docs.mql4.com/constants/tradingconstants/orderproperties

         // OP_BUY = 0
         // OP_SELL = 1
         // OP_BUYLIMIT = 2
         // OP_SELLLIMIT = 3
         // OP_BUYSTOP = 4
         // OP_SELLSTOP = 5

         compArray[3] = Symbol (e.g. EURUSD, etc.)
         compArray[4] = Open/Close Price (ignored if ACTION = MODIFY)
         compArray[5] = SL
         compArray[6] = TP
         compArray[7] = Trade Comment
         compArray[8] = Ticket Number
         compArray[9] = Volume
   */

   int switch_action = 0;

   if(compArray[0] == "TRADE" && compArray[1] == "OPEN")
      switch_action = 1;
   if(compArray[0] == "RATES")
      switch_action = 2;
   if(compArray[0] == "TRADE" && compArray[1] == "CLOSE")
      switch_action = 3;
   if(compArray[0] == "DATA")
      switch_action = 4;

   string ret = "";
   int ticket = -1;
   bool ans = FALSE;
   double price_array[];
   ArraySetAsSeries(price_array, true);

   int price_count = 0;
   int cmd = compArray[2];
   string symbol = compArray[3];
   string ticketNumber = compArray[8];
   double volume = compArray[9];
   double price = compArray[4];
   double slippage = 0.0;
   double stopLoss = compArray[5];
   double takeProfit = compArray[6];
   string comment = compArray[7];


   switch(switch_action)
   {
      case 1:
         Print("OPEN TRADE Instruction Received");
         InformPullClient(pSocket, "OPEN TRADE Instruction Received");
         //Print(symbol);
         //Print(volume);
         OrderSend(symbol, cmd, volume, price, slippage, stopLoss, takeProfit, comment);
         break;
      case 2:
         ret = "N/A";
         if(ArraySize(compArray) > 1)
            ret = GetBidAsk(compArray[1]);

         InformPullClient(pSocket, ret);
         break;
      case 3:
         InformPullClient(pSocket, "CLOSE TRADE Instruction Received");

         // IMPLEMENT CLOSE TRADE LOGIC HERE

         ret = StringFormat("Trade Closed (Ticket: %d)", ticket);
         InformPullClient(pSocket, ret);

         break;

      case 4:
         InformPullClient(pSocket, "HISTORICAL DATA Instruction Received");

         // Format: DATA|SYMBOL|TIMEFRAME|START_DATETIME|END_DATETIME
         price_count = CopyClose(compArray[1], StrToInteger(compArray[2]),
                        StrToTime(compArray[3]), StrToTime(compArray[4]),
                        price_array);

         if (price_count > 0) {

            ret = "";

            // Construct string of price|price|price|.. etc and send to PULL client.
            for(int i = 0; i < price_count; i++ ) {

               if(i == 0)
                  ret = compArray[1] + "|" + DoubleToStr(price_array[i], 5);
               else if(i > 0) {
                  ret = ret + "|" + DoubleToStr(price_array[i], 5);
               }
            }

            Print("Sending: " + ret);

            // Send data to PULL client.
            InformPullClient(pSocket, StringFormat("%s", ret));
            // ret = "";
         }

         break;

      default:
         break;
   }
}

// Parse Zmq Message
void ParseZmqMessage(string& message, string& retArray[]) {

   Print("Parsing: " + message);

   string sep = "|";
   ushort u_sep = StringGetCharacter(sep,0);

   int splits = StringSplit(message, u_sep, retArray);

   for(int i = 0; i < splits; i++) {
      Print(i + ") " + retArray[i]);
   }
}

//+------------------------------------------------------------------+
// Generate string for Bid/Ask by symbol
string GetBidAsk(string symbol) {

   double bid = MarketInfo(symbol, MODE_BID);
   double ask = MarketInfo(symbol, MODE_ASK);

   return(StringFormat("%f|%f", bid, ask));
}

// Inform Client
void InformPullClient(Socket& pushSocket, string message) {

   ZmqMsg pushReply(StringFormat("%s", message));
   // pushSocket.send(pushReply,true,false);

   pushSocket.send(pushReply,true); // NON-BLOCKING
   // pushSocket.send(pushReply,false); // BLOCKING

}
