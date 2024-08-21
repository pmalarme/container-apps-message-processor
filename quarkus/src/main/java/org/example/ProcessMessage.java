package org.example;

import java.util.concurrent.CountDownLatch;

import javax.enterprise.context.ApplicationScoped;
import javax.enterprise.event.Observes;

import org.jboss.logging.Logger;

import com.azure.core.amqp.AmqpRetryOptions;
import com.azure.messaging.servicebus.ServiceBusClientBuilder;
import com.azure.messaging.servicebus.ServiceBusErrorContext;
import com.azure.messaging.servicebus.ServiceBusProcessorClient;

import io.quarkus.runtime.ShutdownEvent;
import io.quarkus.runtime.StartupEvent;

@ApplicationScoped
public class ProcessMessage {
  private static final Logger LOGGER = Logger.getLogger("ListenerBean");
  // Service Bus
  private static final String SERVICE_BUS_CONNECTION_STRING = System.getenv("QUARKUS_SERVICE_BUS_CONNECTION_STRING");
  private final static String TOPIC_NAME = "sbt-incoming-messages";
  private final static String SUBSCRIPTION_NAME = "sbts-all-incoming-messages-quarkus";

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
    final CountDownLatch countdownLatch = new CountDownLatch(1);
    LOGGER.info("Starting client");
    LOGGER.info("Connection string: " + SERVICE_BUS_CONNECTION_STRING);
    final ServiceBusProcessorClient processorClient = new ServiceBusClientBuilder()
      .connectionString(SERVICE_BUS_CONNECTION_STRING)
      .retryOptions(new AmqpRetryOptions().setMaxRetries(10))
      .processor()
      .topicName(TOPIC_NAME)
      .subscriptionName(SUBSCRIPTION_NAME)
      .processError(context -> processError(context, countdownLatch))
      .processMessage(context -> {
        LOGGER.info("Received message: " + context.getMessage().getMessageId());
        context.complete();
      })
      .buildProcessorClient();
    this.processorClient = processorClient;

    processorClient.start();
  }

  private static void processError(final ServiceBusErrorContext context, final CountDownLatch countdownLatch) {
    LOGGER.error("Error when receiving messages: " + context.getException());
    countdownLatch.countDown();
  }
}
