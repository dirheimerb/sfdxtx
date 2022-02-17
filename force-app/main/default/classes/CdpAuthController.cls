public class CdpAuthController {
  public CdpAuthController() {
    Auth.JWT jwt = new Auth.JWT();
    jwt.setSub('sfadminc360@wlgore.com.cdp.trial');
    jwt.setAud('https://wlgorecdp.my.salesforce.com');
    jwt.setIss(
      '3MVG9cHH2bfKACZbnYVEU_R.WzCq4iTxlkT7WbqdloNmSbRpBmEv5f5xyzk4jSd4cand0K_eK9ER2Fb6qbvp4'
    );

    //Additional claims to set scope
    Map<String, Object> claims = new Map<String, Object>();
    claims.put('scope', 'scope name');

    jwt.setAdditionalClaims(claims);

    //Create the object that signs the JWT bearer token
    Auth.JWS jws = new Auth.JWS(jwt, 'SelfSignedCert_27Aug2021_231003');

    //Get the resulting JWS in case debugging is required
    String token = jws.getCompactSerialization();

    //Set the token endpoint that the JWT bearer token is posted to
    String tokenEndpoint = 'https://login.salesforce.com/services/oauth2/token';

    //POST the JWT bearer token
    Auth.JWTBearerTokenExchange bearer = new Auth.JWTBearerTokenExchange(
      tokenEndpoint,
      jws
    );

    //Get the access token
    String accessToken = bearer.getAccessToken();
  }
}
