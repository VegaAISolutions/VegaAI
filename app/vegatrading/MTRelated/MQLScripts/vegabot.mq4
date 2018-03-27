
#property copyright "Data mined, and highly optimized via genetic algorithm machine learning and roulette system risk mangement, and rigorous manual out of sample teting. This script creates a stable balance for eurusdm5"

#include <stdlib.mqh>
#include <stderror.mqh>

// For double comparisons
#define EPSILON 0.0000001

#define COMPONENT_NAME        "VegaBot"

//addOpenVegaBotVersion
#define COMPONENT_VERSION     "4Beta"

#define OP_DEPOSITORWITHDRAWAL         6

#define NO_ERROR                        0

#define ERROR_TIME_BUFFER              60

#define SECONDS_IN_DAY                 86400

#define OPERATIONAL_MODE_TRADING    0
#define OPERATIONAL_MODE_MONITORING 1
#define OPERATIONAL_MODE_TESTING    2

#define ALERT_STATUS_NEW                      0
#define ALERT_STATUS_DISPLAYED                     1

//--------------------------------------------------------- Equity track begin -------------------------
#define EQUITY_TRACK_NONE  0
#define EQUITY_TRACK_FILE  1
//--------------------------------------------------------- Equity track end -------------------------


#define STATUS_NONE                    -1
#define STATUS_INVALID_BARS_COUNT       0
#define STATUS_INVALID_TIMEFRAME        1
#define STATUS_DIVIDE_BY_ZERO           2
#define STATUS_LAST_ERROR               3
#define STATUS_ATR_INIT_PROBLEM         4
#define STATUS_TRADE_CONTEXT_BUSY       5
#define STATUS_TRADING_NOT_ALLOWED      6
#define STATUS_DUPLICATE_ID             7
#define STATUS_RUNNING_ON_DEFAULTS      8
#define STATUS_BELOW_MIN_LOT_SIZE       9
#define STATUS_LIBS_NOT_ALLOWED         10
#define STATUS_NOT_ENOUGH_DATA			 11
#define STATUS_SPREAD_TOO_HIGH          12

#define QUERY_NONE             0
#define QUERY_LONGS_COUNT      1
#define QUERY_SHORTS_COUNT     2
#define QUERY_BUY_STOP_COUNT   3
#define QUERY_SELL_STOP_COUNT  4
#define QUERY_BUY_LIMIT_COUNT  5
#define QUERY_SELL_LIMIT_COUNT 6
#define QUERY_ALL              7

#define PATTERN_NONE          -1
#define LONG_ENTRY_PATTERN     0
#define SHORT_ENTRY_PATTERN    1
#define LONG_EXIT_PATTERN      2
#define SHORT_EXIT_PATTERN     3

#define SIGNAL_NONE                 -1
#define SIGNAL_ENTER_BUY             0
#define SIGNAL_ENTER_SELL            1
#define SIGNAL_CLOSE_BUY             2
#define SIGNAL_CLOSE_SELL            3
#define SIGNAL_UPDATE_BUY            4
#define SIGNAL_UPDATE_SELL           5

#define BUY_COLOR          DodgerBlue
#define BUY_CLOSE_COLOR    Blue
#define SELL_COLOR         DeepPink
#define SELL_UPDATE_COLOR  Orange
#define BUY_UPDATE_COLOR   Green
#define SELL_CLOSE_COLOR   Red
#define INFORMATION_COLOR  Red
#define ERROR_COLOR        Red
#define TRAIL_COLOR        Yellow

// Status management
#define SEVERITY_INFO  0
#define SEVERITY_ERROR 1

extern string VegaBot = "EURUSD Price action system with optional RSI, MACD, and Ichimoku Support";
extern int    OPERATIONAL_MODE    = OPERATIONAL_MODE_TRADING;
extern string TRADE_COMMENT       = "VegaBot V4Beta";
//insertInstanceID
extern int    INSTANCE_ID         = 91337 ;
double SLIPPAGE                   = 5   ;
double MAX_SPREAD_PIPS            = 0.0;
bool   DISABLE_COMPOUNDING        = true;
extern string MM_SETUP            = "Money Management Settings";
extern int    ATR_PERIOD          = 5;
extern double RISK                = 0.01;
extern double TAKE_PROFIT         = 0.05;
extern double STOP_LOSS           = 0;
extern string TRADE_SETUP         = "Trade Filter Settings";
extern int USE_RSI                = 1;
extern int USE_MACD               = 1;
extern int USE_ICHIMOKU           = 1;
extern int USE_KUMOMOD            = 1;
extern string Ichimoku_Setup      = "Ichimoku Settings";
extern int Tenkan                 = 159; // 9 Tenkan line period. The fast "moving average".
extern int Kijun                  = 86; // 26 Kijun line period. The slow "moving average".
extern int Senkou                 = 152; // 52 Senkou period. Used for Kumo (Cloud) spans.
extern int kumoThreshold          = 7; //minimum size of kumo to open an order

//Ichimoku variables
bool ChinkouPriceBull = false;
bool ChinkouPriceBear = false;
bool KumoBullConfirmation = false;
bool KumoBearConfirmation = false;
bool KumoChinkouBullConfirmation = false;
bool KumoChinkouBearConfirmation = false;



//VegaBot Q-Learned Strategy
//extern int x1=9,x2=29,x3=94,x4=125;
//extern int y1=61,y2=100,y3=117,y4=31;
//VegaBot System
//double Qu(int q1,int q2,int q3,int q4) {    return ((q1-100)*MathAbs(High[1]-Low[2])+
//(q2-100)*MathAbs(High[3]-Low[2])+(q3-100)*MathAbs(High[2]-Low[1])+(q4-100)*MathAbs(High[2]-Low[3]));}


// EA global variables
string g_symbol;
double g_pipValue;
double g_ATR;
int    g_waitCounter;
double g_instancePL_UI ;
double g_generatedINSTANCE_ID ;

extern string  MACD_SETUP = "MACD Settings";
extern double MACDOpenLevel = 0;
extern double MACDCloseLevel = 5;
extern int FastEMA=12;   // Fast EMA Period
extern int SlowEMA=26;   // Slow EMA Period
extern int SignalSMA=9;  // Signal SMA Period
extern int    MATrendPeriod = 7;

extern string  RSI_Setup = "RSI entry and exit settings";
extern int 	  RSI_PERIOD = 7;
extern int 	  RSI_LONG = 64;
extern int 	  RSI_SHORT = 36;
extern int 	  RSI_LONGEXIT = 36;
extern int 	  RSI_SHORTEXIT = 64;
double MacdCurrent,MacdPrevious;
double SignalCurrent,SignalPrevious;
double MaCurrent,MaPrevious;
double RSICurrent,RSIPrevious;


//Initial balance and balance reset variables
string g_balanceTimeLabel ;
string g_initialBalanceLabel ;
string g_initBalBackupFile ;
int g_balanceBackupTime = 0 ;
double g_initialBalance ;
int g_instanceStartTime ;
int g_lastTradingTime;

int g_alertStatus ;
string g_lastError ;
int g_lastErrorPrintTime ;
int g_indiLibraryStatus;
int g_periodSeconds;
int g_barsAvailable;

double g_maxTradeSize,
       g_minTradeSize,
       g_spreadPIPs,
       g_adjustedSlippage,
       g_instanceBalance,
		 g_tradeSize;

double g_stopLossPIPs,
	   g_takeProfitPIPs;

//defineMaxShiftNeeded
int g_maxShift = 96 ;

int g_minimalStopPIPs;
int g_contractSize,
	 g_brokerDigits,
	 g_period,
	 g_tradingSignal;

//--------------------------------------------------------- Equity track begin -------------------------
int g_fileEquityLog;
string g_currentDay="",
       g_timeOfEquityMin;
double g_dailyEquityMin,
       g_prevDailyEquityMin;
//--------------------------------------------------------- Equity track end -------------------------


//-------------------   UI staff   ------------------

// Graphical entities names
string g_objGeneralInfo      = "labelGeneral",
       g_objTradeSize        = "labelTradeSize",
		 g_objStopLoss         = "labelStopLoss",
		 g_objTakeProfit       = "labelTakeProfit",
		 g_objATR              = "labelATR",
		 g_objPL               = "labelPL",
		 g_objStatusPane       = "labelStatusPane",
		 g_objBalance          = "labelBalance";
string g_fontName = "Times New Roman";

string g_orderTimeGlobalString;
string g_orderGlobalString ;

int   FontSize = 10;
// The value at index 'i' returns the string
// to be displayed for the error/warning, having ID equal to i.
string g_statusMessages[];

// The value at index 'i' returns the string
// to be displayed for pattern, having ID equal to i.
string g_detectedPatternNames[];

// UI state management
int g_severityStatus,
	 g_lastStatusID          = STATUS_NONE,
	 g_lastDetectedPatternID = PATTERN_NONE;

// The offset, in pixels, of the first information line from the top-left corner.
int g_baseXOffset = 15,
	 g_baseYOffset = 20;

// Controls how far or near are text lines on Y axis
double g_textDensingFactor = 1.5;

