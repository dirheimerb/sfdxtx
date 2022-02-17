import { hasNumber, isArrayLike, isBoolean, isNumber, isObject, Optional } from '@salesforce/ts-types';


export function isEmpty(value: unknown): boolean {
  if (value == null) return true;
  if (isNumber(value)) return false;
  if (isBoolean(value)) return false;
  if (isArrayLike(value) && value.length > 0) return false;
  if (hasNumber(value, 'size') && value.size > 0) return false;
  if (isObject(value) && Object.keys(value).length > 0) return false;
  return true;
}

/**
 * Converts the first character of `string` to lower case.
 *
 * @param string The string to convert.
 */
export function lowerFirst(value: string): string;
/**
 * @see lowerFirst
 */
export function lowerFirst(value?: string): Optional<string>;
// underlying function
export function lowerFirst(value?: string): Optional<string> {
  return value && value.charAt(0).toLowerCase() + value.slice(1);
}

/**
 * Formats a camel case style `string` into a title case.
 *
 * @param text Text to transform.
 */
export function camelCaseToTitleCase(text: string): string {
  return text
    .replace(/(^\w|\s\w)/g, (m) => m.toUpperCase())
    .replace(/([A-Z][a-z]+)/g, ' $1')
    .replace(/\s{2,}/g, ' ')
    .trim();
}

/**
 * Converts string to snake case.
 *
 * @param str The string to convert.
 */
export function snakeCase(str: string): string;
export function snakeCase(str?: string): Optional<string>;
// underlying function
export function snakeCase(str?: string): Optional<string> {
  return (
    str &&
    str
      .replace(/([a-z])([A-Z])/g, '$1_$2')
      .toLowerCase()
      .replace(/\W/g, '_')
      .replace(/^_+|_+$/g, '')
  );
}

/**
 * Converts the first character of `string` to upper case.
 *
 * @param string The string to convert.
 */
export function upperFirst(value: string): string;
/**
 * @see upperFirst
 */
export function upperFirst(value?: string): Optional<string>;
// underlying function
export function upperFirst(value?: string): Optional<string> {
  return value && value.charAt(0).toUpperCase() + value.slice(1);
}

/**
 * Converts value to a boolean.
 *
 * @param value The value to convert
 * @returns boolean
 */
export function toBoolean(value: unknown): boolean {
  switch (typeof value) {
    case 'boolean':
      return value;
    case 'string':
      return value.toLowerCase() === 'true' || value === '1';
    default:
      return false;
  }
}