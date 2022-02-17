/**  
 * To parse this data:
 * @import { Convert, DQValidation } from "./dQValidation.ts";
 * @param const DQValidation = Convert.toDQValidation(json);
 * These functions will throw an error if the JSON doesn't
 * match the expected interface, even if the JSON is valid.
*/
export interface DQValidation {
    decorators:     Decorator[];
    declarationLoc: LOC;
    classMembers:   ClassMember[];
    exports:        Export[];
    updatedAt:      Date;
    _allAttributes: null;
    _properties:    null;
    _methods:       null;
}

export interface ClassMember {
    type:       Type;
    name:       string;
    loc:        LOC;
    decorator?: string;
    value?:     ClassMemberValue;
}

export interface LOC {
    start: End;
    end:   End;
}

export interface End {
    line:   number;
    column: number;
}

export enum Type {
    Method = "method",
    Property = "property",
}

export interface ClassMemberValue {
    type:   string;
    value?: any[] | ValueValueClass;
}

export interface ValueValueClass {
}

export interface Decorator {
    type:    string;
    targets: Target[];
}

export interface Target {
    type:   Type;
    name:   string;
    value?: ClassMemberValue;
}

export interface Export {
    type: string;
}

// Converts JSON strings to/from your types
// and asserts the results of JSON.parse at runtime
export class Convert {
    public static toDQValidation(json: string): DQValidation {
        return cast(JSON.parse(json), r("DQValidation"));
    }

    public static DQValidationToJson(value: DQValidation): string {
        return JSON.stringify(uncast(value, r("DQValidation")), null, 2);
    }
}

function invalidValue(typ: any, val: any, key: any = ''): never {
    if (key) {
        throw Error(`Invalid value for key "${key}". Expected type ${JSON.stringify(typ)} but got ${JSON.stringify(val)}`);
    }
    throw Error(`Invalid value ${JSON.stringify(val)} for type ${JSON.stringify(typ)}`, );
}

function jsonToJSProps(typ: any): any {
    if (typ.jsonToJS === undefined) {
        const map: any = {};
        typ.props.forEach((p: any) => map[p.json] = { key: p.js, typ: p.typ });
        typ.jsonToJS = map;
    }
    return typ.jsonToJS;
}

function jsToJSONProps(typ: any): any {
    if (typ.jsToJSON === undefined) {
        const map: any = {};
        typ.props.forEach((p: any) => map[p.js] = { key: p.json, typ: p.typ });
        typ.jsToJSON = map;
    }
    return typ.jsToJSON;
}

function transform(val: any, typ: any, getProps: any, key: any = ''): any {
    function transformPrimitive(typ: string, val: any): any {
        if (typeof typ === typeof val) return val;
        return invalidValue(typ, val, key);
    }

    function transformUnion(typs: any[], val: any): any {
        // val must validate against one typ in typs
        const l = typs.length;
        for (let i = 0; i < l; i++) {
            const typ = typs[i];
            try {
                return transform(val, typ, getProps);
            } catch (_) {}
        }
        return invalidValue(typs, val);
    }

    function transformEnum(cases: string[], val: any): any {
        if (cases.indexOf(val) !== -1) return val;
        return invalidValue(cases, val);
    }

    function transformArray(typ: any, val: any): any {
        // val must be an array with no invalid elements
        if (!Array.isArray(val)) return invalidValue("array", val);
        return val.map(el => transform(el, typ, getProps));
    }

    function transformDate(val: any): any {
        if (val === null) {
            return null;
        }
        const d = new Date(val);
        if (isNaN(d.valueOf())) {
            return invalidValue("Date", val);
        }
        return d;
    }

    function transformObject(props: { [k: string]: any }, additional: any, val: any): any {
        if (val === null || typeof val !== "object" || Array.isArray(val)) {
            return invalidValue("object", val);
        }
        const result: any = {};
        Object.getOwnPropertyNames(props).forEach(key => {
            const prop = props[key];
            const v = Object.prototype.hasOwnProperty.call(val, key) ? val[key] : undefined;
            result[prop.key] = transform(v, prop.typ, getProps, prop.key);
        });
        Object.getOwnPropertyNames(val).forEach(key => {
            if (!Object.prototype.hasOwnProperty.call(props, key)) {
                result[key] = transform(val[key], additional, getProps, key);
            }
        });
        return result;
    }

    if (typ === "any") return val;
    if (typ === null) {
        if (val === null) return val;
        return invalidValue(typ, val);
    }
    if (typ === false) return invalidValue(typ, val);
    while (typeof typ === "object" && typ.ref !== undefined) {
        typ = typeMap[typ.ref];
    }
    if (Array.isArray(typ)) return transformEnum(typ, val);
    if (typeof typ === "object") {
        return typ.hasOwnProperty("unionMembers") ? transformUnion(typ.unionMembers, val)
            : typ.hasOwnProperty("arrayItems")    ? transformArray(typ.arrayItems, val)
            : typ.hasOwnProperty("props")         ? transformObject(getProps(typ), typ.additional, val)
            : invalidValue(typ, val);
    }
    // Numbers can be parsed by Date but shouldn't be.
    if (typ === Date && typeof val !== "number") return transformDate(val);
    return transformPrimitive(typ, val);
}

