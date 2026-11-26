import { useEffect, useState } from 'react';
import type { ChurchMember } from '../types';
import { INITIAL_MEMBERS } from '../data/mockData';
import { loadStored, saveStored, STORAGE_KEYS } from '../utils/storage';

/**
 * The single read/write path for the member registry.
 *
 * Previously `MembersModule` kept members in its own `useState`, while the
 * dashboard printed a hard-coded "142" for registered congregants. A leader
 * who registered someone saw the head-count stay at 142, and every module
 * re-read localStorage independently, so two open tabs could silently
 * overwrite each other.
 *
 * Every consumer now goes through these helpers, and a `storage` listener
 * keeps other tabs in sync.
 */
const MEMBERS_EVENT = 'zion:members-changed';

export function readMembers(): ChurchMember[] {
  return loadStored<ChurchMember[]>(STORAGE_KEYS.members, INITIAL_MEMBERS);
}

export function writeMembers(members: ChurchMember[]): void {
  saveStored(STORAGE_KEYS.members, members);
  try {
    window.dispatchEvent(new CustomEvent(MEMBERS_EVENT));
  } catch {
    // Non-browser environment: local state still updates in the caller.
  }
}

export function useMembers(): [ChurchMember[], (next: ChurchMember[]) => void] {
  const [members, setMembers] = useState<ChurchMember[]>(readMembers);

  useEffect(() => {
    const sync = () => setMembers(readMembers());

    window.addEventListener(MEMBERS_EVENT, sync);
    // Fires when another tab writes the same localStorage key.
    window.addEventListener('storage', sync);
    return () => {
      window.removeEventListener(MEMBERS_EVENT, sync);
      window.removeEventListener('storage', sync);
    };
  }, []);

  const update = (next: ChurchMember[]) => {
    setMembers(next);
    writeMembers(next);
  };

  return [members, update];
}

/** Members who have received water baptism, as a share of the register. */
export function baptizedShare(members: ChurchMember[]): number {
  if (members.length === 0) return 0;
  return Math.round((members.filter((member) => member.isBaptized).length / members.length) * 100);
}
