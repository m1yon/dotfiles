import {
  ListClustersCommand,
  DescribeClustersCommand,
  ListServicesCommand,
  DescribeServicesCommand,
  ListTasksCommand,
  DescribeTasksCommand,
  type NetworkConfiguration as EcsNetworkConfiguration,
} from "@aws-sdk/client-ecs";
import {
  ListRulesCommand,
  ListTargetsByRuleCommand,
  type Rule,
  type Target,
  type NetworkConfiguration as EventBridgeNetworkConfiguration,
} from "@aws-sdk/client-eventbridge";
import {
  ListSchedulesCommand,
  GetScheduleCommand,
  type ScheduleSummary,
} from "@aws-sdk/client-scheduler";
import type { AWSClients, ClusterInfo, ScheduledTask } from "./types";
import { handleAWSError, ClusterNotFoundError } from "./errors";

export async function discoverClusters(
  clients: AWSClients,
  profile: string
): Promise<ClusterInfo[]> {
  try {
    // List all cluster ARNs with pagination
    const clusterArns: string[] = [];
    let nextToken: string | undefined;

    do {
      const listResponse = await clients.ecs.send(
        new ListClustersCommand({ nextToken })
      );
      if (listResponse.clusterArns) {
        clusterArns.push(...listResponse.clusterArns);
      }
      nextToken = listResponse.nextToken;
    } while (nextToken);

    if (clusterArns.length === 0) {
      return [];
    }

    // Describe clusters in batches of 100 (API limit)
    const clusters: ClusterInfo[] = [];
    for (let i = 0; i < clusterArns.length; i += 100) {
      const batch = clusterArns.slice(i, i + 100);
      const describeResponse = await clients.ecs.send(
        new DescribeClustersCommand({ clusters: batch })
      );

      if (describeResponse.clusters) {
        for (const cluster of describeResponse.clusters) {
          clusters.push({
            clusterArn: cluster.clusterArn!,
            clusterName: cluster.clusterName!,
            status: cluster.status,
            runningTasksCount: cluster.runningTasksCount ?? 0,
            pendingTasksCount: cluster.pendingTasksCount ?? 0,
            activeServicesCount: cluster.activeServicesCount ?? 0,
          });
        }
      }
    }

    return clusters;
  } catch (error) {
    handleAWSError(error, profile);
  }
}

export async function discoverScheduledTasks(
  clients: AWSClients,
  profile: string,
  clusterArn?: string,
  verbose: boolean = false
): Promise<ScheduledTask[]> {
  const scheduledTasks: ScheduledTask[] = [];

  // Discover from EventBridge Rules
  try {
    if (verbose) {
      console.error("Checking EventBridge Rules...");
    }
    const rulesResults = await discoverFromEventBridgeRules(clients, profile, clusterArn);
    scheduledTasks.push(...rulesResults);
    if (verbose) {
      console.error(`Found ${rulesResults.length} scheduled tasks from EventBridge Rules`);
    }
  } catch (error) {
    if (verbose) {
      console.error(`Error discovering from EventBridge Rules: ${error}`);
    }
  }

  // Discover from EventBridge Scheduler
  try {
    if (verbose) {
      console.error("Checking EventBridge Scheduler...");
    }
    const schedulerResults = await discoverFromEventBridgeScheduler(clients, profile, clusterArn, verbose);
    scheduledTasks.push(...schedulerResults);
    if (verbose) {
      console.error(`Found ${schedulerResults.length} scheduled tasks from EventBridge Scheduler`);
    }
  } catch (error) {
    if (verbose) {
      console.error(`Error discovering from EventBridge Scheduler: ${error}`);
    }
  }

  return scheduledTasks;
}

async function discoverFromEventBridgeRules(
  clients: AWSClients,
  profile: string,
  clusterArn?: string
): Promise<ScheduledTask[]> {
  // List all EventBridge rules with pagination
  const rules: Rule[] = [];
  let nextToken: string | undefined;

  do {
    const listResponse = await clients.eventbridge.send(
      new ListRulesCommand({ NextToken: nextToken })
    );
    if (listResponse.Rules) {
      rules.push(...listResponse.Rules);
    }
    nextToken = listResponse.NextToken;
  } while (nextToken);

  // Get targets for each rule and filter for ECS targets
  const scheduledTasks: ScheduledTask[] = [];

  for (const rule of rules) {
    if (!rule.Name) continue;

    const targetsResponse = await clients.eventbridge.send(
      new ListTargetsByRuleCommand({ Rule: rule.Name })
    );

    if (!targetsResponse.Targets) continue;

    for (const target of targetsResponse.Targets) {
      const scheduledTask = parseEcsTarget(rule, target);
      if (scheduledTask) {
        // Filter by cluster if specified
        if (clusterArn && scheduledTask.clusterArn !== clusterArn) {
          continue;
        }
        scheduledTasks.push(scheduledTask);
      }
    }
  }

  return scheduledTasks;
}

