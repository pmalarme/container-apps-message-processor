package com.fabrikam;

import java.util.concurrent.CountDownLatch;

import javax.enterprise.context.ApplicationScoped;
import javax.enterprise.event.Observes;

import org.jboss.logging.Logger;

import com.azure.core.amqp.AmqpRetryOptions;
import com.azure.messaging.servicebus.ServiceBusClientBuilder;
import com.azure.messaging.servicebus.ServiceBusErrorContext;
import com.azure.messaging.servicebus.ServiceBusProcessorClient;
import com.azure.messaging.servicebus.ServiceBusReceivedMessageContext;

import io.quarkus.runtime.ShutdownEvent;
import io.quarkus.runtime.StartupEvent;

@ApplicationScoped
public class MessageProcessor {
  private static final Logger LOGGER = Logger.getLogger("ListenerBean");
  // Service Bus
  private final static String SERVICE_BUS_CONNECTION_STRING = System.getenv("SERVICE_BUS_CONNECTION_STRING");
  private final static String SERVICE_BUS_QUEUE_NAME = System.getenv("SERVICE_BUS_QUEUE_NAME");

  private ServiceBusProcessorClient processorClient = null;

  void onStart(@Observes StartupEvent ev) {               
      LOGGER.info("The application is starting...");
      this.startServiceBusclient();
  }

  void onStop(@Observes ShutdownEvent ev) {               
      LOGGER.info("The application is stopping...");
      if (this.processorClient != null) {
        this.processorClient.close();
      }
  }

  private void startServiceBusclient() {
    LOGGER.info("Starting client");
    LOGGER.info("Connection string: " + SERVICE_BUS_CONNECTION_STRING);
    this.processorClient = new ServiceBusClientBuilder()
      .connectionString(SERVICE_BUS_CONNECTION_STRING)
      .retryOptions(new AmqpRetryOptions().setMaxRetries(10))
      .processor()
      .queueName(SERVICE_BUS_QUEUE_NAME)
      .processError(context -> processError(context))
      .processMessage(context -> processMessage(context))
      .buildProcessorClient();
    this.processorClient.start();
  }

  private static void processMessage(final ServiceBusReceivedMessageContext context) {
    LOGGER.info("Received message: " + context.getMessage().getBody().toString());
    context.complete();
  }

  private static void processError(final ServiceBusErrorContext context) {
    LOGGER.error("Error when receiving messages: " + context.getException());
  }
}
