import (
	"github.com/F-Bh/cue-dynamodb/dynamodb"
    "github.com/F-Bh/cue-dynamodb/cf"
)
#TestTable: dynamodb.#Table
#TestTable: {
	name: "test-table"
	partitionKey: {
		name: "artist"
		type: dynamodb.#DynamoString
	}
	sortKey: {
		name: "age"
		type: dynamodb.#DynamoNumber
	}
	lsis: [{
		indexName: "lsi1"
		sortKey: {
			name: "gender"
			type: dynamodb.#DynamoBinary
		}
		projection: projectionType: "KEYS_ONLY"
	}, {
		indexName: "lsi2"
		sortKey: {
			name: "language"
			type: dynamodb.#DynamoString
		}
		projection: {
			type: "INCLUDE"
			nonKeyAttributes: ["hair-colour", "children"]
		}
	}]
	gsis: [{
		indexName: "gsi-1"
		provisionedThroughput: {
			readCapacityUnits:  100
			writeCapacityUnits: 5.5
		}
		partitionKey: {
			name: "address"
			type: dynamodb.#DynamoString
		}
		sortKey: {
			name: "alive"
			type: dynamodb.#DynamoBoolean
		}
		projection: projectionType: "ALL"
	}, {
		indexName: "gsi-2"
		partitionKey: {
			name: "genre"
			type: dynamodb.#DynamoString
		}
		projection: projectionType: "ALL"
	}]
}



_out: cf.#CreateTable & {
	#table: #TestTable
    #meta:  {
		BillingMode:        "PAY_PER_REQUEST"
		Tags: [{
			Key:   "tag1"
			Value: "tag-val-1"
		}, {
			Key:   "tag2"
			Value: "tag-val-2"
		}]
	}
}

_out.#output