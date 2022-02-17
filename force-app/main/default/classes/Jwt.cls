public class Jwt {
  public static String jwtUsername { get; set; }
  public static String jwtConnectedAppConsumerKey { get; set; }
  public static String jwtSigningCertificateName { get; set; }
  public static String jwtHostname { get; set; }

  public static void getToken() {
    /*jwtUsername = 'kjagdale@wlgore.com.cdp.trial';
        jwtSigningCertificateName = 'My_Salesforce_Gore_Com';
        jwtHostname = 'login.salesforce.com';
        jwtConnectedAppConsumerKey = '3MVG9cHH2bfKACZbnYVEU_R.WzCc0YXnz1mCtCyD1G7hFqT7OW8ABZXcTs1oBARPzMY09eUkKv28_yl7Ct3ME';
                */
    String accessToken = requestAccessToken();
    system.debug('TOKEN:' + accessToken);
  }

  public static String requestAccessToken() {
    string token = createToken();
    // string token = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIzTVZHOWNISDJiZktBQ1pibllWRVVfUi5XekNjMFlYbnoxbUN0Q3lEMUc3aEZxVDdPVzhBQlpYY1RzMW9CQVJQek1ZMDllVWtLdjI4X3lsN0N0M01FIiwic3ViIjoiYmRpcmhlaW1Ad2xnb3JlLmNvbS5jZHAudHJpYWwiLCJhdWQiOiJsb2dpbi5zYWxlc2ZvcmNlLmNvbSIsImV4cCI6MTYzOTA3MDY0NH0.XeSzYcHmtOUuoFj3vb2ggWrz3RULwMxirnumnOWi8d4NsnOHi4cETiV5I-LAz-f8NF9WOsLFLFjmJ7ZWEO5iHHk5lW_1YwSBVP58I9lYv0ul9w6I1MvdCD_DZdSN9Y8cmjGmbZh0Kg7XO82McpVVdXvARDEnOT_HoDBLV2ZBh20sj-8lcCiVNqBFGgUbELOMbqekdkqMD0r9cE8jo_LDQWSs1YEV-a7qb_OwTICGgLyCxpOpgiJtYV_NlgaJDXdX-2ijNM-I5Lqv6hptwwtNzF7kSMGaYkaTPm8VLTQe9y1r_qgDdYh0NztxHa3B4YrBv5jHM1IscEp8XDl1X5dUNQ';

    String grantType = 'urn:ietf:params:oauth:grant-type:jwt-bearer';
    String access_token = null;
    String body =
      'grant_type=' +
      EncodingUtil.urlEncode(grantType, 'UTF-8') +
      '&assertion=' +
      token;
    HttpRequest req = new HttpRequest();
    req.setMethod('POST');
    req.setEndpoint('https://login.salesforce.com/services/oauth2/token');
    req.setHeader('Content-type', 'application/x-www-form-urlencoded');
    req.setBody(body);

    /*Map<String, String> m = new Map<String, String>();
         m.put('grant_type', 'urn:ietf:params:oauth:grant-type:jwt-bearer');
        string token = createToken();
        // string token = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIzTVZHOWNISDJiZktBQ1pibllWRVVfUi5XekNjMFlYbnoxbUN0Q3lEMUc3aEZxVDdPVzhBQlpYY1RzMW9CQVJQek1ZMDllVWtLdjI4X3lsN0N0M01FIiwic3ViIjoiYmRpcmhlaW1Ad2xnb3JlLmNvbS5jZHAudHJpYWwiLCJhdWQiOiJsb2dpbi5zYWxlc2ZvcmNlLmNvbSIsImV4cCI6MTYzOTA3MDY0NH0.XeSzYcHmtOUuoFj3vb2ggWrz3RULwMxirnumnOWi8d4NsnOHi4cETiV5I-LAz-f8NF9WOsLFLFjmJ7ZWEO5iHHk5lW_1YwSBVP58I9lYv0ul9w6I1MvdCD_DZdSN9Y8cmjGmbZh0Kg7XO82McpVVdXvARDEnOT_HoDBLV2ZBh20sj-8lcCiVNqBFGgUbELOMbqekdkqMD0r9cE8jo_LDQWSs1YEV-a7qb_OwTICGgLyCxpOpgiJtYV_NlgaJDXdX-2ijNM-I5Lqv6hptwwtNzF7kSMGaYkaTPm8VLTQe9y1r_qgDdYh0NztxHa3B4YrBv5jHM1IscEp8XDl1X5dUNQ';
         m.put('assertion', token);
     
         HttpRequest req = new HttpRequest();
         req.setHeader('Content-Type','application/x-www-form-urlencoded');
         req.setEndpoint('https://login.salesforce.com/services/oauth2/token');
         req.setMethod('POST');
         req.setTimeout(60 * 1000);
         req.setBody(formEncode(m));*/

    system.debug('REQ: ' + req.getBody());

    HttpResponse res = new Http().send(req);

    system.debug('RESP: ' + res.getBody());
    if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
      return extractJsonField(res.getBody(), 'access_token');
    } else {
      throw new IllegalArgumentException(res.getBody());
    }
  }

  private static String formEncode(Map<String, String> m) {
    String s = '';
    for (String key : m.keySet()) {
      if (s.length() > 0) {
        s += '&';
      }
      // s += key + '=' + EncodingUtil.urlEncode(m.get(key), 'UTF-8');
      s += key + '=' + m.get(key);
    }
    return s;
  }

  private static String extractJsonField(String body, String field) {
    JSONParser parser = JSON.createParser(body);
    while (parser.nextToken() != null) {
      if (
        parser.getCurrentToken() == JSONToken.FIELD_NAME &&
        parser.getText() == field
      ) {
        parser.nextToken();
        return parser.getText();
      }
    }
    throw new IllegalArgumentException(
      field +
      ' not found in response ' +
      body
    );
  }

  public static String createToken() {
    String headerJson = '{"alg": "RS256", "typ": "JWT"}';
    String bodyJson = '{"iss": "3MVG9cHH2bfKACZbnYVEU_R.WzCc0YXnz1mCtCyD1G7hFqT7OW8ABZXcTs1oBARPzMY09eUkKv28_yl7Ct3ME","exp": 1669884312,"aud": "login.salesforce.com","sub": "bdirheim@wlgore.com.cdp.trial"}';
    // JSON.serialize(new Body(iss, prn, aud, exp));

    String token =
      base64UrlSafe(Blob.valueOf(headerJson)) +
      '.' +
      base64UrlSafe(Blob.valueOf(bodyJson));

    // Crypto.sign(algorithmName, input, privateKey)
    /*String signature = base64UrlSafe(Crypto.signWithCertificate(
                'RSA-SHA256',
                Blob.valueOf(token),
                jwtSigningCertificateName
                )); */
    //String base64StringEncode = 'MIIEpAIBAAKCAQEA63iGGjvt1cP3LKCg8hIcVwXGzwMugo0WMgaoRmFt1WVe0NgbI0pFaqHS+1/xo7d6bAaeKXXH9VLH/vWsbYojx66IlIBUsaNYSMGt0io0yToeFuqyhfOjgOFo4zZk1KHs/P06+Naw6PmJwztVK9pQO9PaK5uZydCI5YlqDwHp51lUUeej8wppOvVNsG1Bow7L0iMfHGDj4gd2/eETdk/e3ijVZhD/d/ab9t8WvzjfKfXuJaxZtYcMg8dzjShRkhqilm06AO7/H0JyELhuS4ZpJV3t9nro7/gbr/c8rQL4ctlHP1D7C5hCWvYGENqVJ1p0IFfG0+ZjMYeYpqdOLnrBUwIDAQABAoIBAQDrFhscmfRrVQizP3Mv+rDcmOHRz6VhpaYhL9BU4/SZ9mjhLMB7TS1ctk9DtJg1EXth2oGRdwu5e3o8q94IRsBOHYwyZqUn7KK5kNQPXR/yPtnHm228mnAEvgbPwYCNYVSPh+qWgRGCp4/IoLX54C32bR4GJ4U0ncPvFnASp6B03So3Hxoqv2bgMBhVv1VfvOnDPpOH3tmP2sosPQk4Ni94Q1qCbqiwDVhghpwuZIcZ20s31DCbFUg8nVIxTPzNViDmo0RdCyzcVbSuzjLMORDzMSeO/4WLKGxWjMu9yaEt4qBMcNo+RWq/KYNJ4QB4bEC9xQoCxqfHluAVpS/xPeLRAoGBAPaloCPce2DmbZGFr+qQuanVIkewwFTOOw/ZL+IfBuKaEvlg/ZxdAOgZ+pOlcENFBuk2COg04HrTIqlqpGsF5d9nOpUBUvoO1zR684VPGnLXeDodOhIlzegolFZt5ISCs+QPu3Pi7BVn7Y8RqVLu3rwJEtyM55xae4uOjOOTtw2nAoGBAPRmZz/yJmNgo8dBfRdY4A4Cks8Vupxun6iWwzdYhhfjEt4CHP32XoTVjHvx0VoFRgPiFGvZCUc967qzgMEkZNjbZ8f/yo5tyVWHK/wP5im67r7XpxiWuu/2b79GZhii05EfibuXQk4YLZXqmnFsmpO0LhsNYEClPMWX+heh+tx1AoGBAKyoMpsH++JQTAEjmYrVNvL5PR78TxbOqy+j9M4QtCwqeP/TcpVj0X+ot+1lUVn11ymn5sJOSZoRdOEtwt0catdhlvO50pEzlFirfQ8j2brstL/Rt9X+Ws6aoYSDNwW/zRfoH2u3PVaawwR085gXmRn+LBLyHCwqdvOxnVSuEeVfAoGAQwRtnaBWHHwcjQANQECzt8PG5BhOQqUnDMDCqUOSCazPuKcVsiJDyuMQEdC+mpPFnjz5YpVyMOHu6RRd4xiKuth3PeWLcsDyK4zUZ9soPxsuapCSFnEGs9R80hOI3YqQv0PJrfINUYLZxTk+vomMXaJT3kEtuqxU3M4O2zokox0CgYA7weOqC/eIstoCAzUFq+qRggpRa/bFEUXfOOlGXYxEVa3tLuIR+rkpxyt2y9ByOLGsPeAs+uJ8dDk4IgzwHdR69OP0rjGq6ac36Kc4e5SfzvTj9lsmBbmCPPXOXgig59CA4sFaRIExHaxq2zy5p4DPzSi7tUUHQ2ayQ/asiyBSA==';
    string privateKey =
      'MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCXJik6Y6rTLcIR' +
      '9gcdpARN2Ri7Af8oQtfOK/ffDUk5Q/oJxEeXjtNrUpvwL0ylWFKRtMA3Co+PJSzV' +
      'NmSIbC/aoed0C5A4rmJ+AIC/6HKBEMFKIhq0NGUkuq28ms5yi7gT95sdFjZ6Myie' +
      'e/2rOhzFwe3bYWWyw0u2vAmiLUItqio0p4Uq3vpo4kDLh6uNnlw68fRTkMoIwDDk' +
      '+QogyKdyNVuUvg+O4wnwm6aW/5k0wIxf1r0fqvDs4CgZZRKAoPpfutB5JPdLihcV' +
      'j6WasZLEPpTbZZwdV4qTnWcZBgACS06dVoFgiSlLdfnsaq7i2PZRVpUWaknB3Lyf' +
      'aMIRIrDJAgMBAAECggEACq3/93/Tkf6PkfqQ4+WjBreeVVdVpqv7aNZHOi/LgtP0' +
      'YrSHTPSC6HhCq6jB6QRpuCEd/D2fKWF6bpm8Zn3Db1alfpfzEagzrhy9vCGR1p//' +
      'EkyA18cEdwEINdV33RTVdba282oOgRmkhvcylCLD5e63DltORuBg9QlKAnchcA20' +
      'NX/yym9XUQTfPTsTbi3qvs+MHsDeA3xRdz+SF43y074zJWMOv5KGXNTb3rq3TKfP' +
      '3lhiEiBebb/ilNa8+Dpw0cdyERB9G++0KhB8u0LDq0qxLDo/7daDy5+nj77L3lCp' +
      'DOMNXH1Wfh7WJWfJjAVwZpD1nfoiukepj/Nuku3EgQKBgQDTSvdmW2t9rX8pbFpo' +
      'ftuva2n0LQeIgDI6AwRq4sRZ/jQV9a6yBNaRkhHTHhgJaRybdmf1+Xdbdpr4Msjo' +
      'OJoaU2XRXMuaxp4er2Bcic5pF8xb/RCcLMhYUc1QDOOxC7ASHH9lEVxg9quwYPw5' +
      'r/oEHE5Me/AjUzcXHbHN8KpuSQKBgQC3IWfZE23x5ovwWzMc93PrieRCgKLaAhsg' +
      'zhe8fM924omDEJhtjruWElvDZL+sMOMYTMyGEMLyQbnhZ94KNGDY8iIoUU0gikRb' +
      'bQLFsnupNgH0tSZPgmirc/OO8YXHbZqWWCG1rc2skvBgixUtNWorbs4Zy4xuUe7b' +
      'uiyDj/AugQKBgGiZqDhn8aLaDSW4mlk41BDXoDBdSmls7XCCpeE0OfhDPA3S/pTq' +
      'iD6wjVpyf3vJKXxc9cJzqX8CDF3q5kLwInn9513qDnGk+go+z/l/z0t/mI/BjEOE' +
      'd/ohJP8IIoA3RQbyTK8AFTd7Zit/F96HG8KFMM30XUFfpNowvSEyj2zhAoGAem68' +
      'BhYGUE6JSlU+s+QAPP3AfHGR7tyvlFwU5HAxJ9NGijiDH+PoJ+n4LYbi2lUIzssx' +
      'hYQZQWuNwVP2z626/e/LxFaukM2/67vSuaedI0C3SAoAJfIS1mW79NomTXFKg69C' +
      'QjuDoRfP20vBCauHYqg+5GIAbhUa8w3iCscllYECgYB21z1WPRwgim2rfD0aFmkd' +
      'K9lg5xaK9UCwoGFTh3GiLguHSBQPDvcrB6GQDqoi+IeFIccGJnvwyKlDJFOyo6Uy' +
      'NUpI3qi/yMjVaQ9hHrnqbXVTPhoDO5j6LuQMPZzX654SlGeo5EfAyOVGNDid6vrR' +
      'HFJUBnxw3fYQGM+gZhjcBw==';
    system.debug('** privateKey' + privateKey);
    string signature = '';
    try {
      signature = base64UrlSafe(
        Crypto.sign('RSA-SHA256', Blob.valueOf(token), Blob.valueOf(privateKey))
      );
    } catch (Exception err) {
      system.debug('ERROR: ' + err);
    }
    token += '.' + signature;
    system.debug('Token' + token);

    return token;
  }

  private static String base64UrlSafe(Blob b) {
    return EncodingUtil.base64Encode(b).replace('+', '-').replace('/', '_');
  }
}
