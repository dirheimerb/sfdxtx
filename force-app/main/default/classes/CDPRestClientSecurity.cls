/**
 * @description       : FLS and Object Security checks for CDPRest
 * @author            : BDirheimer
 * @group             :
 * @last modified on  : 02-06-2022
 * @last modified by  : BDirheimer
 **/
public with sharing class CDPRestClientSecurity {
  @testVisible
  private static Map<String, Set<String>> accessibleFields = new Map<String, Set<String>>();
  private static Map<String, Set<String>> updateFields = new Map<String, Set<String>>();

  /**
   * @description exception class
   */

  public class CDPRestClientSecurityException extends Exception {
  }

  public enum CrudType {
    CREATE,
    READ,
    EDIT,
    DEL,
    UPS
  }

  public enum FLSType {
    ACCESSIBLE,
    UPDATABLE
  }

  /**
   * @description this cachebuilder interface allows the class to
   * cache per-object results for each object requested. This prevents the
   * need to repeatedly calculate permission usage by calling
   * Schema.Describe* calls
   */
  private class PermissionCache implements Cache.CacheBuilder {
    /**
     * @description   Required method for the Cache
     * FieldName -> FLStype -> True/False
     * @param objType String object name used as the cache key
     * @return       `Object`
     */
    public Object doLoad(String objType) {
      return calculateFLS(objType);
    }

    public Map<String, Map<FLSType, Boolean>> calculateFLS(string objType) {
      Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(
        new List<String>{ objType }
      );

      Map<String, Map<FLSType, Boolean>> results = new Map<String, Map<FLSType, Boolean>>();
      for (SObject field : descResult[0].fields.getMap().values()) {
        DescribeFieldResult fieldDetails = field.getDescribe();
        String fieldKey = String.valueOf(field).toLowerCase();
        results.put(fieldKey, new Map<FLSType, Boolean>());
        results.get(fieldKey)
          .put(FLSType.ACCESSIBLE, fieldDetails.isAccessible());
        results.get(fieldKey)
          .put(FLSType.UPDATABLE, fieldDetails.isUpdateable());
      }
      return results;
    }
  }
  public static Boolean crud(SObject obj, CrudType permission) {
    switch on permission {
      when CREATE {
        return obj.getSObjectType().getDescribe().isCreateable();
      }
      when READ {
        return obj.getSObjectType().getDescribe().isAccessible();
      }
      when EDIT {
        return obj.getSObjectType().getDescribe().isUpdateable();
      }
      when DEL {
        return obj.getSObjectType().getDescribe().isDeletable();
      }
    }
    return false;
  }

  @testVisible
  private static Boolean crud(List<SObject> objs, CrudType permission) {
    return crud(objs?.get(0), permission);
  }

  @testVisible
  private static Boolean crud(String objectName, CrudType permission) {
    Type t = Type.forName(objectName);
    SObject p = (SObject) JSON.deserialize('{}', t);
    return crud(p, permission);
  }

  public static Boolean create(SObject obj) {
    return CDPRestClientSecurity.crud(obj, CrudType.CREATE);
  }

  public static Boolean create(List<SObject> objs) {
    return crud(objs?.get(0), CrudType.CREATE);
  }

  public static Boolean create(String objName) {
    return crud(objName, CrudType.CREATE);
  }

  public static Boolean read(SObject obj) {
    return CDPRestClientSecurity.crud(obj, CrudType.EDIT);
  }

  public static Boolean read(List<SObject> objs) {
    return crud(objs?.get(0), CrudType.READ);
  }

  /**
   * @description convenience api for determining if the running user can
   * read the specified object
   * @param String Object type to check read permissions on
   * @return Boolean
   */
  public static Boolean read(String objName) {
    return crud(objName, CrudType.READ);
  }

  /**
   * @description convenience api for determining if the running user can
   * edit / update the specified object
   * @param obj object type to check edit permissions on
   * @return Boolean
   **/
  public static Boolean edit(SObject obj) {
    return CDPRestClientSecurity.crud(obj, CrudType.EDIT);
  }

  /**
   * @description convenience api for determining if the running user can
   * edit / update the specified objects
   * @param obj object type to check edit permissions on
   **/
  public static Boolean edit(List<SObject> objs) {
    return crud(objs?.get(0), CrudType.EDIT);
  }

  /**
   * @description convenience api for determining if the running user can
   * edit the specified object
   * @param String Object type to check edit permissions on
   * @return Boolean
   **/
  public static Boolean edit(String objName) {
    return crud(objName, CrudType.EDIT);
  }

  /**
   * @description convenience api for determining if the running user can
   * upsert (insert and update) the specified objects
   * @param obj object type to check edit permissions on
   * @return Boolean
   **/
  public static Boolean ups(SObject obj) {
    return crud(obj, CrudType.UPS);
  }

  /**
   * @description convenience api for determining if the running user can
   * edit / update the specified objects
   * @param obj object type to check upsert permissions on
   * @return Boolean
   **/
  public static Boolean ups(List<SObject> objs) {
    return crud(objs?.get(0), CrudType.UPS);
  }

  /**
   * @description convenience api for determining if the running user can
   * upsert the specified object
   * @param String Object type to check upsert permissions on
   * @return Boolean
   **/
  public static Boolean ups(String objName) {
    return crud(objName, CrudType.UPS);
  }

  /**
   * @description convenience api for determining if the running user can
   * delete/destroy the specified object
   * @param obj object type to check destroy permissions on
   * @return Boolean
   **/
  public static Boolean destroy(SObject obj) {
    return CDPRestClientSecurity.crud(obj, CrudType.DEL);
  }

  /**
   * @description convenience api for determining if the running user can
   * delete the specified object
   * @param String Object type to check delete permissions on
   * @return Boolean
   **/
  public static Boolean destroy(List<SObject> objs) {
    return crud(objs?.get(0), CrudType.DEL);
  }

  /**
   * @description convenience api for determining if the running user can
   * delete the specified object
   * @param String Object type to check create permissions on
   * @return Boolean
   **/
  public static Boolean destroy(String objName) {
    return crud(objName, CrudType.DEL);
  }

  public static Boolean flsAccessible(String obj, String field) {
    return getFLSForFieldOnObject(obj, field, FLSType.ACCESSIBLE);
  }

  public static Map<String, Boolean> bulkFLSAccessible(
    String obj,
    Set<String> fields
  ) {
    Map<String, Boolean> results = new Map<String, Boolean>();
    for (String field : fields) {
      results.put(field, flsAccessible(obj, field));
    }
    return results;
  }

  public static Boolean flsUpdatable(String obj, String field) {
    return getFLSForFieldOnObject(obj, field, FLSType.UPDATABLE);
  }

  public static Map<String, Boolean> bulkFLSUpdatable(
    String obj,
    Set<String> fields
  ) {
    Map<String, Boolean> results = new Map<String, Boolean>();
    for (String field : fields) {
      results.put(field, flsUpdatable(obj, field));
    }
    return results;
  }

  /**
   * @description   Utilizes the Metadata to determaine FLS
   *
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  @testVisible
  private static Set<String> memoizeFLSMDC(String objType, FLSType action) {
    List<FieldPermissions> fields = [
      SELECT Id, Field, PermissionsEdit, PermissionsRead, SobjectType
      FROM FieldPermissions
      WHERE SobjectType = :objType
    ];

    if (!CDPRestClientSecurity.accessibleFieldsByObject.containsKey(objType)) {
      Set<String> accessibleFields = new Set<String>();
      Set<String> updatableFields = new Set<String>();
      for (FieldPermissions field : fields) {
        String[] parts = field.Field.split('\\.');
        if (field.PermissionsRead) {
          accessibleFields.add(parts[1].toLowerCase());
        }
        if (field.PermissionsEdit) {
          updatableFields.add(parts[1].toLowerCase());
        }
      }
      CDPRestClientSecurity.accessibleFieldsByObject.put(
        objType,
        accessibleFields
      );
      CDPRestClientSecurity.updatableFieldsByObject.put(
        objType,
        updatableFields
      );
    }

    if (action == CDPRestClientSecurity.FLSType.ACCESSIBLE) {
      return CDPRestClientSecurity.accessibleFieldsByObject.get(objType);
    } else {
      return CDPRestClientSecurity.updatableFieldsByObject.get(objType);
    }
  }
}
