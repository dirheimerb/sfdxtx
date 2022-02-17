public class CDPSearchWrapper {
  public class CDPSearchIndividual {
    public List<CDPSearchData> data { get; set; }
    public String startTime { get; set; }
    public String endTime { get; set; }
    public String rowCount { get; set; }
    public String queryId { get; set; }
  }

  public class CDPSearchData {
    public String UPID { get; set; }
    public String personName { get; set; }
    public String firstName { get; set; }
    public String lastName { get; set; }
    public String email { get; set; }
    public String secondaryEmail { get; set; }
    public String phone { get; set; }
    public String mobilePhone { get; set; }
    public String street { get; set; }
    public String otherStreet { get; set; }
    public String city { get; set; }
    public String state { get; set; }
    public String postalCode { get; set; }
    public String country { get; set; }
    public String dataSourceObjectId { get; set; }
    public String dataSourceId { get; set; }
    public String physicianRegistrationNo { get; set; }
    public String createdDate { get; set; }
    public String lastModifiedDate { get; set; }
  }
}
