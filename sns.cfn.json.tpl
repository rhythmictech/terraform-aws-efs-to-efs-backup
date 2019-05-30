{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Resources" : {
    "EmailSNSTopic": {
      "Type" : "AWS::SNS::Topic",
      "Properties" : {
        "Subscription": [
          {
           "Endpoint" : "${email_address}",
           "Protocol" : "Email"
          }
        ]
      }
    }
  },

  "Outputs" : {
    "ARN" : {
      "Description" : "Email SNS Topic ARN",
      "Value" : { "Ref" : "EmailSNSTopic" }
    }
  }
}