async function discoverFromEventBridgeScheduler(
  clients: AWSClients,
  profile: string,
  clusterArn?: string,
  verbose: boolean = false
): Promise<ScheduledTask[]> {
  // List all schedules with pagination
  const schedules: ScheduleSummary[] = [];
  let nextToken: string | undefined;

  do {
    const listResponse = await clients.scheduler.send(
      new ListSchedulesCommand({ NextToken: nextToken })
    );
    if (listResponse.Schedules) {
      schedules.push(...listResponse.Schedules);
    }
    nextToken = listResponse.NextToken;
  } while (nextToken);

  if (verbose) {
    console.error(`Found ${schedules.length} schedules in EventBridge Scheduler`);
  }

  // Get full details for each schedule and filter for ECS targets
  const scheduledTasks: ScheduledTask[] = [];

  for (const schedule of schedules) {
    if (!schedule.Name) continue;

    try {
      const getResponse = await clients.scheduler.send(
        new GetScheduleCommand({ Name: schedule.Name, GroupName: schedule.GroupName })
      );

      const target = getResponse.Target;
      if (!target?.EcsParameters) continue;

      // Check if target ARN is an ECS cluster
      if (!target.Arn?.includes(":cluster/")) continue;

      const ecsParams = target.EcsParameters;
      
      // Filter by cluster if specified
      if (clusterArn && target.Arn !== clusterArn) continue;

      // Convert Scheduler's network config to ECS format
      let networkConfiguration: EcsNetworkConfiguration | undefined;
      if (ecsParams.NetworkConfiguration?.AwsvpcConfiguration) {
        const awsvpc = ecsParams.NetworkConfiguration.AwsvpcConfiguration;
        networkConfiguration = {
          awsvpcConfiguration: {
            subnets: awsvpc.Subnets,
            securityGroups: awsvpc.SecurityGroups,
            assignPublicIp: awsvpc.AssignPublicIp,
          },
        };
      }

      scheduledTasks.push({
        ruleName: schedule.Name,
        ruleArn: getResponse.Arn || `scheduler:${schedule.Name}`,
        scheduleExpression: getResponse.ScheduleExpression,
        clusterArn: target.Arn,
        taskDefinitionArn: ecsParams.TaskDefinitionArn!,
        networkConfiguration,
        launchType: ecsParams.LaunchType as "EC2" | "FARGATE" | "EXTERNAL" | undefined,
        platformVersion: ecsParams.PlatformVersion,
        enabled: getResponse.State === "ENABLED",
        taskCount: ecsParams.TaskCount ?? 1,
        source: "eventbridge-scheduler",
      });
    } catch (error) {
      if (verbose) {
        console.error(`Error getting schedule ${schedule.Name}: ${error}`);
      }
    }
  }

  return scheduledTasks;
}

/**
 * Convert EventBridge NetworkConfiguration to ECS NetworkConfiguration
 * The API returns mixed case - awsvpcConfiguration (lowercase) with Subnets (uppercase)
 * ECS expects: { awsvpcConfiguration: { subnets, securityGroups, assignPublicIp } }
 */
function convertNetworkConfiguration(
  ebConfig: EventBridgeNetworkConfiguration | undefined
): EcsNetworkConfiguration | undefined {
  if (!ebConfig) return undefined;

  // Handle both possible casings - SDK types say AwsvpcConfiguration but API returns awsvpcConfiguration
  const awsvpc = (ebConfig as any).awsvpcConfiguration || ebConfig.AwsvpcConfiguration;
  if (!awsvpc) return undefined;

  // Handle both possible casings for the inner properties too
  const subnets = awsvpc.Subnets || awsvpc.subnets;
  const securityGroups = awsvpc.SecurityGroups || awsvpc.securityGroups;
  const assignPublicIp = awsvpc.AssignPublicIp || awsvpc.assignPublicIp;

  if (!subnets?.length) return undefined;

  return {
    awsvpcConfiguration: {
      subnets,
      securityGroups,
      assignPublicIp,
    },
  };
}

