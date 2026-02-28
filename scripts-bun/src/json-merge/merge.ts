type JsonValue = string | number | boolean | null | JsonObject | JsonArray;
type JsonObject = { [key: string]: JsonValue };
type JsonArray = JsonValue[];

function isPlainObject(value: unknown): value is JsonObject {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

/**
 * Deep merges two JSON values. When both are plain objects, keys are merged
 * recursively. For all other cases (arrays, primitives, null), the override
 * value wins.
 */
export function deepMerge(base: JsonValue, override: JsonValue): JsonValue {
  if (isPlainObject(base) && isPlainObject(override)) {
    const result: JsonObject = { ...base };
    for (const key of Object.keys(override)) {
      const baseVal = base[key];
      const overrideVal = override[key]!;
      if (baseVal !== undefined) {
        result[key] = deepMerge(baseVal, overrideVal);
      } else {
        result[key] = overrideVal;
      }
    }
    return result;
  }
  return override;
}

/**
 * Recursively sorts all object keys alphabetically. Arrays are traversed
 * (sorting objects within them) but array order is preserved.
 */
export function sortKeysDeep(value: JsonValue): JsonValue {
  if (isPlainObject(value)) {
    const sorted: JsonObject = {};
    const keys = Object.keys(value).sort((a, b) => a.localeCompare(b));
    for (const key of keys) {
      sorted[key] = sortKeysDeep(value[key]!);
    }
    return sorted;
  }
  if (Array.isArray(value)) {
    return value.map(sortKeysDeep);
  }
  return value;
}