// The EA initialization funtion
int init()
{
   displayWelcomeMessage() ;

   g_initialBalance = AccountBalance() ;

	g_symbol = Symbol();
	g_period = Period();
	g_periodSeconds = PeriodSeconds(g_period);
	g_pipValue = Point;
	g_orderTimeGlobalString = StringConcatenate(INSTANCE_ID, "_LAST_OP_TIME");
	g_orderGlobalString = StringConcatenate(INSTANCE_ID,  "_LAST_OP");
	generateINSTANCE_ID() ;

	// Retrieve the minimum stop loss in PIPs
	g_minimalStopPIPs = MarketInfo( g_symbol, MODE_STOPLEVEL );
	g_maxTradeSize    = MarketInfo( g_symbol, MODE_MAXLOT    );
	g_minTradeSize    = MarketInfo( g_symbol, MODE_MINLOT    );

	g_brokerDigits  = Digits;
	g_tradingSignal = SIGNAL_NONE;

   if(OPERATIONAL_MODE != OPERATIONAL_MODE_TESTING )
	initUI();

	// Success
	return (0);
}

//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
{
   if(OPERATIONAL_MODE != OPERATIONAL_MODE_TESTING )
	deinitUI();

	return (0);
}

//+------------------------------------------------------------------+
//| Tick handling function                                           |
//+------------------------------------------------------------------+
int start()
{

g_lastStatusID = STATUS_NONE ;
g_severityStatus = SEVERITY_INFO;
g_barsAvailable = iBars(g_symbol, g_period);

checkLibraryUsageAllowed();

	if(  STATUS_LIBS_NOT_ALLOWED  == g_lastStatusID )
	{
	     g_severityStatus = SEVERITY_ERROR;
		if( OPERATIONAL_MODE_TESTING != OPERATIONAL_MODE )
			updateStatusUI( true );

		return (0);
	}

	// check if we are running on defaults
	isINSTANCE_IDDefault(INSTANCE_ID);

	if(  STATUS_RUNNING_ON_DEFAULTS  == g_lastStatusID )
	{
	     g_severityStatus = SEVERITY_ERROR;
		if( OPERATIONAL_MODE_TESTING != OPERATIONAL_MODE )
			updateStatusUI( true );

		return (0);
	}

	verifyINSTANCE_IDUniquiness();

	if(  STATUS_DUPLICATE_ID == g_lastStatusID )
	{
	     g_severityStatus = SEVERITY_ERROR;
		if( OPERATIONAL_MODE_TESTING != OPERATIONAL_MODE )
			updateStatusUI( true );

		return (0);
	}

	if(g_barsAvailable < MathMax(g_maxShift, ATR_PERIOD*(SECONDS_IN_DAY/g_periodSeconds)+10)){

		g_lastStatusID = STATUS_NOT_ENOUGH_DATA;
	    g_severityStatus = SEVERITY_ERROR;
		if( OPERATIONAL_MODE_TESTING != OPERATIONAL_MODE )
			updateStatusUI( true );

	    return (0);
	}

	calculateATR();

	if( STATUS_DIVIDE_BY_ZERO == g_lastStatusID )
	{
	   g_severityStatus = SEVERITY_ERROR;
	   if(OPERATIONAL_MODE != OPERATIONAL_MODE_TESTING )
		updateStatusUI( true );
		return (0);
	}
	if( STATUS_ATR_INIT_PROBLEM == g_lastStatusID )
	{
	   g_severityStatus = SEVERITY_ERROR;
	   if(OPERATIONAL_MODE != OPERATIONAL_MODE_TESTING )
		updateStatusUI( true );
		return (0);
	}

	if(OPERATIONAL_MODE != OPERATIONAL_MODE_TESTING )
	{
	calculateInstanceBalance();
	}

	calculateContractSize();
	adjustSlippage();
	calculateSpreadPIPS() ;
	calculateTradeSize();
	calculateStopLossPIPs();
	calculateTakeProfitPIPs();

	g_lastTradingTime = GlobalVariableGet(g_orderTimeGlobalString);

	g_tradingSignal = checkTradingSignal();

	// Handle already opened trades
	int openedTradesCount = 0;

	for( int cnt = 0; cnt < OrdersTotal(); cnt++ )
	{
		if( ! OrderSelect( cnt, SELECT_BY_POS, MODE_TRADES ) )
     	{
     		g_severityStatus = STATUS_LAST_ERROR;
     		g_lastStatusID = GetLastError();
     		continue;
		}

		// Filter orders, that were not opened by this instance
		if( ! ( ( OrderSymbol() == g_symbol ) && ( OrderMagicNumber() == INSTANCE_ID ) ) )
		{
			continue;
		}

		handleTrade();

		openedTradesCount++;
	}

   if(OPERATIONAL_MODE != OPERATIONAL_MODE_TESTING )
	updateUI();

	if( OPERATIONAL_MODE_MONITORING == OPERATIONAL_MODE )
	{
		// Just handle existing trade
		return (0);
	}

	g_tradingSignal = checkTradingSignal();

	if (g_lastTradingTime != iTime(Symbol(),0,0)) {

	   switch( g_tradingSignal ) {
	      case SIGNAL_ENTER_BUY:
		      openBuyOrder();
	      break;
	      case SIGNAL_ENTER_SELL:
		      openSellOrder();
	      break;
	      case SIGNAL_NONE:
	         GlobalVariableSet(g_orderTimeGlobalString, iTime(Symbol(),0,0));
	      break;
									  } // switch( g_tradingSignal )
							}

   if( ( STATUS_TRADE_CONTEXT_BUSY  == g_lastStatusID ) ||
		 ( STATUS_TRADING_NOT_ALLOWED == g_lastStatusID ) ||
		 ( STATUS_BELOW_MIN_LOT_SIZE == g_lastStatusID )
	  )
	{
		g_severityStatus = SEVERITY_ERROR;
		if( OPERATIONAL_MODE != OPERATIONAL_MODE_TESTING )
			updateStatusUI( true );
	}

	return (0);
}

void displayWelcomeMessage()
{
	string welcomeMessage = StringConcatenate("You are running ", COMPONENT_NAME, " v.", COMPONENT_VERSION) ;
	Alert( welcomeMessage );
}

void checkLibraryUsageAllowed()
{

if (IsLibrariesAllowed() == false) {
      //Library calls must be allowed
      g_lastStatusID = STATUS_LIBS_NOT_ALLOWED ;
   }

}

// This function verifies that we are not running on default settings.
// If we are then an error is generated which stops trading.
// This is an important feature since several reasons can cause a platform
// to "reset" back to the EA defaults, something which may be very detrimental
// depending on the systems.

void isINSTANCE_IDDefault(int ID)
{
   if (ID == -1)
   {
   g_lastStatusID = STATUS_RUNNING_ON_DEFAULTS ;
		return;
   }
}

// Declares the INSTANCE_ID global variable,
// marking it with a unique random number
void generateINSTANCE_ID()
{
	int count;

	// The following if statement creates or increases
	// the "count" variable which is then used as a part of the "seed"
	// for the random number generator, this count ensures that
	// random numbers remain unique and duplicates identified even if the instances are started
	// at exactly the same time on the same instrument.
	if( GlobalVariableCheck( "rdn_gen_count" ) )
	{
		count = GlobalVariableGet( "rdn_gen_count" );
		g_waitCounter = count ;
		if( count < 100 )
			GlobalVariableSet( "rdn_gen_count", count + 1 );

		if( count >= 100 )
			GlobalVariableSet( "rdn_gen_count", 1 );
	}
	else
	{
		GlobalVariableSet( "rdn_gen_count", 1 );
		count = 1 ;
	}

	// Random number generator seed, current time, Ask and counter are used
	MathSrand( TimeLocal() * Ask * count );

	// String for global variable
	string INSTANCE_IDTag = DoubleToStr( INSTANCE_ID, 0 );

	// generate the random number and place it within the tag
	GlobalVariableSet( INSTANCE_IDTag, MathRand() );

	// Assigns the random number to this instance specific global variable
	// this value will be used from now on to check if there are duplicate
	// Instance IDs
	g_generatedINSTANCE_ID = GlobalVariableGet( INSTANCE_IDTag );
}

// Verifies that the tag, generated during initialization, has changed.
// Generates a "duplicate ID" error if this is the case.
void verifyINSTANCE_IDUniquiness()
{
	// Retrieve instance ID as string to search for global variable
	string INSTANCE_IDTag = DoubleToStr( INSTANCE_ID, 0 );

	// Assign the value of the global variable
	double retrievedINSTANCE_ID = GlobalVariableGet( INSTANCE_IDTag );

	// Check whether the tag has changed from what it had originally been assigned to
	if( MathAbs( g_generatedINSTANCE_ID - retrievedINSTANCE_ID ) >= EPSILON )
	{
		// Gnerates an error if a duplicate instance is found
		g_lastStatusID = STATUS_DUPLICATE_ID;
		return;
	}

	// Reassigning global variable, this does not change the variable's value,
	// however it needs to be done since unmodified variables are deleted
	// after 4 weeks. This "regeneration" avoids deletion.
	GlobalVariableSet( INSTANCE_IDTag, retrievedINSTANCE_ID );
}


bool SetBuyOrderSLAndTP( int tradeTicket, double tradeOpenPrice )
{
	double stopLossPrice   = calculateStopLossPrice( OP_BUY, tradeOpenPrice ),
			 takeProfitPrice = calculateTakeProfitPrice( OP_BUY, tradeOpenPrice );

	if (STOP_LOSS == 0 && TAKE_PROFIT == 0)
	return(true);

	bool res = OrderModify(
	 					tradeTicket,
	 					tradeOpenPrice,
	 					stopLossPrice,
	 					takeProfitPrice,
	 					0,
	 					BUY_COLOR
	 							 );
	if( res )
		return(true);

	logOrderModifyInfo(
						"SetBuyOrderSLAndTP-OrderModify: ",
						tradeTicket,
						tradeOpenPrice,
						stopLossPrice,
						takeProfitPrice,
						GetLastError()
							);

	return(false);
}