function parseEcsTarget(rule: Rule, target: Target): ScheduledTask | null {
  if (!target.EcsParameters) return null;

  // The target.Arn for ECS is the cluster ARN
  const clusterArn = target.Arn;
  if (!clusterArn) return null;

  return {
    ruleName: rule.Name!,
    ruleArn: rule.Arn!,
    scheduleExpression: rule.ScheduleExpression,
    clusterArn,
    taskDefinitionArn: target.EcsParameters.TaskDefinitionArn!,
    networkConfiguration: convertNetworkConfiguration(
      target.EcsParameters.NetworkConfiguration
    ),
    launchType: target.EcsParameters.LaunchType as
      | "EC2"
      | "FARGATE"
      | "EXTERNAL"
      | undefined,
    platformVersion: target.EcsParameters.PlatformVersion,
    enabled: rule.State === "ENABLED",
    taskCount: target.EcsParameters.TaskCount ?? 1,
    source: "eventbridge-rules",
  };
}

export async function findClusterByName(
  clients: AWSClients,
  profile: string,
  clusterName: string
): Promise<ClusterInfo> {
  const clusters = await discoverClusters(clients, profile);

  const cluster = clusters.find(
    (c) =>
      c.clusterName === clusterName ||
      c.clusterArn === clusterName ||
      c.clusterArn.endsWith(`/${clusterName}`)
  );

  if (!cluster) {
    throw new ClusterNotFoundError(clusterName);
  }

  return cluster;
}

export async function findScheduledTaskByRule(
  clients: AWSClients,
  profile: string,
  ruleName: string,
  clusterArn?: string,
  verbose: boolean = false
): Promise<ScheduledTask | undefined> {
  const tasks = await discoverScheduledTasks(clients, profile, clusterArn, verbose);
  return tasks.find((t) => t.ruleName === ruleName);
}

/**
 * Extract task definition family from ARN
 * e.g., "arn:aws:ecs:us-east-1:123456789:task-definition/my-task:10" -> "my-task"
 */
function getTaskDefinitionFamily(taskDefinitionArn: string): string {
  const match = taskDefinitionArn.match(/task-definition\/([^:]+)/);
  return match ? match[1] : taskDefinitionArn;
}

/**
 * Find network configuration from recently run tasks in the cluster
 * that use the same task definition family
 */
export async function findNetworkConfigurationFromTasks(
  clients: AWSClients,
  profile: string,
  clusterArn: string,
  taskDefinitionArn: string,
  verbose: boolean = false
): Promise<EcsNetworkConfiguration | undefined> {
  try {
    const targetFamily = getTaskDefinitionFamily(taskDefinitionArn);
    if (verbose) {
      console.error(`Looking for network config from tasks using family: ${targetFamily}`);
    }

    // Check both running and stopped tasks
    for (const desiredStatus of ["RUNNING", "STOPPED"] as const) {
      const listResponse = await clients.ecs.send(
        new ListTasksCommand({
          cluster: clusterArn,
          desiredStatus,
          maxResults: 100,
        })
      );

      if (!listResponse.taskArns?.length) {
        if (verbose) {
          console.error(`No ${desiredStatus.toLowerCase()} tasks found`);
        }
        continue;
      }

      if (verbose) {
        console.error(`Found ${listResponse.taskArns.length} ${desiredStatus.toLowerCase()} tasks`);
      }

      // Describe tasks in batches of 100
      const describeResponse = await clients.ecs.send(
        new DescribeTasksCommand({
          cluster: clusterArn,
          tasks: listResponse.taskArns,
        })
      );

      if (!describeResponse.tasks) continue;

      // First, try to find a task with the same task definition family
      for (const task of describeResponse.tasks) {
        if (!task.taskDefinitionArn) continue;
        
        const taskFamily = getTaskDefinitionFamily(task.taskDefinitionArn);
        
        if (taskFamily === targetFamily && task.attachments) {
          const networkConfig = extractNetworkConfigFromTask(task.attachments);
          if (networkConfig) {
            if (verbose) {
              console.error(`Found matching network config from task: ${task.taskArn}`);
            }
            return networkConfig;
          }
        }
      }

      // Fallback: any task with network config
      for (const task of describeResponse.tasks) {
        if (task.attachments) {
          const networkConfig = extractNetworkConfigFromTask(task.attachments);
          if (networkConfig) {
            if (verbose) {
              console.error(`Using network config from task: ${task.taskArn}`);
            }
            return networkConfig;
          }
        }
      }
    }

    return undefined;
  } catch (error) {
    if (verbose) {
      console.error(`Error finding network configuration from tasks: ${error}`);
    }
    return undefined;
  }
}

