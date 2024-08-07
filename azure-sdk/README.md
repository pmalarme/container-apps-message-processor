# Service Bus Queue Processor

## Setup

Set environment variables:
```sh
export SERVICE_BUS_CONNECTION_STRING=your_connection_string_here
export SERVICE_BUS_QUEUE_NAME=your_queue_name_here
```

## Build and Run

```sh
mvn clean
mvn compile
mvn exec:java -Dexec.mainClass="ServiceBusQueueProcessor"
```

Press Ctrl+C to stop the processor.