bool SetSellOrderSLAndTP( int tradeTicket, double tradeOpenPrice )
{
	double stopLossPrice   = calculateStopLossPrice( OP_SELL, tradeOpenPrice ),
			 takeProfitPrice = calculateTakeProfitPrice( OP_SELL, tradeOpenPrice );

	if (STOP_LOSS == 0 && TAKE_PROFIT == 0)
	return(true);

	bool res = OrderModify(
	 					tradeTicket,
	 					tradeOpenPrice,
	 					stopLossPrice,
	 					takeProfitPrice,
	 					0,
	 					SELL_COLOR
	 							 );
	if( res )
		return(true);

	logOrderModifyInfo(
						"SetSellOrderSLAndTP-OrderModify: ",
						tradeTicket,
						tradeOpenPrice,
						stopLossPrice,
						takeProfitPrice,
						GetLastError()
						   );

	return(false);
}

void openBuyOrder()
{

   if( (g_spreadPIPs > MAX_SPREAD_PIPS) && (MAX_SPREAD_PIPS > 0.0 ))
	{
		g_lastStatusID = STATUS_SPREAD_TOO_HIGH;

		if ((TimeCurrent()- g_lastErrorPrintTime) > ERROR_TIME_BUFFER)
		{
		Print( "openBuyOrder: Spread is above threshold." );
		g_lastErrorPrintTime = TimeCurrent();
		}

		return;
	}

	if( ! IsTradeAllowed() )
	{
		g_lastStatusID = STATUS_TRADING_NOT_ALLOWED;

		if ((TimeCurrent()- g_lastErrorPrintTime) > ERROR_TIME_BUFFER)
		{
		Print( "openBuyOrder: Trading is not allowed." );
		g_lastErrorPrintTime = TimeCurrent();
		}

		return;
	}

	if( ! MarketInfo(Symbol(), MODE_TRADEALLOWED) && ! IsTesting() )
	{
		g_lastStatusID = STATUS_TRADING_NOT_ALLOWED;

		if ((TimeCurrent()- g_lastErrorPrintTime) > ERROR_TIME_BUFFER)
		{
		Print( "openBuyOrder: Trading is not allowed." );
		g_lastErrorPrintTime = TimeCurrent();
		}

		return;
	}

	if( IsTradeContextBusy() )
	{
	   g_lastStatusID = STATUS_TRADE_CONTEXT_BUSY;

	   if ((TimeCurrent()- g_lastErrorPrintTime) > ERROR_TIME_BUFFER)
		{
		Print( "openBuyOrder: trade context is busy." );
		g_lastErrorPrintTime = TimeCurrent();
		}
		return;
	}

	checkMinTradeSize() ;

	if( STATUS_BELOW_MIN_LOT_SIZE == g_lastStatusID )
	{
	   if ((TimeCurrent()- g_lastErrorPrintTime) > ERROR_TIME_BUFFER)
		{
		Print( "openBuyOrder: lot size below minimum broker size on entry signal." );
		g_lastErrorPrintTime = TimeCurrent();
		}
		return;
	}

	double tradeOpenPrice = NormalizeDouble( Ask, g_brokerDigits );

	// Support ECN brokerage
	int tradeTicket = OrderSend(
									g_symbol,
									OP_BUY,
									g_tradeSize,
									tradeOpenPrice,
									g_adjustedSlippage,
									0,
									0,
									TRADE_COMMENT,
									INSTANCE_ID,
									0,
									BUY_COLOR
							  		   );
	if( -1 == tradeTicket )
	{
		logOrderSendInfo(
						"openBuyOrder-OrderSend: ",
						g_tradeSize,
						tradeOpenPrice,
						g_adjustedSlippage,
						0.0,
						0.0,
						GetLastError()
							 );
		return;
	}

	SetBuyOrderSLAndTP( tradeTicket, tradeOpenPrice );


	GlobalVariableSet(StringConcatenate(INSTANCE_ID,"_TRADE_MOD"), iTime(g_symbol, g_period, 0));
	GlobalVariableSet(g_orderGlobalString, tradeOpenPrice);
	GlobalVariableSet(g_orderTimeGlobalString, iTime(Symbol(),0,0));

}

void openSellOrder()
{

   if( (g_spreadPIPs > MAX_SPREAD_PIPS) && (MAX_SPREAD_PIPS > 0.0))
	{
		g_lastStatusID = STATUS_SPREAD_TOO_HIGH;

		if ((TimeCurrent()- g_lastErrorPrintTime) > ERROR_TIME_BUFFER)
		{
		Print( "openSellOrder: Spread is above threshold." );
		g_lastErrorPrintTime = TimeCurrent();
		}

		return;
	}

	if( ! IsTradeAllowed() )
	{
		g_lastStatusID = STATUS_TRADING_NOT_ALLOWED;

		if ((TimeCurrent()- g_lastErrorPrintTime) > ERROR_TIME_BUFFER)
		{
		Print( "openSellOrder: Trading is not allowed." );
		g_lastErrorPrintTime = TimeCurrent();
		}

		return;
	}

	if( ! MarketInfo(Symbol(), MODE_TRADEALLOWED) && ! IsTesting() )
	{
		g_lastStatusID = STATUS_TRADING_NOT_ALLOWED;

		if ((TimeCurrent()- g_lastErrorPrintTime) > ERROR_TIME_BUFFER)
		{
		Print( "openSellOrder: Trading is not allowed." );
		g_lastErrorPrintTime = TimeCurrent();
		}

		return;
	}

	if( IsTradeContextBusy() )
	{
	   g_lastStatusID = STATUS_TRADE_CONTEXT_BUSY;

	   if ((TimeCurrent()- g_lastErrorPrintTime) > ERROR_TIME_BUFFER)
		{
		Print( "openSellOrder: trade context is busy." );
		g_lastErrorPrintTime = TimeCurrent();
		}
		return;
	}


	checkMinTradeSize() ;

	if( STATUS_BELOW_MIN_LOT_SIZE == g_lastStatusID )
	{
	   if ((TimeCurrent()- g_lastErrorPrintTime) > ERROR_TIME_BUFFER)
		{
		Print( "openSellOrder: lot size below minimum broker size on entry signal." );
		g_lastErrorPrintTime = TimeCurrent();
		}
		return;
	}

	double tradeOpenPrice = NormalizeDouble( Bid, g_brokerDigits );


	// Support ECN brokerage
	int tradeTicket = OrderSend(
									g_symbol,
									OP_SELL,
									g_tradeSize,
									tradeOpenPrice,
									g_adjustedSlippage,
									0,
									0,
									TRADE_COMMENT,
									INSTANCE_ID,
									0,
									SELL_COLOR
							  		   );
	if( -1 == tradeTicket )
	{
		logOrderSendInfo(
						"openSellOrder-OrderSend: ",
						g_tradeSize,
						tradeOpenPrice,
						g_adjustedSlippage,
						0.0,
						0.0,
						GetLastError()
							 );
		return;
	}

	SetSellOrderSLAndTP( tradeTicket, tradeOpenPrice );

	GlobalVariableSet(StringConcatenate(INSTANCE_ID,"_TRADE_MOD"), iTime(g_symbol, g_period, 0));
	GlobalVariableSet(g_orderGlobalString, tradeOpenPrice);
	GlobalVariableSet(g_orderTimeGlobalString, iTime(Symbol(),0,0));

}

void handleTrade()
{
	switch( OrderType() ) {
	case OP_BUY:
		handleBuyTrade();
	break;
	case OP_SELL:
		handleSellTrade();
	break;
								 } // switch( OrderType() )
}

void handleBuyTrade()
{

int tradeTicket = OrderTicket() ;
double tradeOpenPrice = GlobalVariableGet(g_orderGlobalString);
double stopLossPrice = OrderStopLoss() ;
double takeProfitPrice = OrderTakeProfit() ;

//Remodify order if it wasn't adequately modified on entry

  if( (     OrderMagicNumber()   == INSTANCE_ID ) &&
		 ( MathAbs( stopLossPrice ) <  EPSILON    ) &&
		 ( STOP_LOSS != 0 )
	  )
	{
		SetBuyOrderSLAndTP( tradeTicket, tradeOpenPrice );
	}

  if( (     OrderMagicNumber()   == INSTANCE_ID ) &&
		 ( MathAbs( takeProfitPrice ) <  EPSILON    ) &&
		 ( TAKE_PROFIT != 0 )
	  )
	{
		SetBuyOrderSLAndTP( tradeTicket, tradeOpenPrice );
	}

//Close trade if signal to close long is triggered

	if( SIGNAL_CLOSE_BUY == g_tradingSignal )
	{
	  if(OrderMagicNumber() == INSTANCE_ID)
	  {

		OrderClose( tradeTicket, OrderLots(), NormalizeDouble( Bid, g_brokerDigits ), g_adjustedSlippage, BUY_CLOSE_COLOR );
		logOrderCloseInfo(
						"handleBuyTrade: ",
						tradeTicket,
						GetLastError()
							  );
		}
	}

	if( SIGNAL_UPDATE_BUY == g_tradingSignal && TimeCurrent()-GlobalVariableGet(StringConcatenate(INSTANCE_ID,"_TRADE_MOD")) > g_period*60-1)
	{
	  if(OrderMagicNumber() == INSTANCE_ID)
	  {

	  	     if (SetBuyOrderSLAndTP( tradeTicket, Ask ))
		     {
            GlobalVariableSet(StringConcatenate(INSTANCE_ID,"_TRADE_MOD"), iTime(g_symbol, g_period, 0));
            GlobalVariableSet(g_orderTimeGlobalString, iTime(Symbol(),0,0));
            GlobalVariableSet(g_orderGlobalString, Ask);
           }
		}
	}

}

