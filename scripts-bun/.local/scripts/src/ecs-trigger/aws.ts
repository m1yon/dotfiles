import { ECSClient } from "@aws-sdk/client-ecs";
import { EventBridgeClient } from "@aws-sdk/client-eventbridge";
import { SchedulerClient } from "@aws-sdk/client-scheduler";
import { fromIni } from "@aws-sdk/credential-provider-ini";
import type { AWSClients } from "./types";
import { CredentialsError } from "./errors";

export interface CreateAWSClientsOptions {
  profile: string;
  region?: string;
}

export async function createAWSClients(
  options: CreateAWSClientsOptions
): Promise<AWSClients> {
  const { profile, region } = options;

  try {
    const credentials = fromIni({ profile });

    const clientConfig = {
      credentials,
      ...(region && { region }),
    };

    const ecs = new ECSClient(clientConfig);
    const eventbridge = new EventBridgeClient(clientConfig);
    const scheduler = new SchedulerClient(clientConfig);

    // Verify credentials work by making a simple call
    // This will throw early if credentials are invalid
    try {
      await ecs.config.credentials();
    } catch (error) {
      if (error instanceof Error) {
        throw new CredentialsError(error.message, profile);
      }
      throw error;
    }

    return { ecs, eventbridge, scheduler };
  } catch (error) {
    if (error instanceof CredentialsError) {
      throw error;
    }
    if (error instanceof Error) {
      throw new CredentialsError(error.message, profile);
    }
    throw new CredentialsError(String(error), profile);
  }
}