function cast<T>(val: any, typ: any): T {
    return transform(val, typ, jsonToJSProps);
}

function uncast<T>(val: T, typ: any): any {
    return transform(val, typ, jsToJSONProps);
}

function a(typ: any) {
    return { arrayItems: typ };
}

function u(...typs: any[]) {
    return { unionMembers: typs };
}

function o(props: any[], additional: any) {
    return { props, additional };
}

function m(additional: any) {
    return { props: [], additional };
}

function r(name: string) {
    return { ref: name };
}

const typeMap: any = {
    "DQValidation": o([
        { json: "decorators", js: "decorators", typ: a(r("Decorator")) },
        { json: "declarationLoc", js: "declarationLoc", typ: r("LOC") },
        { json: "classMembers", js: "classMembers", typ: a(r("ClassMember")) },
        { json: "exports", js: "exports", typ: a(r("Export")) },
        { json: "updatedAt", js: "updatedAt", typ: Date },
        { json: "_allAttributes", js: "_allAttributes", typ: null },
        { json: "_properties", js: "_properties", typ: null },
        { json: "_methods", js: "_methods", typ: null },
    ], false),
    "ClassMember": o([
        { json: "type", js: "type", typ: r("Type") },
        { json: "name", js: "name", typ: "" },
        { json: "loc", js: "loc", typ: r("LOC") },
        { json: "decorator", js: "decorator", typ: u(undefined, "") },
        { json: "value", js: "value", typ: u(undefined, r("ClassMemberValue")) },
    ], false),
    "LOC": o([
        { json: "start", js: "start", typ: r("End") },
        { json: "end", js: "end", typ: r("End") },
    ], false),
    "End": o([
        { json: "line", js: "line", typ: 0 },
        { json: "column", js: "column", typ: 0 },
    ], false),
    "ClassMemberValue": o([
        { json: "type", js: "type", typ: "" },
        { json: "value", js: "value", typ: u(undefined, u(a("any"), r("ValueValueClass"))) },
    ], false),
    "ValueValueClass": o([
    ], false),
    "Decorator": o([
        { json: "type", js: "type", typ: "" },
        { json: "targets", js: "targets", typ: a(r("Target")) },
    ], false),
    "Target": o([
        { json: "type", js: "type", typ: r("Type") },
        { json: "name", js: "name", typ: "" },
        { json: "value", js: "value", typ: u(undefined, r("ClassMemberValue")) },
    ], false),
    "Export": o([
        { json: "type", js: "type", typ: "" },
    ], false),
    "Type": [
        "method",
        "property",
    ],
};