/**
 * Extract network configuration from task attachments
 * ECS tasks store network info in attachments with type "ElasticNetworkInterface"
 */
function extractNetworkConfigFromTask(
  attachments: { type?: string; details?: { name?: string; value?: string }[] }[]
): EcsNetworkConfiguration | undefined {
  const eniAttachment = attachments.find((a) => a.type === "ElasticNetworkInterface");
  if (!eniAttachment?.details) return undefined;

  const details = eniAttachment.details;
  const getDetail = (name: string) => details.find((d) => d.name === name)?.value;

  const subnetId = getDetail("subnetId");
  if (!subnetId) return undefined;

  // Security groups might be stored as a single value or we need to look at the ENI
  // For now, we'll get what we can from the attachment
  const securityGroups: string[] = [];
  
  // Try to find security group from attachment details
  // Note: This might not always be available in attachments
  
  return {
    awsvpcConfiguration: {
      subnets: [subnetId],
      securityGroups: securityGroups.length > 0 ? securityGroups : undefined,
      assignPublicIp: "DISABLED", // Safe default for private subnets
    },
  };
}

/**
 * Find network configuration from an existing service in the cluster
 * that uses the same task definition family
 */
export async function findNetworkConfigurationFromService(
  clients: AWSClients,
  profile: string,
  clusterArn: string,
  taskDefinitionArn: string,
  verbose: boolean = false
): Promise<EcsNetworkConfiguration | undefined> {
  try {
    const targetFamily = getTaskDefinitionFamily(taskDefinitionArn);
    if (verbose) {
      console.error(`Looking for network config from services using task family: ${targetFamily}`);
    }

    // List all services in the cluster with pagination
    const serviceArns: string[] = [];
    let nextToken: string | undefined;

    do {
      const listResponse = await clients.ecs.send(
        new ListServicesCommand({ cluster: clusterArn, nextToken })
      );
      if (listResponse.serviceArns) {
        serviceArns.push(...listResponse.serviceArns);
      }
      nextToken = listResponse.nextToken;
    } while (nextToken);

    if (serviceArns.length === 0) {
      if (verbose) {
        console.error("No services found in cluster");
      }
      return undefined;
    }

    // Describe services in batches of 10 (API limit)
    for (let i = 0; i < serviceArns.length; i += 10) {
      const batch = serviceArns.slice(i, i + 10);
      const describeResponse = await clients.ecs.send(
        new DescribeServicesCommand({ cluster: clusterArn, services: batch })
      );

      if (describeResponse.services) {
        for (const service of describeResponse.services) {
          if (!service.taskDefinition) continue;
          
          const serviceFamily = getTaskDefinitionFamily(service.taskDefinition);
          if (verbose) {
            console.error(`Checking service ${service.serviceName}: family=${serviceFamily}`);
          }

          if (serviceFamily === targetFamily && service.networkConfiguration) {
            if (verbose) {
              console.error(`Found matching network config from service: ${service.serviceName}`);
            }
            return service.networkConfiguration;
          }
        }
      }
    }

    // If no exact match, try to find any service with a network config as fallback
    if (verbose) {
      console.error("No exact match found, looking for any service with network config...");
    }

    for (let i = 0; i < serviceArns.length; i += 10) {
      const batch = serviceArns.slice(i, i + 10);
      const describeResponse = await clients.ecs.send(
        new DescribeServicesCommand({ cluster: clusterArn, services: batch })
      );

      if (describeResponse.services) {
        for (const service of describeResponse.services) {
          if (service.networkConfiguration?.awsvpcConfiguration?.subnets?.length) {
            if (verbose) {
              console.error(`Using network config from service: ${service.serviceName}`);
            }
            return service.networkConfiguration;
          }
        }
      }
    }

    return undefined;
  } catch (error) {
    if (verbose) {
      console.error(`Error finding network configuration: ${error}`);
    }
    return undefined;
  }
}
