import { getFunctions, httpsCallable } from "firebase/functions";
import { app } from "./firebaseChurchService";
import type { UserRole } from "../types";

/**
 * Portal client for the Cloud Functions that own church roles.
 *
 * A leader account created in the Members Registry used to exist only in
 * localStorage — the person could never actually sign in with that role.
 * This service closes that gap: `setUserRole` (Admin SDK) writes the custom
 * claim, which both Firebase Auth and `firestore.rules` trust.
 *
 * Region must match `REGION` in functions/index.js.
 */
const functions = getFunctions(app, "africa-south1");
const setUserRoleCallable = httpsCallable(functions, "setUserRole");

export interface RoleProvisionResult {
  uid: string;
  email: string;
  role: string;
  previousRole?: string;
}

/**
 * Grants a real Firebase role to an already-registered account.
 * The target must first sign up in the member app (or be created by an admin
 * in Firebase Auth); the Cloud Function returns `not-found` otherwise.
 */
export async function provisionLeaderRole(input: {
  email: string;
  role: UserRole;
  branch?: string;
  reason?: string;
}): Promise<RoleProvisionResult> {
  const result = await setUserRoleCallable({
    targetEmail: input.email.trim(),
    role: input.role,
    branch: input.branch || "Mbagala Kwa Matope (HQ)",
    reason: input.reason || "Imetolewa kupitia Daftari la Waumini (portal)",
  });
  return result.data as RoleProvisionResult;
}

/** Human-readable message for the most common provisioning failures. */
export function describeProvisionError(error: unknown): string {
  const code = (error as { code?: string })?.code || "";
  const message = (error as { message?: string })?.message || "";
  if (code.includes("not-found") || message.includes("Hakuna akaunti")) {
    return "Akaunti ya Firebase haijapatikana. Mhusika ajiandikishe kwanza kwenye app, kisha urudie kumpa wadhifa.";
  }
  if (code.includes("permission-denied")) {
    return "Ni Super Admin / Admin pekee anayeweza kugawa vyeo vya mfumo.";
  }
  if (code.includes("unauthenticated")) {
    return "Ingia kwa akaunti halisi ya Firebase kabla ya kugawa vyeo.";
  }
  return message || "Imeshindikana kugawa wadhifa. Kagua muunganisho na ruhusa zako.";
}
