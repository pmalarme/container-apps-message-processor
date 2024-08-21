# Use an official OpenJDK runtime as a parent image
FROM openjdk:17-jdk-slim

# Set the working directory in the container
WORKDIR /app

# Copy the local project files to the container's working directory
COPY . .

# Install Maven
RUN apt-get update && \
    apt-get install -y maven && \
    apt-get clean

# Build the project
RUN mvn clean package -DskipTests

# Specify the command to run the application
CMD ["java", "-jar", "target/azure-batch-example-1.0-SNAPSHOT-shaded.jar"]
