/*
 * @auther: Char
 * @createdDate: 6 Jan 2022
 * @desc : For Testing
 * @ Added cacheable=true, to wire can use token BDirheimer
 *
 */
public class DisplayUnifiedProfileImpl {
  @AuraEnabled(cacheable=true)
  public static Map<String, String> getCDPToken() {
    return CDP_APIUtls.getCDPToken(CDP_APIUtls.getJWTBearerToken());
  }
}
