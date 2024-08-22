package com.fabrikam.functions;

import com.microsoft.azure.functions.ExecutionContext;
import com.microsoft.azure.functions.annotation.FunctionName;
import com.microsoft.azure.functions.annotation.ServiceBusQueueTrigger;

/**
* Azure Functions rto process messages from a Service Bus queue.
*/
public class Function {
  /**
  * This function will be invoked when a new message is received
  * at the specified Service Bus queue and will log the message
  * content to the console.
  * 
  * @param message The message content.
  * @param context The execution context.
  **/
  @FunctionName("sbprocessor")
  public void processMessage(
  @ServiceBusQueueTrigger(
  name = "message",
  queueName = "sbq-fabrikam-functions",
  connection = "SERVICE_BUS_CONNECTION_STRING")
  String message,
  final ExecutionContext context) {
    context.getLogger().info("Received message: " + message);
  }
}
