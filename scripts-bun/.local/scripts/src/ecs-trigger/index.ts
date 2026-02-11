#!/usr/bin/env bun
// ---
// description: Discover and trigger AWS ECS scheduled tasks
// ---
import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import type { CLIOptions, ScheduledTask, ClusterInfo } from "./types";
import { createAWSClients } from "./aws";
import {
  discoverClusters,
  discoverScheduledTasks,
  findClusterByName,
  findScheduledTaskByRule,
} from "./discovery";
import {
  selectCluster,
  selectScheduledTask,
  confirmExecution,
} from "./interactive";
import { runScheduledTask } from "./runner";
import { EcsTriggerError } from "./errors";

async function main() {
  const argv = await yargs(hideBin(process.argv))
    .usage("Usage: $0 --profile <profile> [options]")
    .option("profile", {
      alias: "p",
      type: "string",
      description: "AWS CLI profile",
      demandOption: true,
    })
    .option("region", {
      alias: "r",
      type: "string",
      default: "us-east-1",
      description: "AWS region",
    })
    .option("cluster", {
      alias: "c",
      type: "string",
      description: "Skip cluster selection",
    })
    .option("rule", {
      type: "string",
      description: "Skip rule selection",
    })
    .option("list", {
      alias: "l",
      type: "boolean",
      default: false,
      description: "Output JSON, don't execute",
    })
    .option("verbose", {
      alias: "v",
      type: "boolean",
      default: false,
      description: "Debug logging",
    })
    .example("$0 --profile production", "Interactive mode")
    .example(
      "$0 --profile production --cluster my-cluster --rule my-rule",
      "Direct execution"
    )
    .example("$0 --profile production --list", "List scheduled tasks as JSON")
    .help()
    .alias("help", "h")
    .strict()
    .parse();

  const options: CLIOptions = {
    profile: argv.profile,
    region: argv.region,
    cluster: argv.cluster,
    rule: argv.rule,
    list: argv.list,
    verbose: argv.verbose,
  };

  try {
    await run(options);
  } catch (error) {
    if (error instanceof EcsTriggerError) {
      console.error(`Error: ${error.message}`);
      process.exit(1);
    }
    // Re-throw unexpected errors
    throw error;
  }
}

async function run(options: CLIOptions): Promise<void> {
  const { profile, region, cluster, rule, list, verbose } = options;

  if (verbose) {
    console.error(`Using profile: ${profile}`);
    if (region) console.error(`Region override: ${region}`);
  }

  // Initialize AWS clients
  const clients = await createAWSClients({ profile, region });

  if (verbose) {
    console.error("AWS clients initialized successfully");
  }

  // List mode - output JSON and exit
  if (list) {
    await handleListMode(clients, profile, cluster, verbose);
    return;
  }

  // Interactive/Direct mode
  await handleExecuteMode(clients, profile, options);
}

async function handleListMode(
  clients: Awaited<ReturnType<typeof createAWSClients>>,
  profile: string,
  clusterFilter: string | undefined,
  verbose: boolean
): Promise<void> {
  if (verbose) {
    console.error("Discovering clusters and scheduled tasks...");
  }

  let clusterArn: string | undefined;

  if (clusterFilter) {
    const cluster = await findClusterByName(clients, profile, clusterFilter);
    clusterArn = cluster.clusterArn;
  }

  const [clusters, tasks] = await Promise.all([
    discoverClusters(clients, profile),
    discoverScheduledTasks(clients, profile, clusterArn, verbose),
  ]);

  const output = {
    clusters: clusters.map((c) => ({
      name: c.clusterName,
      arn: c.clusterArn,
      status: c.status,
      runningTasks: c.runningTasksCount,
      pendingTasks: c.pendingTasksCount,
      services: c.activeServicesCount,
    })),
    scheduledTasks: tasks.map((t) => ({
      ruleName: t.ruleName,
      ruleArn: t.ruleArn,
      schedule: t.scheduleExpression,
      cluster: t.clusterArn,
      taskDefinition: t.taskDefinitionArn,
      launchType: t.launchType,
      enabled: t.enabled,
      source: t.source,
    })),
  };

  console.log(JSON.stringify(output, null, 2));
}

async function handleExecuteMode(
  clients: Awaited<ReturnType<typeof createAWSClients>>,
  profile: string,
  options: CLIOptions
): Promise<void> {
  const { cluster: clusterName, rule: ruleName, verbose } = options;

  // Resolve cluster
  let selectedCluster: ClusterInfo;

  if (clusterName) {
    if (verbose) console.error(`Looking up cluster: ${clusterName}`);
    selectedCluster = await findClusterByName(clients, profile, clusterName);
  } else {
    if (verbose) console.error("Discovering clusters...");
    const clusters = await discoverClusters(clients, profile);
    selectedCluster = await selectCluster(clusters);
  }

  if (verbose) {
    console.error(`Selected cluster: ${selectedCluster.clusterName}`);
  }

  // Resolve scheduled task
  let selectedTask: ScheduledTask;

  if (ruleName) {
    if (verbose) console.error(`Looking up rule: ${ruleName}`);
    const task = await findScheduledTaskByRule(
      clients,
      profile,
      ruleName,
      selectedCluster.clusterArn,
      verbose
    );
    if (!task) {
      throw new EcsTriggerError(
        `No scheduled task found with rule "${ruleName}" for cluster "${selectedCluster.clusterName}"`
      );
    }
    selectedTask = task;
  } else {
    if (verbose) console.error("Discovering scheduled tasks...");
    const tasks = await discoverScheduledTasks(
      clients,
      profile,
      selectedCluster.clusterArn,
      verbose
    );
    selectedTask = await selectScheduledTask(tasks);
  }

  if (verbose) {
    console.error(`Selected task: ${selectedTask.ruleName}`);
  }

  // Confirm execution (only in interactive mode)
  if (!clusterName || !ruleName) {
    const confirmed = await confirmExecution(selectedTask);
    if (!confirmed) {
      console.error("Cancelled");
      return;
    }
  }

  // Execute the task
  if (verbose) {
    console.error("Starting task...");
  }

  const result = await runScheduledTask(
    clients,
    profile,
    selectedTask,
    verbose
  );

  // Output result
  console.log(JSON.stringify(result, null, 2));

  // Display clickable console link
  console.error(`\nAWS Console: ${result.consoleUrl}`);
}

main().catch((error) => {
  console.error("Unexpected error:", error);
  process.exit(1);
});
