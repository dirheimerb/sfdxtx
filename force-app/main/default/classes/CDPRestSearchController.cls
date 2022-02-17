/**
 * @description       :
 * @author            : BDirheimer
 * @group             :
 * @last modified on  : 02-06-2022
 * @last modified by  : BDirheimer
 **/
public with sharing class CDPRestSearch extends CDPRestClient {
  /**
   * Final variable section
   */
  @testVisible
  private static final String DEFAULTNAMEDCREDTIAL = 'CDPQuery';
  private static final String PATH = '/services/data/v52.0/query';
  /**
   * This is only being used to extend for exceptions
   */
  public class CDPRestSearchException extends Exception {
  }

  @AuraEnabled
  public CDPRestSearch() {
    String searchParam;
    String searchKey;
    namedCredentialName = DEFAULTNAMEDCREDTIAL;
  }

  public List<CDPRestSearchModel> getData() {
    HttpResponse response = getPath(PATH);
    switch on response.getStatusCode() {
      when 201 {
        try {
          return CDPRestSearchModel.parse(response.getBody());
        } catch (System.JSONException jx) {
          throw new CDPRestSearch.CDPRestSearchException(jx.getMessage());
        }
      }
      when 404 {
        throw new CDPRestSearchModel.CDPRestSearchException('404 error');
      }
      when else {
        throw new CDPRestSearchModel.CDPRestSearchException(
          'Unexpected Response code: ' + response.getStatusCode()
        );
      }
    }
  }
}