void handleSellTrade()
{

int tradeTicket = OrderTicket();
double tradeOpenPrice = GlobalVariableGet(g_orderGlobalString);
double stopLossPrice = OrderStopLoss() ;
double takeProfitPrice = OrderTakeProfit();

// Update the order if it wasn't adequately modified on entry

	if( (     OrderMagicNumber()   == INSTANCE_ID ) &&
		 ( MathAbs( stopLossPrice ) <  EPSILON    ) &&
		 ( STOP_LOSS != 0 )
	  )
	{
		SetSellOrderSLAndTP( tradeTicket, tradeOpenPrice );
	}

  if( (     OrderMagicNumber()   == INSTANCE_ID ) &&
		 ( MathAbs( takeProfitPrice ) <  EPSILON    ) &&
		 ( TAKE_PROFIT != 0 )
	  )
	{
		SetSellOrderSLAndTP( tradeTicket, tradeOpenPrice );
	}


	// Close the trade if close long signal has been triggered

	if( SIGNAL_CLOSE_SELL == g_tradingSignal )
	{
	  if(OrderMagicNumber() == INSTANCE_ID)
	  {

		OrderClose( tradeTicket, OrderLots(), NormalizeDouble( Ask, g_brokerDigits) , g_adjustedSlippage, SELL_CLOSE_COLOR );
		logOrderCloseInfo(
						"handleSellTrade: ",
						tradeTicket,
						GetLastError()
							  );
	  }
	}

	if( SIGNAL_UPDATE_SELL == g_tradingSignal && TimeCurrent()-GlobalVariableGet(StringConcatenate(INSTANCE_ID,"_TRADE_MOD")) > g_period*60-1)
	{
	  if(OrderMagicNumber() == INSTANCE_ID)
	  {

		   if (SetSellOrderSLAndTP( tradeTicket, Bid))
		   {
            GlobalVariableSet(StringConcatenate(INSTANCE_ID,"_TRADE_MOD"), iTime(g_symbol, g_period, 0));
            GlobalVariableSet(g_orderTimeGlobalString, iTime(Symbol(),0,0));
            GlobalVariableSet(g_orderGlobalString, Bid);
         }
		}
	}

}

int checkTradingSignal()
{
	int pattern_status = detectPattern(),
		 signal = SIGNAL_NONE;

	switch( pattern_status ) {
	case PATTERN_NONE:
	break;
	case LONG_ENTRY_PATTERN:
	   if (queryOrdersCount(QUERY_ALL) == 0)
		signal = SIGNAL_ENTER_BUY;
	   if (queryOrdersCount(OP_BUY) > 0)
		signal = SIGNAL_UPDATE_BUY;
		if (queryOrdersCount(OP_SELL) > 0)
		signal = SIGNAL_CLOSE_SELL;
	break;
	case SHORT_ENTRY_PATTERN:
		if (queryOrdersCount(QUERY_ALL) == 0)
		signal = SIGNAL_ENTER_SELL;
	   if (queryOrdersCount(OP_SELL) > 0)
		signal = SIGNAL_UPDATE_SELL;
		if (queryOrdersCount(OP_BUY) > 0)
		signal = SIGNAL_CLOSE_BUY;
	break;
	case LONG_EXIT_PATTERN:
		signal = SIGNAL_CLOSE_BUY;
	break;
	case SHORT_EXIT_PATTERN:
		signal = SIGNAL_CLOSE_SELL;
	break;

							} // switch( pattern )
	return (signal);
}

int detectPattern()
{

//MACD, RSI, Ichimoku Indicator data
MacdCurrent=iMACD(NULL,0,FastEMA,SlowEMA,SignalSMA,PRICE_CLOSE,MODE_MAIN,0);
MacdPrevious=iMACD(NULL,0,FastEMA,SlowEMA,SignalSMA,PRICE_CLOSE,MODE_MAIN,1);
SignalCurrent=iMACD(NULL,0,FastEMA,SlowEMA,SignalSMA,PRICE_CLOSE,MODE_SIGNAL,0);
SignalPrevious=iMACD(NULL,0,FastEMA,SlowEMA,SignalSMA,PRICE_CLOSE,MODE_SIGNAL,1);
MaCurrent=iMA(NULL,0,MATrendPeriod,0,MODE_EMA,PRICE_CLOSE,0);
MaPrevious=iMA(NULL,0,MATrendPeriod,0,MODE_EMA,PRICE_CLOSE,1);
RSICurrent=iRSI(NULL,0,RSI_PERIOD,PRICE_CLOSE,0);
RSIPrevious=iRSI(NULL,0,RSI_PERIOD,PRICE_CLOSE,1);
double tenkanSen= iIchimoku(NULL,PERIOD_CURRENT,Tenkan,Kijun,Senkou,MODE_TENKANSEN,0);
double kijunSen = iIchimoku(NULL,PERIOD_CURRENT,Tenkan,Kijun,Senkou,MODE_KIJUNSEN,0);
double tenkanSenHist= iIchimoku(NULL,PERIOD_CURRENT,Tenkan,Kijun,Senkou,MODE_TENKANSEN,1);
double kijunSenHist = iIchimoku(NULL,PERIOD_CURRENT,Tenkan,Kijun,Senkou,MODE_KIJUNSEN,1);
double tenkanSen5=iIchimoku(NULL,PERIOD_CURRENT,Tenkan,Kijun,Senkou,MODE_TENKANSEN,1);
double slope=(tenkanSen-tenkanSen5)*1000;



double ChinkouSpanLatest=iIchimoku(NULL,0,Tenkan,Kijun,Senkou,MODE_CHINKOUSPAN,Kijun+1); // Latest closed bar with Chinkou.
double ChinkouSpanPreLatest=iIchimoku(NULL,0,Tenkan,Kijun,Senkou,MODE_CHINKOUSPAN,Kijun+2); // Bar older than latest closed bar with Chinkou.

                                                                                    // Bullish entry condition


// Kumo confirmation. When cross is happening current price (latest close) should be above/below both Senkou Spans, or price should close above/below both Senkou Spans after a cross.
double SenkouSpanALatestByPrice = iIchimoku(NULL, 0, Tenkan, Kijun, Senkou, MODE_SENKOUSPANA, 1); // Senkou Span A at time of latest closed price bar.
double SenkouSpanBLatestByPrice = iIchimoku(NULL, 0, Tenkan, Kijun, Senkou, MODE_SENKOUSPANB, 1); // Senkou Span B at time of latest closed price bar.
if((Close[1]>SenkouSpanALatestByPrice) && (Close[1]>SenkouSpanBLatestByPrice)) KumoBullConfirmation=true;
else KumoBullConfirmation=false;
if((Close[1]<SenkouSpanALatestByPrice) && (Close[1]<SenkouSpanBLatestByPrice)) KumoBearConfirmation=true;
else KumoBearConfirmation=false;

// Kumo/Chinkou confirmation. When cross is happening Chinkou at its latest close should be above/below both Senkou Spans at that time, or it should close above/below both Senkou Spans after a cross.
double SenkouSpanALatestByChinkou = iIchimoku(NULL, 0, Tenkan, Kijun, Senkou, MODE_SENKOUSPANA, Kijun + 1); // Senkou Span A at time of latest closed bar of Chinkou span.
double SenkouSpanBLatestByChinkou = iIchimoku(NULL, 0, Tenkan, Kijun, Senkou, MODE_SENKOUSPANB, Kijun + 1); // Senkou Span B at time of latest closed bar of Chinkou span.
if((ChinkouSpanLatest>SenkouSpanALatestByChinkou) && (ChinkouSpanLatest>SenkouSpanBLatestByChinkou)) KumoChinkouBullConfirmation=true;
else KumoChinkouBullConfirmation=false;
if((ChinkouSpanLatest<SenkouSpanALatestByChinkou) && (ChinkouSpanLatest<SenkouSpanBLatestByChinkou)) KumoChinkouBearConfirmation=true;
else KumoChinkouBearConfirmation=false;





if((ChinkouSpanLatest>Close[Kijun+1]) && (ChinkouSpanPreLatest<=Close[Kijun+2]))
  {
   ChinkouPriceBull = true;
   ChinkouPriceBear = false;
  }
// Bearish entry condition
else if((ChinkouSpanLatest<Close[Kijun+1]) && (ChinkouSpanPreLatest>=Close[Kijun+2]))
  {
   ChinkouPriceBull = false;
   ChinkouPriceBear = true;
  }
else if(ChinkouSpanLatest==Close[Kijun+1]) // Voiding entry conditions if cross is ongoing.
  {
   ChinkouPriceBull = false;
   ChinkouPriceBear = false;
  }


//insertDayFilter

//insertHourFilter

	if(queryOrdersCount(OP_BUY) > 0 ){

   int pattern_status_ID = detectLongExitPattern();
	if( PATTERN_NONE != pattern_status_ID )
		return (pattern_status_ID);
		}

   if(queryOrdersCount(OP_SELL) > 0 ){

	pattern_status_ID = detectShortExitPattern();
	if( PATTERN_NONE != pattern_status_ID )
		return (pattern_status_ID);
		}

	pattern_status_ID = detectLongEntryPattern();
	if( PATTERN_NONE != pattern_status_ID )
		return (pattern_status_ID);

	pattern_status_ID = detectShortEntryPattern();
	if( PATTERN_NONE != pattern_status_ID )
		return (pattern_status_ID);

	return (PATTERN_NONE);
}


