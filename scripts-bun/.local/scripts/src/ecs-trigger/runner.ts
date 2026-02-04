import {
  RunTaskCommand,
  DescribeTasksCommand,
  type Task,
  type NetworkConfiguration,
} from "@aws-sdk/client-ecs";
import type {
  AWSClients,
  ScheduledTask,
  TaskExecutionResult,
  ContainerInfo,
} from "./types";
import { handleAWSError, TaskStartError } from "./errors";
import { findNetworkConfigurationFromService, findNetworkConfigurationFromTasks } from "./discovery";

const POLL_INTERVAL_MS = 2000;
const MAX_POLL_ATTEMPTS = 30; // 60 seconds max wait

export async function runScheduledTask(
  clients: AWSClients,
  profile: string,
  task: ScheduledTask,
  verbose: boolean = false
): Promise<TaskExecutionResult> {
  try {
    if (verbose) {
      console.error(`Starting task with definition: ${task.taskDefinitionArn}`);
      console.error(`Cluster: ${task.clusterArn}`);
      console.error(`Launch type: ${task.launchType || "default"}`);
    }

    // Get network configuration - use task's config or fetch from a matching service/task
    let networkConfiguration: NetworkConfiguration | undefined = task.networkConfiguration;
    
    if (!networkConfiguration && task.launchType === "FARGATE") {
      if (verbose) {
        console.error("No network configuration in scheduled task, searching for one...");
      }
      
      // Try 1: Look for a service with the same task definition
      networkConfiguration = await findNetworkConfigurationFromService(
        clients,
        profile,
        task.clusterArn,
        task.taskDefinitionArn,
        verbose
      );
      
      // Try 2: Look for recently run tasks in the cluster
      if (!networkConfiguration) {
        if (verbose) {
          console.error("No services found, checking recent tasks...");
        }
        networkConfiguration = await findNetworkConfigurationFromTasks(
          clients,
          profile,
          task.clusterArn,
          task.taskDefinitionArn,
          verbose
        );
      }
      
      if (!networkConfiguration) {
        throw new TaskStartError(
          "No network configuration found. Fargate tasks require network configuration (subnets/security groups). " +
          "Could not find configuration from services or recent tasks in the cluster."
        );
      }
    }

    if (verbose && networkConfiguration?.awsvpcConfiguration) {
      const cfg = networkConfiguration.awsvpcConfiguration;
      console.error(`Network: subnets=${cfg.subnets?.join(",")}, securityGroups=${cfg.securityGroups?.join(",")}, publicIp=${cfg.assignPublicIp}`);
    }

    const runTaskCommand = new RunTaskCommand({
      cluster: task.clusterArn,
      taskDefinition: task.taskDefinitionArn,
      launchType: task.launchType,
      networkConfiguration,
      platformVersion: task.platformVersion,
      count: task.taskCount,
      startedBy: "ecs-trigger-manual",
    });

    const response = await clients.ecs.send(runTaskCommand);

    // Check for failures
    if (response.failures && response.failures.length > 0) {
      throw new TaskStartError(
        "Task failed to start",
        response.failures.map((f) => ({ arn: f.arn, reason: f.reason }))
      );
    }

    if (!response.tasks || response.tasks.length === 0) {
      throw new TaskStartError("No tasks returned from RunTask command");
    }

    const startedTask = response.tasks[0];
    if (!startedTask.taskArn) {
      throw new TaskStartError("Task started but no ARN returned");
    }

    if (verbose) {
      console.error(`Task started: ${startedTask.taskArn}`);
      console.error(`Waiting for task to reach RUNNING state...`);
    }

    // Wait for task to start running
    const finalTask = await waitForTaskStart(
      clients,
      profile,
      task.clusterArn,
      startedTask.taskArn,
      verbose
    );

    return formatTaskResult(finalTask);
  } catch (error) {
    if (error instanceof TaskStartError) {
      throw error;
    }
    handleAWSError(error, profile);
  }
}

async function waitForTaskStart(
  clients: AWSClients,
  profile: string,
  clusterArn: string,
  taskArn: string,
  verbose: boolean
): Promise<Task> {
  let attempts = 0;

  while (attempts < MAX_POLL_ATTEMPTS) {
    try {
      const response = await clients.ecs.send(
        new DescribeTasksCommand({
          cluster: clusterArn,
          tasks: [taskArn],
        })
      );

      if (!response.tasks || response.tasks.length === 0) {
        throw new TaskStartError("Task not found during polling");
      }

      const task = response.tasks[0];
      const status = task.lastStatus;

      if (verbose) {
        console.error(`Task status: ${status}`);
      }

      // Task is running or has already completed/stopped
      if (
        status === "RUNNING" ||
        status === "STOPPED" ||
        status === "DEPROVISIONING"
      ) {
        return task;
      }

      // Task failed
      if (task.stopCode || task.stoppedReason) {
        throw new TaskStartError(
          `Task stopped: ${task.stoppedReason || task.stopCode || "unknown reason"}`
        );
      }

      attempts++;
      await sleep(POLL_INTERVAL_MS);
    } catch (error) {
      if (error instanceof TaskStartError) {
        throw error;
      }
      handleAWSError(error, profile);
    }
  }

  // Timeout - return last known state
  const response = await clients.ecs.send(
    new DescribeTasksCommand({
      cluster: clusterArn,
      tasks: [taskArn],
    })
  );

  if (response.tasks && response.tasks.length > 0) {
    return response.tasks[0];
  }

  throw new TaskStartError("Task polling timed out");
}

function formatTaskResult(task: Task): TaskExecutionResult {
  const containers: ContainerInfo[] = (task.containers || []).map((c) => ({
    name: c.name,
    containerArn: c.containerArn,
    lastStatus: c.lastStatus,
    exitCode: c.exitCode,
    reason: c.reason,
    healthStatus: c.healthStatus,
  }));

  return {
    taskArn: task.taskArn!,
    clusterArn: task.clusterArn!,
    taskDefinitionArn: task.taskDefinitionArn,
    lastStatus: task.lastStatus,
    desiredStatus: task.desiredStatus,
    startedBy: task.startedBy,
    launchType: task.launchType,
    platformVersion: task.platformVersion,
    containers,
    createdAt: task.createdAt,
    startedAt: task.startedAt,
  };
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
