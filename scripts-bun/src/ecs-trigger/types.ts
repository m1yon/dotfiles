import type { NetworkConfiguration, LaunchType } from "@aws-sdk/client-ecs";

export interface ScheduledTask {
  ruleName: string;
  ruleArn: string;
  scheduleExpression: string | undefined;
  clusterArn: string;
  taskDefinitionArn: string;
  networkConfiguration: NetworkConfiguration | undefined;
  launchType: LaunchType | undefined;
  platformVersion: string | undefined;
  enabled: boolean;
  taskCount: number;
  source: ScheduledTaskSource;
}

export interface ClusterInfo {
  clusterArn: string;
  clusterName: string;
  status: string | undefined;
  runningTasksCount: number;
  pendingTasksCount: number;
  activeServicesCount: number;
}

export interface ContainerInfo {
  name: string | undefined;
  containerArn: string | undefined;
  lastStatus: string | undefined;
  exitCode: number | undefined;
  reason: string | undefined;
  healthStatus: string | undefined;
}

export interface TaskExecutionResult {
  taskArn: string;
  clusterArn: string;
  taskDefinitionArn: string | undefined;
  lastStatus: string | undefined;
  desiredStatus: string | undefined;
  startedBy: string | undefined;
  launchType: string | undefined;
  platformVersion: string | undefined;
  containers: ContainerInfo[];
  createdAt: Date | undefined;
  startedAt: Date | undefined;
  consoleUrl: string;
}

export interface CLIOptions {
  profile: string;
  region?: string;
  cluster?: string;
  rule?: string;
  list: boolean;
  verbose: boolean;
}

export interface AWSClients {
  ecs: import("@aws-sdk/client-ecs").ECSClient;
  eventbridge: import("@aws-sdk/client-eventbridge").EventBridgeClient;
  scheduler: import("@aws-sdk/client-scheduler").SchedulerClient;
}

export type ScheduledTaskSource = "eventbridge-rules" | "eventbridge-scheduler";
