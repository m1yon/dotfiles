import { select } from "@inquirer/prompts";
import type { ClusterInfo, ScheduledTask } from "./types";

export async function selectCluster(clusters: ClusterInfo[]): Promise<ClusterInfo> {
  if (clusters.length === 0) {
    throw new Error("No ECS clusters found");
  }

  if (clusters.length === 1) {
    return clusters[0];
  }

  const choice = await select({
    message: "Select an ECS cluster:",
    choices: clusters.map((cluster) => ({
      name: formatClusterChoice(cluster),
      value: cluster,
    })),
  });

  return choice;
}

function formatClusterChoice(cluster: ClusterInfo): string {
  const parts = [cluster.clusterName];

  const statusInfo: string[] = [];
  if (cluster.runningTasksCount > 0) {
    statusInfo.push(`${cluster.runningTasksCount} running`);
  }
  if (cluster.pendingTasksCount > 0) {
    statusInfo.push(`${cluster.pendingTasksCount} pending`);
  }
  if (cluster.activeServicesCount > 0) {
    statusInfo.push(`${cluster.activeServicesCount} services`);
  }

  if (statusInfo.length > 0) {
    parts.push(`(${statusInfo.join(", ")})`);
  }

  if (cluster.status && cluster.status !== "ACTIVE") {
    parts.push(`[${cluster.status}]`);
  }

  return parts.join(" ");
}

export async function selectScheduledTask(
  tasks: ScheduledTask[]
): Promise<ScheduledTask> {
  if (tasks.length === 0) {
    throw new Error("No scheduled tasks found");
  }

  if (tasks.length === 1) {
    return tasks[0];
  }

  const choice = await select({
    message: "Select a scheduled task:",
    choices: tasks.map((task) => ({
      name: formatTaskChoice(task),
      value: task,
    })),
  });

  return choice;
}

function formatTaskChoice(task: ScheduledTask): string {
  const parts = [task.ruleName];

  // Add schedule expression
  if (task.scheduleExpression) {
    parts.push(`(${task.scheduleExpression})`);
  }

  // Add enabled/disabled status
  parts.push(task.enabled ? "[ENABLED]" : "[DISABLED]");

  // Add task definition (short form)
  const taskDefShort = task.taskDefinitionArn.split("/").pop() || task.taskDefinitionArn;
  parts.push(`-> ${taskDefShort}`);

  return parts.join(" ");
}

export async function confirmExecution(task: ScheduledTask): Promise<boolean> {
  const choice = await select({
    message: `Execute task "${task.ruleName}"?`,
    choices: [
      { name: "Yes, run the task", value: true },
      { name: "No, cancel", value: false },
    ],
  });

  return choice;
}
