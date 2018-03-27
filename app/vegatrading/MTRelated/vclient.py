import zmq

c = zmq.Context()

print("Connecting to the mt4 server...")
s = c.socket(zmq.REQ)
s.connect("tcp://127.0.0.1:5557")

r = c.socket(zmq.PULL)
r.connect("tcp://127.0.0.1:5558")

while True:
	try:
		msg = input("Enter command: ")
		if msg == "exit":
			break;
		s.send_string(msg, encoding='utf-8')

		print("Waiting for metatrader to respond...")
		m = s.recv();
		print("Reply from server ", m)
	except Exception as e:
		print(e)

