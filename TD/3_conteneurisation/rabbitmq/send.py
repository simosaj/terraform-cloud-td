import sys

import pika

message = " ".join(sys.argv[1:]) or "Bonjour depuis le TD 3 !"
with pika.BlockingConnection(pika.ConnectionParameters("localhost")) as connection:
    channel = connection.channel()
    channel.queue_declare(queue="hello")
    channel.basic_publish(exchange="", routing_key="hello", body=message.encode("utf-8"))
    print(f"Envoyé : {message}")
