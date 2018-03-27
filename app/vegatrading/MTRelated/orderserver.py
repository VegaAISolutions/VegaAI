import time
import zmq

client_context = zmq.Context()
client_listen = client_context.socket(zmq.REP)
client_listen.bind("tcp://127.0.0.1:5556")

mt4_pushcontext = zmq.Context()
mt4_push = mt4_pushcontext.socket(zmq.PUSH)
mt4_push.bind("tcp://127.0.0.1:5557")

mt4_listencontext = zmq.Context()
mt4_listen = mt4_listencontext.socket(zmq.REQ)
mt4_listen = mt4_listen.bind("tcp://127.0.0.1:5558")
#this code will handle placing orders to the various destination systems such as metatrader
print("Order server started....")
while True:
    m = client_listen.recv()
    print("Processing Request: %s", m)

    client_listen.send(b"Order Received")

    #TODO - Add logic to pass in the values based on the buy or sell.
    #if m == 'Buy':
    trade = 'TRADE|OPEN|0|BTCUSD|0|50|50|R-to-MetaTrader4|12345678|1'

    mt4_push.send_string(trade)

    mt4_response = mt4_listen.recv()

    print(mt4_response)

    print("Server pausing for 5 seconds")
    time.sleep(5000)