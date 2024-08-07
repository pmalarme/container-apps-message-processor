package org.example;

import com.azure.messaging.servicebus.*;

public class ServiceBusQueueProcessor {
    private static final String CONNECTION_STRING = System.getenv("SERVICE_BUS_CONNECTION_STRING");
    private static final String QUEUE_NAME = System.getenv("SERVICE_BUS_QUEUE_NAME");
    private static final int BATCH_SIZE = 10;

    public static void main(final String[] args) throws InterruptedException {
        final ServiceBusReceiverClient receiver = new ServiceBusClientBuilder()
            .connectionString(CONNECTION_STRING)
            .receiver()
            .queueName(QUEUE_NAME)
            .buildClient();

        receiver.receiveMessages(BATCH_SIZE).forEach(message -> {
            System.out.println("Processing message: " + message.getBody().toString());
            receiver.complete(message);
        });
    }
}