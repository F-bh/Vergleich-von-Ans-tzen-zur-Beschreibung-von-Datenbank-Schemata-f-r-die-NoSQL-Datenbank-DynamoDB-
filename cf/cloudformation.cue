package cf

import (
	"list"
	"strings"
	"github.com/F-Bh/cue-dynamodb/dynamodb"
)

#DynamoCFOperation: #CreateTable

#CreateTable: {
	#table: dynamodb.#Table
	#meta: {
		BillingMode?: *"PAY_PER_REQUEST" | "PROVISIONED"
		if BillingMode != _|_ && BillingMode == "PROVISIONED" {
			ReadCapacityUnits!:  number & >0
			WriteCapacityUnits!: number & >0
		}
		TableClass?:                *"STANDARD" | "STANDARD_INFREQUENT_ACCESS"
		PointInTimeRecovery?:       bool | *false
		DeletionProtectionEnabled?: bool | *true
		SSESpecification?: {
			Enabled!:        bool | *true
			KMSMasterKeyId?: string
			SSEType:         "KMS"
		}
		StreamSpecification?: StreamViewType?:    "KEYS_ONLY" | "NEW_IMAGE" | "OLD_IMAGE" | "NEW_AND_OLD_IMAGES"
		KinsesisStreamSpecification?: StreamArn!: string & strings.MinRunes(37) & strings.MaxRunes(1024)
		TimeToLiveSpecification?: {
			Enabled:       bool | *true
			AttributeName: dynamodb.#DynamoSecondaryAttributeName
		}
		ImportSourceSpecification?: {
			InputCompressionType?: "GZIP" | "NONE" | "ZSTD"
			InputFormat!:          "CSV" | "DYNAMODB_JSON" | "ION"
			InputFormatOptions?: {
				Csv?: {
					Delimiter?:  ";" | ":" | "|" | "\t" | " "
					HeaderList?: [ string, ...] & list.MinItems(1) & list.MaxItems(255)
				}
			}
			S3BucketSource!: {
				S3Bucket!:      string & =~"^[a-z0-9A-Z]+[a-zA-Z0-9.-]*[a-z0-9A-Z]+$" & strings.MaxRunes(255) //regex changed from ^[a-z0-9A-Z]+[\.\-\w]*[a-z0-9A-Z]+$
				S3BucketOwner?: string & =~"[0-9]{12}"
				S3KeyPrefix?:   string & strings.MaxRunes(1024)
			}
		}
		ContributorInsightsSpecification?: Enabled!: bool | *false
		Tags?: [dynamodb.#DynamoTag, ...]
		_tags: [ for tag in Tags {tag.Key}]
		_tags: list.MaxItems(50)
	}
	#output: {
		Type: "AWS::DynamoDB::Table"
		Properties: {
			#meta
			TableName: #table.name
			KeySchema: [
				{
					AttributeName: #table.partitionKey.name
					KeyType:       #table.partitionKey.keyType
				},
				if #table.sortKey != _|_ {
					AttributeName: #table.sortKey.name
					KeyType:       #table.sortKey.keyType
				},
			]
			AttributeDefinitions: [{
				AttributeName: #table.partitionKey.name
				AttributeType: #table.partitionKey.type
			},
				if #table.sortKey != _|_ {
					AttributeName: #table.sortKey.name
					AttributeType: #table.sortKey.type
				},
			]
			GlobalSecondaryIndexes: [ for gsi in #table.gsis {
				if #meta.ContributorInsightsSpecification != _|_ {
					ContributorInsightsSpecification: #meta.ContributorInsightsSpecification
				}
				IndexName: gsi.indexName
				if gsi.provisionedThroughput != _|_ {
					ProvisionedThroughput: gsi.provisionedThroughput
				}
				Projection: gsi.projection
				KeySchema: [{
					AttributeName: gsi.partitionKey.name
					KeyType:       gsi.partitionKey.type
				},
					if gsi.sortKey != _|_ {
						AttributeName: gsi.sortKey.name
						KeyType:       gsi.sortKey.keyType
					}]
			}]
			LocalSecondaryIndexes: [ for lsi in #table.lsis {
				IndexName:  lsi.indexName
				Projection: lsi.projection
				KeySchema: [{
					AttributeName: #table.partitionKey.name
					KeyType:       #table.partitionKey.keyType
				},
					{
						AttributeName: lsi.sortKey.name
						KeyType:       lsi.sortKey.type
					}]
			}]
		}
	}
}