//Indicator Filters
int IchimokuLong()
{
   double SenkouSpanALatestByPriceF = iIchimoku(NULL, 0, Tenkan, Kijun, Senkou, MODE_SENKOUSPANA, -25);
   double SenkouSpanBLatestByPriceF = iIchimoku(NULL, 0, Tenkan, Kijun, Senkou, MODE_SENKOUSPANB, -25);
   double kumo = (SenkouSpanALatestByPriceF - SenkouSpanBLatestByPriceF) * 10000;

   int IchimokuLongSignal = PATTERN_NONE;

   if(ChinkouPriceBull)
      {
         if (USE_KUMOMOD == 1)
            {
               if ((KumoBullConfirmation) && (KumoChinkouBullConfirmation) && (kumo > kumoThreshold))
                  {
                     ChinkouPriceBull=false;
                     IchimokuLongSignal=1;
                  }
            }
         if (USE_KUMOMOD != 1)
            {
               if ((KumoBullConfirmation) && (KumoChinkouBullConfirmation))
                  {
                     ChinkouPriceBull=false;
                     IchimokuLongSignal=1;
                  }
            }
       }
return(IchimokuLongSignal);
}


int IchimokuShort()
{
   int IchimokuShortSignal = PATTERN_NONE;

   double SenkouSpanALatestByPriceF = iIchimoku(NULL, 0, Tenkan, Kijun, Senkou, MODE_SENKOUSPANA, -25);
   double SenkouSpanBLatestByPriceF = iIchimoku(NULL, 0, Tenkan, Kijun, Senkou, MODE_SENKOUSPANB, -25);
   double kumo = (SenkouSpanALatestByPriceF - SenkouSpanBLatestByPriceF) * 10000;

   if(ChinkouPriceBear)
      {
         if (USE_KUMOMOD == 1)
            {
               if (((KumoBearConfirmation) && (KumoChinkouBearConfirmation) && (kumo <- kumoThreshold)))
                  {
                     ChinkouPriceBear=false;
                     IchimokuShortSignal=1;
                  }
            }
         if (USE_KUMOMOD != 1)
            {
               if (((KumoBearConfirmation) && (KumoChinkouBearConfirmation)))
                  {
                     ChinkouPriceBear=false;
                     IchimokuShortSignal=1;
                  }
            }
       }
return(IchimokuShortSignal);
}

int MACDLong()
{
   int MACDLongSignal = PATTERN_NONE;

   if (
         (MacdCurrent < 0 && MacdCurrent > SignalCurrent && MacdPrevious < SignalPrevious && MathAbs(MacdCurrent) > (MACDOpenLevel*Point) && MaCurrent > MaPrevious)
       )
       MACDLongSignal = 1;

return(MACDLongSignal);
}

int MACDShort()
{
   int MACDShortSignal = PATTERN_NONE;

   if (
         (MacdCurrent > 0 && MacdCurrent < SignalCurrent && MacdPrevious > SignalPrevious && MacdCurrent > (MACDOpenLevel*Point) && MaCurrent < MaPrevious)
       )
       MACDShortSignal = 1;

return(MACDShortSignal);
}


int RSILong()
{
   int RSILongSignal = PATTERN_NONE;

   if (
         (RSICurrent > RSIPrevious && RSICurrent > RSI_LONG ) //< 75)
      )
      RSILongSignal = 1;

return(RSILongSignal);
}

int RSIShort()
{
   int RSIShortSignal = PATTERN_NONE;

   if (
         (RSICurrent < RSIPrevious && RSICurrent < RSI_SHORT)
      )
      RSIShortSignal = 1;

return(RSIShortSignal);
}

int RSILongExit()
{

 int RSILongExitSignal = PATTERN_NONE;

   if (
         (RSICurrent < RSIPrevious && RSICurrent > RSI_LONGEXIT)
      )
      RSILongExitSignal = 1;

return(RSILongExitSignal);

}

int RSIShortExit()
{

 int RSIShortExitSignal = PATTERN_NONE;

   if (
         (RSICurrent > RSIPrevious && RSICurrent < RSI_SHORTEXIT)
      )
      RSIShortExitSignal = 1;

return(RSIShortExitSignal);

}

int MACDShortExit()
{
   int MACDShortExitSignal = PATTERN_NONE;

   if (
         (MacdCurrent < 0 && MacdCurrent > SignalCurrent  && MacdPrevious < SignalPrevious && MathAbs(MacdCurrent) > (MACDCloseLevel*Point))
      )
      MACDShortExitSignal = 1;

return(MACDShortExitSignal);
}

int MACDLongExit()
{
   int MACDLongExitSignal = PATTERN_NONE;

   if (
         (MacdCurrent > 0 && MacdCurrent < SignalCurrent && MacdPrevious > SignalPrevious && MacdCurrent > (MACDCloseLevel*Point))
      )
      MACDLongExitSignal = 1;

return(MACDLongExitSignal);
}


int ShortPriceAction()
{
   int ShortActionSignal = PATTERN_NONE;

   if (
         (Close[11] < High[6]&&High[6] < High[11]&&Open[16] < Low[11])
||
         (Open[6] < High[6]&&Open[16] < High[21]&&Open[3] < Open[6])
||
         (Open[21] < Low[6]&&Open[21] < Low[16]&&Open[11] < High[6])
||
         (Open[16] < Low[16]&&Open[16] < High[21]&&Open[11] < Open[6])
||
         (Open[21] < Close[6]&&Open[11] < Low[6]&&Open[11] < High[6])
||
         (High[1] < Open[6]&&Open[11] < Open[16]&&Open[16] < Open[21])
||
         (Open[11] < High[6]&&High[6] < High[11]&&Open[1] < Open[11])
||
         (Close[11] < High[11]&&Close[1] < Open[16]&&Low[11] < Low[6])
||
         (Close[16] < Low[11]&&Close[11] < High[6]&&High[11] < Close[6])
||
         (Close[11] < Close[6]&&Close[16] < Close[1]&&Open[16] < High[16])
||
         (Close[6] < High[1]&&High[11] < Close[6]&&High[6] < High[11])
||
         (Close[6] < High[6]&&High[16] < Open[21]&&Open[11] < Low[16])
||
         //Qu(x1,x2,x3,x4) > 0
         ((Close[11] < High[6]&&High[6] < High[11]&&Open[16] < Low[11])
         &&
         (Open[6] < High[6]&&Open[16] < High[21]&&Open[3] < Open[6])
         &&
         (Open[21] < Low[6]&&Open[21] < Low[16]&&Open[11] < High[6])
         &&
         (Open[16] < Low[16]&&Open[16] < High[21]&&Open[11] < Open[6])
         &&
         (Open[21] < Close[6]&&Open[11] < Low[6]&&Open[11] < High[6])
         &&
         (High[1] < Open[6]&&Open[11] < Open[16]&&Open[16] < Open[21])
         &&
         (Open[11] < High[6]&&High[6] < High[11]&&Open[1] < Open[11])
         &&
         (Close[11] < High[11]&&Close[1] < Open[16]&&Low[11] < Low[6])
         &&
         (Close[16] < Low[11]&&Close[11] < High[6]&&High[11] < Close[6])
         &&
         (Close[11] < Close[6]&&Close[16] < Close[1]&&Open[16] < High[16])
         &&
         (Close[6] < High[1]&&High[11] < Close[6]&&High[6] < High[11])
         &&
         (Close[6] < High[6]&&High[16] < Open[21]&&Open[11] < Low[16]))

      )
      ShortActionSignal = 1;

return(ShortActionSignal);
}

int LongPriceAction()
{
   int LongActionSignal = PATTERN_NONE;

   if (
         (Close[11] > Low[6] && Low[6] > Low[11] && Open[16] > High[11])
||
         (Open[6] > Low[6]&&Open[16] > Low[21]&&Open[3] > Open[6])
||
         (Open[21] > High[6]&&Open[21] > High[16]&&Open[11] > Low[6])
||
         (Open[16] > High[16]&&Open[16] > Low[21]&&Open[11] > Open[6])
||
         (Open[21] > Close[6]&&Open[11] > High[6]&&Open[11] > Low[6])
||
         (Low[1] > Open[6]&&Open[11] > Open[16]&&Open[16] > Open[21])
||
         (Open[11] > Low[6]&&Low[6] > Low[11]&&Open[1] > Open[11])
||
         (Close[11] > Low[11]&&Close[1] > Open[16]&&High[11] > High[6])
||
         (Close[16] > High[11]&&Close[11] > Low[6]&&Low[11] > Close[6])
||
         (Close[11] > Close[6]&&Close[16] > Close[1]&&Open[16] > Low[16])
||
         (Close[6] > Low[1]&&Low[11] > Close[6]&&Low[6] > Low[11])
||
         (Close[6] > Low[6]&&Low[16] > Open[21]&&Open[11] > High[16])
||
         //Qu(x1,x2,x3,x4) > 0
         ((Close[11] > Low[6] && Low[6] > Low[11] && Open[16] > High[11])
         &&
         (Open[6] > Low[6]&&Open[16] > Low[21]&&Open[3] > Open[6])
         &&
         (Open[21] > High[6]&&Open[21] > High[16]&&Open[11] > Low[6])
         &&
         (Open[16] > High[16]&&Open[16] > Low[21]&&Open[11] > Open[6])
         &&
         (Open[21] > Close[6]&&Open[11] > High[6]&&Open[11] > Low[6])
         &&
         (Low[1] > Open[6]&&Open[11] > Open[16]&&Open[16] > Open[21])
         &&
         (Open[11] > Low[6]&&Low[6] > Low[11]&&Open[1] > Open[11])
         &&
         (Close[11] > Low[11]&&Close[1] > Open[16]&&High[11] > High[6])
         &&
         (Close[16] > High[11]&&Close[11] > Low[6]&&Low[11] > Close[6])
         &&
         (Close[11] > Close[6]&&Close[16] > Close[1]&&Open[16] > Low[16])
         &&
         (Close[6] > Low[1]&&Low[11] > Close[6]&&Low[6] > Low[11])
         &&
         (Close[6] > Low[6]&&Low[16] > Open[21]&&Open[11] > High[16]))

      )
      LongActionSignal = 1;

return(LongActionSignal);
}

