import argparse

import pika

parser = argparse.ArgumentParser()
parser.add_argument("--once", action="store_true", help="Quitter après le premier message.")
args = parser.parse_args()

with pika.BlockingConnection(pika.ConnectionParameters("localhost")) as connection:
    channel = connection.channel()
    channel.queue_declare(queue="hello")

    def receive(channel, method, properties, body):
        print(f"Reçu : {body.decode('utf-8')}", flush=True)
        channel.basic_ack(method.delivery_tag)
        if args.once:
            channel.stop_consuming()

    channel.basic_consume(queue="hello", on_message_callback=receive)
    try:
        channel.start_consuming()
    except KeyboardInterrupt:
        channel.stop_consuming()
