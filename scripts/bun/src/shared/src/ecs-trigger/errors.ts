export class EcsTriggerError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "EcsTriggerError";
  }
}

export class CredentialsError extends EcsTriggerError {
  constructor(message: string, public readonly profile: string) {
    super(`Credentials error for profile "${profile}": ${message}`);
    this.name = "CredentialsError";
  }
}

export class ClusterNotFoundError extends EcsTriggerError {
  constructor(clusterIdentifier: string) {
    super(`Cluster not found: ${clusterIdentifier}`);
    this.name = "ClusterNotFoundError";
  }
}

export class RuleNotFoundError extends EcsTriggerError {
  constructor(ruleName: string) {
    super(`EventBridge rule not found: ${ruleName}`);
    this.name = "RuleNotFoundError";
  }
}

export class TaskStartError extends EcsTriggerError {
  constructor(
    message: string,
    public readonly failures?: Array<{ arn?: string; reason?: string }>
  ) {
    const failureDetails = failures
      ?.map((f) => `${f.arn || "unknown"}: ${f.reason || "unknown reason"}`)
      .join("; ");
    super(`Failed to start task: ${message}${failureDetails ? ` (${failureDetails})` : ""}`);
    this.name = "TaskStartError";
  }
}

export class NoEcsTargetError extends EcsTriggerError {
  constructor(ruleName: string) {
    super(`EventBridge rule "${ruleName}" has no ECS target`);
    this.name = "NoEcsTargetError";
  }
}

export function handleAWSError(error: unknown, profile: string): never {
  if (error instanceof Error) {
    const name = error.name;

    if (name === "ExpiredTokenException" || name === "ExpiredToken") {
      throw new CredentialsError("Token has expired. Please refresh your credentials.", profile);
    }

    if (name === "AccessDeniedException" || name === "AccessDenied") {
      throw new CredentialsError(
        "Access denied. Check your IAM permissions.",
        profile
      );
    }

    if (name === "CredentialsProviderError" || name === "CredentialsError") {
      throw new CredentialsError(
        `Could not load credentials. Ensure profile "${profile}" exists in ~/.aws/credentials or ~/.aws/config`,
        profile
      );
    }

    if (name === "ThrottlingException" || name === "Throttling") {
      throw new EcsTriggerError("AWS API rate limit exceeded. Please try again later.");
    }

    throw new EcsTriggerError(error.message);
  }

  throw new EcsTriggerError(String(error));
}
