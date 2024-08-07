import com.azure.messaging.servicebus.*;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

public class ServiceBusQueueProcessor {
    private static final String CONNECTION_STRING = System.getenv("SERVICE_BUS_CONNECTION_STRING");
    private static final String QUEUE_NAME = System.getenv("SERVICE_BUS_QUEUE_NAME");

    public static void main(String[] args) throws InterruptedException {
        CountDownLatch countdownLatch = new CountDownLatch(1);

        // Create a processor client that will receive messages from the queue
        ServiceBusProcessorClient processorClient = new ServiceBusClientBuilder()
                .connectionString(CONNECTION_STRING)
                .processor()
                .queueName(QUEUE_NAME)
                .processMessage(ServiceBusQueueProcessor::processMessage)
                .processError(context -> processError(context, countdownLatch))
                .buildProcessorClient();

        System.out.println("Starting the processor");
        processorClient.start();

        // The CountDownLatch is used to keep the main thread alive
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            System.out.println("Shutting down the processor");
            processorClient.close();
            countdownLatch.countDown();
        }));

        System.out.println("Processor is running. Press Ctrl+C to exit.");
        countdownLatch.await();
    }

    private static void processMessage(ServiceBusReceivedMessageContext context) {
        ServiceBusReceivedMessage message = context.getMessage();
        String messageBody = message.getBody().toString();
        System.out.println("Received message: " + messageBody);
        
        // Add your custom processing logic here
        String response = "Processed: " + messageBody.toUpperCase();
        System.out.println(response);
        
        // You could perform actions based on the message content here
        if (messageBody.contains("hello")) {
            System.out.println("Greeting message received!");
        } else if (messageBody.contains("urgent")) {
            System.out.println("Urgent message received! Prioritizing...");
        }
    }

    private static void processError(ServiceBusErrorContext context, CountDownLatch countdownLatch) {
        System.out.printf("Error when receiving messages from namespace: '%s'. Entity: '%s'%n",
                context.getFullyQualifiedNamespace(), context.getEntityPath());

        if (!(context.getException() instanceof ServiceBusException)) {
            System.out.printf("Non-ServiceBusException occurred: %s%n", context.getException());
            return;
        }

        ServiceBusException exception = (ServiceBusException) context.getException();
        ServiceBusFailureReason reason = exception.getReason();

        if (reason == ServiceBusFailureReason.MESSAGING_ENTITY_DISABLED
                || reason == ServiceBusFailureReason.MESSAGING_ENTITY_NOT_FOUND
                || reason == ServiceBusFailureReason.UNAUTHORIZED) {
            System.out.printf("An unrecoverable error occurred. Stopping processing with reason %s: %s%n",
                    reason, exception.getMessage());

            countdownLatch.countDown();
        } else if (reason == ServiceBusFailureReason.MESSAGE_LOCK_LOST) {
            System.out.printf("Message lock lost for message: %s%n", context.getException());
        } else if (reason == ServiceBusFailureReason.SERVICE_BUSY) {
            try {
                TimeUnit.SECONDS.sleep(1);
            } catch (InterruptedException e) {
                System.err.println("Unable to sleep for period of time");
            }
        } else {
            System.out.printf("Error source %s, reason %s, message: %s%n", context.getErrorSource(),
                    reason, context.getException());
        }
    }
}