int detectLongEntryPattern()
{

      int longEntryPattern = PATTERN_NONE;

      if (
            (USE_ICHIMOKU == 0 && USE_MACD == 0 && USE_RSI == 0 && LongPriceAction() == 1)
         || (USE_ICHIMOKU == 0 && USE_MACD == 1 && USE_RSI == 0 && MACDLong() == 1 && LongPriceAction() == 1)
         || (USE_ICHIMOKU == 1 && USE_MACD == 1 && USE_RSI == 0 && IchimokuLong() == 1 && MACDLong() == 1 && LongPriceAction() == 1)
         || (USE_ICHIMOKU == 0 && USE_MACD == 1 && USE_RSI == 1 && RSILong() == 1 && MACDLong() == 1 && LongPriceAction() == 1)
         || (USE_ICHIMOKU == 0 && USE_MACD == 0 && USE_RSI == 1 && RSILong() == 1 && LongPriceAction() == 1)
         || (USE_ICHIMOKU == 1 && USE_MACD == 0 && USE_RSI == 1 && IchimokuLong() == 1 && RSILong() == 1 && LongPriceAction() == 1)
         || (USE_ICHIMOKU == 1 && USE_MACD == 0 && USE_RSI == 0 && IchimokuLong() == 1 && LongPriceAction() == 1)
         || (USE_ICHIMOKU == 1 && USE_MACD == 1 && USE_RSI == 1 && IchimokuLong() == 1 && MACDLong() == 1 && RSILong() == 1 && LongPriceAction() == 1)
      )
      longEntryPattern = LONG_ENTRY_PATTERN;

return(longEntryPattern);
}

int detectShortEntryPattern()
{

   int shortEntryPattern = PATTERN_NONE;

   if (
            (USE_ICHIMOKU == 0 && USE_MACD == 0 && USE_RSI == 0 && ShortPriceAction() == 1)
         || (USE_ICHIMOKU == 0 && USE_MACD == 1 && USE_RSI == 0 && MACDShort() == 1 && ShortPriceAction() == 1)
         || (USE_ICHIMOKU == 1 && USE_MACD == 1 && USE_RSI == 0 && IchimokuShort() == 1 && MACDShort() == 1 && ShortPriceAction() == 1)
         || (USE_ICHIMOKU == 0 && USE_MACD == 1 && USE_RSI == 1 && RSIShort() == 1 && MACDShort() == 1 && LongPriceAction() == 1)
         || (USE_ICHIMOKU == 0 && USE_MACD == 0 && USE_RSI == 1 && RSIShort() == 1 && ShortPriceAction() == 1)
         || (USE_ICHIMOKU == 1 && USE_MACD == 0 && USE_RSI == 1 && IchimokuShort() == 1 && RSIShort() == 1 && ShortPriceAction() == 1)
         || (USE_ICHIMOKU == 1 && USE_MACD == 0 && USE_RSI == 0 && IchimokuShort() == 1 && ShortPriceAction() == 1)
         || (USE_ICHIMOKU == 1 && USE_MACD == 1 && USE_RSI == 1 && IchimokuShort() == 1 && MACDShort() == 1 && RSIShort() == 1 && ShortPriceAction() == 1)
      )
      shortEntryPattern = SHORT_ENTRY_PATTERN;

return(shortEntryPattern);
}

int detectLongExitPattern()
{
   int longExitPattern = (PATTERN_NONE);

   if (
            (USE_ICHIMOKU == 0 && USE_MACD == 0 && USE_RSI == 0 && ShortPriceAction() == 1)
         || (USE_ICHIMOKU == 0 && USE_MACD == 1 && USE_RSI == 0 && MACDLongExit() == 1 && ShortPriceAction() == 1)
         || (USE_ICHIMOKU == 1 && USE_MACD == 1 && USE_RSI == 0 && IchimokuShort() == 1 && MACDLongExit() == 1 && ShortPriceAction() == 1)
         || (USE_ICHIMOKU == 0 && USE_MACD == 1 && USE_RSI == 1 && RSILongExit() == 1 && MACDLongExit() == 1 && LongPriceAction() == 1)
         || (USE_ICHIMOKU == 0 && USE_MACD == 0 && USE_RSI == 1 && RSILongExit() == 1 && ShortPriceAction() == 1)
         || (USE_ICHIMOKU == 1 && USE_MACD == 0 && USE_RSI == 1 && IchimokuShort() == 1 && RSILongExit() == 1 && ShortPriceAction() == 1)
         || (USE_ICHIMOKU == 1 && USE_MACD == 0 && USE_RSI == 0 && IchimokuShort() == 1 && ShortPriceAction() == 1)
         || (USE_ICHIMOKU == 1 && USE_MACD == 1 && USE_RSI == 1 && IchimokuShort() == 1 && MACDLongExit() == 1 && RSILongExit() == 1 && ShortPriceAction() == 1)
      )
      longExitPattern = LONG_EXIT_PATTERN;

return(longExitPattern);
}


int detectShortExitPattern()
{
   int shortExitPattern = (PATTERN_NONE);

if (
            (USE_ICHIMOKU == 0 && USE_MACD == 0 && USE_RSI == 0 && LongPriceAction() == 1)
         || (USE_ICHIMOKU == 0 && USE_MACD == 1 && USE_RSI == 0 && MACDShortExit() == 1 && LongPriceAction() == 1)
         || (USE_ICHIMOKU == 1 && USE_MACD == 1 && USE_RSI == 0 && IchimokuLong() == 1 && MACDShortExit() == 1 && LongPriceAction() == 1)
         || (USE_ICHIMOKU == 0 && USE_MACD == 1 && USE_RSI == 1 && RSIShortExit() == 1 && MACDShortExit() == 1 && LongPriceAction() == 1)
         || (USE_ICHIMOKU == 0 && USE_MACD == 0 && USE_RSI == 1 && RSIShortExit() == 1 && LongPriceAction() == 1)
         || (USE_ICHIMOKU == 1 && USE_MACD == 0 && USE_RSI == 1 && IchimokuLong() == 1 && RSIShortExit() == 1 && LongPriceAction() == 1)
         || (USE_ICHIMOKU == 1 && USE_MACD == 0 && USE_RSI == 0 && IchimokuLong() == 1 && LongPriceAction() == 1)
         || (USE_ICHIMOKU == 1 && USE_MACD == 1 && USE_RSI == 1 && IchimokuLong() == 1 && MACDShortExit() == 1 && RSIShortExit() == 1 && LongPriceAction() == 1)
      )
      shortExitPattern = SHORT_EXIT_PATTERN;

return(shortExitPattern);
}

void calculateATR()
{
	// Use the current ATR value, taking
	// into account sunday candle existence.

	double currentHigh, currentLow, previousClose, trueRange, sumTrueRange = 0;
	g_ATR = 0;

	if(g_period == 1440)
	{
     for (int i= 0; i < ATR_PERIOD; i++)
     {
        currentHigh   =  High[i+1];
        currentLow    =  Low[i+1];
        previousClose =  Close[i+2];
        trueRange = MathMax( (currentHigh-currentLow), MathMax(MathAbs(currentLow-previousClose), MathAbs(currentHigh-previousClose)));
        sumTrueRange += trueRange;
     }

     g_ATR = sumTrueRange/ATR_PERIOD ;
	 } else {

	 for (i=0; i< ATR_PERIOD; i++)
	{
	    int currentHighIndex = MathRound(((1440/2)/g_period)*i+(1440/g_period));
	    int currentLowIndex = MathRound(((1440/2)/g_period)*i+1);
		currentHigh  =  High[currentHighIndex];
		currentLow  =   Low[currentLowIndex];

		g_ATR += MathAbs(currentHigh-currentLow)/ATR_PERIOD;
	}


	 }

	if( MathAbs( g_ATR ) < EPSILON )
	{
		g_lastStatusID = STATUS_DIVIDE_BY_ZERO;
		return;
	}

	// The ATR is 0.0001 when initialization failure occurs.
	if( ( MathAbs( g_ATR ) - 0.0001 ) < EPSILON )
	{
		g_lastStatusID = STATUS_ATR_INIT_PROBLEM;
		return;
	}

}

void calculateContractSize()
{
	g_contractSize = MarketInfo( Symbol(),  MODE_LOTSIZE );
}


void calculateTradeSize()
{
	double atrForCalculation = g_ATR;
	if( isInstrumentJPY() )
		atrForCalculation /= 100;

      if (STOP_LOSS != 0)
		g_tradeSize = ( RISK * 0.01 * AccountBalance() ) / ( g_contractSize * STOP_LOSS * atrForCalculation );

      if (STOP_LOSS == 0)
		g_tradeSize = ( RISK * 0.01 * AccountBalance() ) / ( g_contractSize * 2 * atrForCalculation );

		if(DISABLE_COMPOUNDING && STOP_LOSS != 0)
		g_tradeSize = ( RISK * 0.01 * g_initialBalance ) / ( g_contractSize * STOP_LOSS * atrForCalculation );

		if(DISABLE_COMPOUNDING && STOP_LOSS == 0)
		g_tradeSize = ( RISK * 0.01 * g_initialBalance ) / ( g_contractSize * 2 * atrForCalculation );


	if( g_tradeSize > g_maxTradeSize )
		g_tradeSize = g_maxTradeSize;

	g_tradeSize = roundDouble(g_tradeSize);

}

