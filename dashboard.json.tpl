{
  "widgets": [{
    "type": "metric",
    "x": 0,
    "y": 0,
    "width": 18,
    "height": 3,
    "properties": {
      "view": "singleValue",
      "stacked": true,
      "metrics": [
        ["AWS/EFS", "BurstCreditBalance", "FileSystemId", "${SrcEFS}", {
          "stat": "Minimum"
        }],
        [".", "PermittedThroughput", ".", "."],
        [".", "TotalIOBytes", ".", ".", {
          "period": 60,
          "stat": "Sum"
        }]
      ],
      "region": "${AWS_Region}",
      "title": "BurstCreditBalance, PermittedThroughput, TotalIOBytes - Source",
      "period": 300
    }
  }, {
    "type": "metric",
    "x": 0,
    "y": 3,
    "width": 18,
    "height": 3,
    "properties": {
      "view": "singleValue",
      "stacked": false,
      "region": "${AWS_Region}",
      "metrics": [
        ["AWS/EFS", "BurstCreditBalance", "FileSystemId", "${DstEFS}", {
          "period": 60,
          "stat": "Average"
        }],
        [".", "PermittedThroughput", ".", ".", {
          "period": 60,
          "stat": "Average"
        }],
        [".", "TotalIOBytes", ".", ".", {
          "period": 60,
          "stat": "Sum"
        }]
      ],
      "title": "BurstCreditBalance, PermittedThroughput, TotalIOBytes - Backup",
      "period": 300
    }
  }, {
    "type": "text",
    "x": 18,
    "y": 0,
    "width": 6,
    "height": 12,
    "properties": {
      "markdown": "\n# EFS Backup Solution \n \n Visit Solution:[LandingPage](http://aws.amazon.com/answers/infrastructure-management/efs-backup). \n A link to this dashboard: [${AWS_StackName}](#dashboards:name=${AWS_StackName}). \n"
    }
  }, {
    "type": "metric",
    "x": 0,
    "y": 6,
    "width": 9,
    "height": 6,
    "properties": {
      "view": "timeSeries",
      "stacked": false,
      "metrics": [
        ["AWS/Lambda", "Errors", "FunctionName", "${Orchestrator}", {
          "stat": "Sum"
        }],
        [".", "Invocations", ".", ".", {
          "stat": "Sum"
        }]
      ],
      "region": "${AWS_Region}",
      "period": 300,
      "title": "Orchestrator"
    }
  }, {
    "type": "metric",
    "x": 9,
    "y": 6,
    "width": 9,
    "height": 6,
    "properties": {
      "view": "timeSeries",
      "stacked": false,
      "metrics": [
        ["AWS/DynamoDB", "SuccessfulRequestLatency", "TableName", "${EFSDynamoDB}", "Operation", "UpdateItem", {
          "stat": "Sum"
        }],
        ["...", "PutItem", {
          "stat": "Sum"
        }]
      ],
      "region": "${AWS_Region}",
      "title": "Backup Table"
    }
  }]
}
