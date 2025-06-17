#!/usr/bin/env python3
import requests
import time
import sys
from concurrent import futures
import os
from flask import Flask, request, jsonify
from cloudevents.http import from_http
import json


if __name__ == "__main__":
    # Dapr Pub/Sub component and topic
    PUBSUB_NAME = "messagepubsub"
    TOPIC_NAME = "LLMOrchestrator"

    app = Flask(__name__)

    app_port = os.getenv('APP_PORT', '6002')

    # Register Dapr pub/sub subscriptions
    @app.route('/dapr/subscribe', methods=['GET'])
    def subscribe():
        subscriptions = [{
            'pubsubname': PUBSUB_NAME,
            'topic': TOPIC_NAME,
            'route': 'chat'
        }]
        print('Dapr pub/sub is subscribed to: ' + json.dumps(subscriptions))
        return jsonify(subscriptions)


    # Dapr subscription in /dapr/subscribe sets up this route
    @app.route('/chat', methods=['POST'])
    def orders_subscriber():
        event = from_http(request.headers, request.get_data())
        print('Subscriber received: %s' % event.data['content'], flush=True)
        print("Event attributes:")
        for attr, value in event._attributes.items():
            print(f"{attr}: {value}")
        return json.dumps({'success': True}), 200, {
            'ContentType': 'application/json'}

    status_url = "http://localhost:8004/status"
    healthy = False
    for attempt in range(1, 11):
        try:
            print(f"Attempt {attempt}...")
            response = requests.get(status_url, timeout=5)

            if response.status_code == 200:
                print("Workflow app is healthy!")
                healthy = True
                break
            else:
                print(f"Received status code {response.status_code}: {response.text}")

        except requests.exceptions.RequestException as e:
            print(f"Request failed: {e}")

        attempt += 1
        print("Waiting 5s seconds before next health checkattempt...")
        time.sleep(5)

    if not healthy:
        print("Workflow app is not healthy!")
        sys.exit(1)

    workflow_url = "http://localhost:8004/start-workflow"
    task_payload = {"task": "Simulate a conversation about the 19th century book 'The Count of Monte Cristo'"}

    for attempt in range(1, 11):
        try:
            print(f"Attempt {attempt}...")
            response = requests.post(workflow_url, json=task_payload, timeout=5)

            if response.status_code == 202:
                print("Workflow started successfully!")
                app.run(port=app_port) 
                exit(0)
            else:
                print(f"Received status code {response.status_code}: {response.text}")

        except requests.exceptions.RequestException as e:
            print(f"Request failed: {e}")

        attempt += 1
        print("Waiting 1s seconds before next attempt...")
        time.sleep(1)

    print("Maximum attempts (10) reached without success.")

    print("Failed to get successful response")
    sys.exit(1)

     