void checkMinTradeSize()
{

	if (g_tradeSize < g_minTradeSize)
	{
	g_lastStatusID = STATUS_BELOW_MIN_LOT_SIZE ;
	}

}

double calculateStopLossPrice( int orderType, double openPrice )
{
	double price = 0;
	switch( orderType ) {
	case OP_BUY:
		price = openPrice - pipsToPrice( g_stopLossPIPs );
	break;
	case OP_SELL:
		price = openPrice + pipsToPrice( g_stopLossPIPs );
	break;
							  } // switch( orderType )

	price = NormalizeDouble( price, g_brokerDigits );

	if ( g_stopLossPIPs == 0 )
	return(0);

	return (price);
}

double calculateTakeProfitPrice( int orderType, double openPrice )
{
	double price = 0.0;

	switch( orderType ) {
	case OP_BUY:
		price = openPrice + pipsToPrice( g_takeProfitPIPs );
	break;
	case OP_SELL:
		price = openPrice - pipsToPrice( g_takeProfitPIPs );
	break;
							  } // switch( orderType )

	price = NormalizeDouble( price, g_brokerDigits );

	if ( g_takeProfitPIPs == 0 )
	return(0);

	return (price);
}

void calculateSpreadPIPS()
{
	g_spreadPIPs = MathAbs(Ask-Bid)*100 ;

	if( ( 5 == g_brokerDigits ) ||
		 ( 4 == g_brokerDigits )
	  )
	{
		g_spreadPIPs *= 100;
	}

}

void calculateStopLossPIPs()
{
	g_stopLossPIPs = 10000 * STOP_LOSS * g_ATR;
	if( g_stopLossPIPs < g_minimalStopPIPs )
	{
		g_stopLossPIPs = g_minimalStopPIPs;
	}

	if( isInstrumentJPY() )
	{
		g_stopLossPIPs /= 100;
	}
}

void adjustSlippage()
{
   g_adjustedSlippage = SLIPPAGE;

   // Support 5 digit brokers
   if( ( 3 == g_brokerDigits ) ||
       ( 5 == g_brokerDigits )
     )
   {
      g_adjustedSlippage *= 10;
   }

}

void calculateTakeProfitPIPs()
{
	g_takeProfitPIPs = 10000 * TAKE_PROFIT * g_ATR;
	if( isInstrumentJPY() )
	{
		g_takeProfitPIPs /= 100;
	}
}

double pipsToPrice( double pips )
{
	double calculationPIPs = pips;

	// Support 5 digit brokers
	if( ( 3 == g_brokerDigits ) ||
		 ( 5 == g_brokerDigits )
	  )
	{
		calculationPIPs *= 10;
	}

	return (calculationPIPs * g_pipValue);
}

bool isInstrumentJPY()
{
	int found = StringFind( Symbol(), "JPY", 0 );
	if( found == -1 )
		return (false);

	return (true);
}

int queryOrdersCount( int orderType )
{
// The query function is used for counting particular sets of orders
// for different purposes. It allows us to calculate amount of open longs,
// shorts or pending orders. It also allows to retrieve the amount of all
// the orders, opened by the expert by calling it with the QUERY_ALL argument.
	int query = QUERY_NONE,
		 ordersCount = 0;

	switch( orderType ) {
	case OP_BUY:
		query = QUERY_LONGS_COUNT;
	break;
	case OP_SELL:
		query = QUERY_SHORTS_COUNT;
	break;
	case OP_BUYSTOP:
		query = QUERY_BUY_STOP_COUNT;
	break;
	case OP_SELLSTOP:
		query = QUERY_SELL_STOP_COUNT;
	break;
	case OP_SELLLIMIT:
		query = QUERY_SELL_LIMIT_COUNT;
	break;
	case OP_BUYLIMIT:
		query = QUERY_BUY_LIMIT_COUNT;
	break;
	case QUERY_ALL:
		// A case to count all orders
		query = QUERY_ALL ;
	break;
							  } // switch( orderType )

	int total = OrdersTotal() ;
	for ( int i = 0 ; i < total+1; i++)
	{
		 if (!OrderSelect( i, SELECT_BY_POS, MODE_TRADES )) continue;

		if( (        OrderType() ==  OP_SELL   ) &&
			 ( OrderMagicNumber() == INSTANCE_ID ) &&
			 ( ( QUERY_SHORTS_COUNT == query ) || ( query == QUERY_ALL ) )
		  )
		{
			ordersCount++;
		}

		if( (       OrderType() ==   OP_BUY   ) &&
			 ( OrderMagicNumber()== INSTANCE_ID ) &&
			 ( ( query == QUERY_LONGS_COUNT ) || ( query == QUERY_ALL ) )
		  )
		{
			ordersCount++;
		}

		if( (       OrderType() == OP_SELLSTOP ) &&
			 ( OrderMagicNumber()==  INSTANCE_ID ) &&
			 ( ( query == QUERY_SELL_STOP_COUNT ) || ( query == QUERY_ALL ) )
		  )
		{
			ordersCount++;
		}

		if( (       OrderType() == OP_BUYSTOP ) &&
			 ( OrderMagicNumber()== INSTANCE_ID ) &&
			 ( ( query == QUERY_BUY_STOP_COUNT ) || ( query == QUERY_ALL ) )
		  )
		{
			ordersCount++;
		}

		if( (       OrderType() == OP_SELLLIMIT ) &&
			 ( OrderMagicNumber()== INSTANCE_ID   ) &&
			 ( ( query == QUERY_SELL_LIMIT_COUNT ) || ( query == QUERY_ALL ) )
		  )
		{
			ordersCount++;
		}

		if( (       OrderType()  == OP_BUYLIMIT ) &&
			 ( OrderMagicNumber() == INSTANCE_ID  ) &&
			 ( ( query == QUERY_BUY_LIMIT_COUNT ) || ( query == QUERY_ALL ) )
		  )
		{
      	ordersCount++;
		}
	}

	return(ordersCount);
}

double roundDouble( double value  )
{
	double roundedValue = 0.0;
	int roundingDigits = 0;

	double minimal_lot_step = MarketInfo(Symbol(), MODE_LOTSTEP) ;


	if (minimal_lot_step == 0.01)
		roundedValue = NormalizeDouble( value, 2 );
	if (minimal_lot_step == 0.05)
		roundedValue = NormalizeDouble( MathFloor(value * 20 + 0.5) / 20, 2 );
	if (minimal_lot_step == 0.1)
		roundedValue = NormalizeDouble( value, 1 );

	return (roundedValue);
}

void calculateInstanceBalance()
{

   g_instanceBalance = g_initialBalance;
   g_instancePL_UI = 0 ;

	int closedOrdersCount =  OrdersHistoryTotal();

	for( int i = 0; i < closedOrdersCount; i++ )
	{
		OrderSelect( i, SELECT_BY_POS, MODE_HISTORY );

		if( OrderMagicNumber() == INSTANCE_ID  )
		{
			g_instanceBalance += OrderProfit() + OrderSwap() ;
			g_instancePL_UI += OrderProfit() + OrderSwap() ;
		}

   }

}


int initUI()
{
	// Displayed in the main chart window
	ObjectCreate( g_objGeneralInfo,OBJ_LABEL, 0, 0, 0 );
	ObjectCreate( g_objTradeSize,  OBJ_LABEL, 0, 0, 0 );
	ObjectCreate( g_objStopLoss,   OBJ_LABEL, 0, 0, 0 );
	ObjectCreate( g_objTakeProfit, OBJ_LABEL, 0, 0, 0 );
	ObjectCreate( g_objATR,        OBJ_LABEL, 0, 0, 0 );
	ObjectCreate( g_objPL,         OBJ_LABEL, 0, 0, 0 );
	ObjectCreate( g_objBalance,           OBJ_LABEL, 0, 0, 0 );
	ObjectCreate( g_objStatusPane, OBJ_LABEL, 0, 0, 0 );


	// Bind to top left corner
	ObjectSet( g_objGeneralInfo,OBJPROP_CORNER, 0 );
	ObjectSet( g_objTradeSize,  OBJPROP_CORNER, 0 );
	ObjectSet( g_objBalance,           OBJPROP_CORNER, 0 );
	ObjectSet( g_objStopLoss,   OBJPROP_CORNER, 0 );
	ObjectSet( g_objTakeProfit, OBJPROP_CORNER, 0 );
   ObjectSet( g_objATR,        OBJPROP_CORNER, 0 );
	ObjectSet( g_objPL,         OBJPROP_CORNER, 0 );


	// Bind to bottom left corner
	ObjectSet( g_objStatusPane, OBJPROP_CORNER, 2 );

	// Set X offset
	ObjectSet( g_objGeneralInfo,OBJPROP_XDISTANCE, g_baseXOffset );
	ObjectSet( g_objTradeSize,  OBJPROP_XDISTANCE, g_baseXOffset );
	ObjectSet( g_objStopLoss,   OBJPROP_XDISTANCE, g_baseXOffset );
	ObjectSet( g_objTakeProfit, OBJPROP_XDISTANCE, g_baseXOffset );
	ObjectSet( g_objBalance,           OBJPROP_XDISTANCE, g_baseXOffset );
	ObjectSet( g_objATR,        OBJPROP_XDISTANCE, g_baseXOffset );
	ObjectSet( g_objPL,         OBJPROP_XDISTANCE, g_baseXOffset );
	ObjectSet( g_objStatusPane, OBJPROP_XDISTANCE, g_baseXOffset );


	// Prepare patterns name table
	ArrayResize( g_detectedPatternNames, 6 );
	g_detectedPatternNames[ 0 ] = "Long entry pattern detected";
	g_detectedPatternNames[ 1 ] = "Short entry pattern detected";
	g_detectedPatternNames[ 2 ] = "Long exit pattern detected";
	g_detectedPatternNames[ 3 ] = "Short exit pattern detected";

	ArrayResize( g_statusMessages, 10);
	g_statusMessages[ STATUS_INVALID_BARS_COUNT ] = "Invalid bars count";
	g_statusMessages[ STATUS_INVALID_TIMEFRAME  ] = "Invalid timeframe, trading suspended";
	g_statusMessages[ STATUS_DIVIDE_BY_ZERO     ] = "ATR not initialized correctly (zero divide)";
   g_statusMessages[ STATUS_ATR_INIT_PROBLEM   ] = "ATR not initialized correctly";
   g_statusMessages[ STATUS_TRADE_CONTEXT_BUSY ] = "Trade context busy (server issue)";
   g_statusMessages[ STATUS_TRADING_NOT_ALLOWED] = "Trading not allowed (server issue)";
   g_statusMessages[ STATUS_DUPLICATE_ID       ] = "Trading Stopped, Duplicate ID" ;
   g_statusMessages[ STATUS_RUNNING_ON_DEFAULTS] = "Change to defaults, Instance IDs cannot be -1" ;
   g_statusMessages[ STATUS_BELOW_MIN_LOT_SIZE ] = "Lot size is below minimum (capital too low)" ;
   g_statusMessages[ STATUS_LIBS_NOT_ALLOWED ]   = "Please allow external lib usage" ;
   g_statusMessages[ STATUS_NOT_ENOUGH_DATA ]   = "Not enough data present on chart" ;
   g_statusMessages[ STATUS_SPREAD_TOO_HIGH ]   = "Spread above allowed threshold" ;
	// Set severity status to default
	g_severityStatus = SEVERITY_INFO;

	return (0);
}

void updateUI()
{
	updateStatusUI( false );


	// General Info
	string text = "VegaBot V4Beta 2017" ;
	ObjectSet( g_objGeneralInfo, OBJPROP_YDISTANCE, g_baseYOffset );
   ObjectSetText( g_objGeneralInfo, text, FontSize, g_fontName, INFORMATION_COLOR );

	// Trade size
	text = StringConcatenate( "Trade size: ", g_tradeSize );
	ObjectSet( g_objTradeSize, OBJPROP_YDISTANCE, g_baseYOffset + FontSize * g_textDensingFactor );
   ObjectSetText( g_objTradeSize, text, FontSize, g_fontName, INFORMATION_COLOR );

	// Stop loss
	text = StringConcatenate( "Stop loss: ", g_stopLossPIPs );
	ObjectSet( g_objStopLoss, OBJPROP_YDISTANCE, g_baseYOffset + FontSize * g_textDensingFactor*2 );
	ObjectSetText( g_objStopLoss, text, FontSize, g_fontName, INFORMATION_COLOR );

	// Take profit
	text = StringConcatenate( "Take profit: ", g_takeProfitPIPs );
	ObjectSet( g_objTakeProfit, OBJPROP_YDISTANCE, g_baseYOffset + FontSize * g_textDensingFactor * 3 );
	ObjectSetText( g_objTakeProfit, text, FontSize, g_fontName, INFORMATION_COLOR );

	// ATR
	text = StringConcatenate( "ATR: ", g_ATR );
	ObjectSet( g_objATR, OBJPROP_YDISTANCE, g_baseYOffset + FontSize * g_textDensingFactor * 4 );
	ObjectSetText( g_objATR, text, FontSize, g_fontName, INFORMATION_COLOR );

	// Profit/loss
	text = StringConcatenate( "Profit up until now is: ", g_instancePL_UI);
	ObjectSet( g_objPL, OBJPROP_YDISTANCE, g_baseYOffset + FontSize * g_textDensingFactor * 5 );
	ObjectSetText( g_objPL, text, FontSize, g_fontName, INFORMATION_COLOR );

	text = StringConcatenate( "Balance is: ", AccountBalance());
	ObjectSet( g_objBalance, OBJPROP_YDISTANCE, g_baseYOffset + FontSize * g_textDensingFactor * 6 );
	ObjectSetText( g_objBalance, text, FontSize, g_fontName, INFORMATION_COLOR );


	// Update the window content
	WindowRedraw();
}

void updateStatusUI( bool doRedraw )
{
	// The purpose of setting message to empty string
	// is to clean the screen from irrelevant info.
	string statusMessage = "";
	color clr = CLR_NONE;
	switch( g_severityStatus ) {
	case SEVERITY_INFO:
		clr = INFORMATION_COLOR;
		if ( g_lastDetectedPatternID >= 0 )
		statusMessage = g_detectedPatternNames[ g_lastDetectedPatternID ];
	break;
	case SEVERITY_ERROR:
		switch( g_lastStatusID ) {
		case STATUS_INVALID_BARS_COUNT:
		case STATUS_INVALID_TIMEFRAME:
			statusMessage = g_statusMessages[ g_lastStatusID ];
		break;
		case STATUS_LAST_ERROR:
			statusMessage = ErrorDescription( g_lastStatusID );
		break;
		case STATUS_ATR_INIT_PROBLEM  :
			statusMessage = g_statusMessages[ g_lastStatusID ];
			break;
		case STATUS_DIVIDE_BY_ZERO :
			statusMessage = g_statusMessages[ g_lastStatusID ];
	    	break;
	    case STATUS_TRADE_CONTEXT_BUSY :
			statusMessage = g_statusMessages[ g_lastStatusID ];
			break;
		case STATUS_DUPLICATE_ID :
			statusMessage = g_statusMessages[ g_lastStatusID ];
			break;
		case STATUS_TRADING_NOT_ALLOWED :
			statusMessage = g_statusMessages[ g_lastStatusID ];
			break;
		case STATUS_RUNNING_ON_DEFAULTS :
			statusMessage = g_statusMessages[ g_lastStatusID ];
			break;
		case STATUS_BELOW_MIN_LOT_SIZE :
			statusMessage = g_statusMessages[ g_lastStatusID ];
			break;
		case STATUS_LIBS_NOT_ALLOWED :
			statusMessage = g_statusMessages[ g_lastStatusID ];
			break;
		case STATUS_NOT_ENOUGH_DATA :
			statusMessage = g_statusMessages[ g_lastStatusID ];
			break;
		case STATUS_SPREAD_TOO_HIGH :
			statusMessage = g_statusMessages[ g_lastStatusID ];
			break;
										 } // switch( g_lastStatusID )

		if( g_lastError != statusMessage)
		{
		g_alertStatus = ALERT_STATUS_NEW ;
		}

		if(ALERT_STATUS_NEW == g_alertStatus)
		{

		Alert( statusMessage );

		g_alertStatus = ALERT_STATUS_DISPLAYED ;
		g_lastError = statusMessage ;
		}

		clr = ERROR_COLOR;
	break;
										} // switch( g_severityStatus )

	ObjectSet( g_objStatusPane, OBJPROP_YDISTANCE, g_baseYOffset );
   ObjectSetText( g_objStatusPane, statusMessage, FontSize * 1.2, g_fontName, clr );

   if( doRedraw )
   {
  		// Update the window content
		WindowRedraw();
	}
}

void deinitUI()
{
   ObjectDelete( g_objBalance );
   ObjectDelete( g_objGeneralInfo );
	ObjectDelete( g_objTradeSize );
	ObjectDelete( g_objStopLoss );
	ObjectDelete( g_objTakeProfit );
	ObjectDelete( g_objATR );
	ObjectDelete( g_objPL );
	ObjectDelete( g_objStatusPane );
}

void logOrderSendInfo(
               string commonInfo,
               double orderSize,
               double openPrice,
                  int slippage,
               double stopLoss,
               double takeProfit,
                  int errorCode
                     )
{
   string info = StringConcatenate(
                      commonInfo,
                      "instrument: ",   g_symbol,
                      " order size: ",  orderSize,
                      " open price: ",  openPrice,
                      " slippage: ",    slippage,
                      " stop loss: ",   stopLoss,
                      " take profit: ", takeProfit
                                  );
   Print( info );
   if( ERR_NO_ERROR == errorCode )
      return;

   Print( "Error info: ", errorCode, " description: ", ErrorDescription( errorCode ) );
}

void logOrderModifyInfo(
                 string commonInfo,
                    int tradeTicket,
                 double openPrice,
                 double stopLoss,
                 double takeProfit,
                    int errorCode
                       )
{
   string info = StringConcatenate(
                      commonInfo,
                      "instrument: ",   g_symbol,
                      " ticket: ",      tradeTicket,
                      " open price: ",  openPrice,
                      " stop loss: ",   stopLoss,
                      " take profit: ", takeProfit
                                  );
   Print( info );
   if( ERR_NO_ERROR == errorCode )
      return;

   Print( "Error info: ", errorCode, " description: ", ErrorDescription( errorCode ) );
}

void logOrderCloseInfo(
                 string commonInfo,
                    int orderTicket,
                    int errorCode
                       )
{
   string info = StringConcatenate(
                      commonInfo,
                      "instrument: ", g_symbol,
                      " ticket: ",    orderTicket
                                  );
   Print( info );
   if( ERR_NO_ERROR == errorCode )
      return;

   Print( "Error info: ", errorCode, " description: ", ErrorDescription( errorCode ) );
}


