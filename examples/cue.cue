// Kommentar
#TableMetaDef: {
	billingMode?:        *"onDemand" | "provisioned"
	pointInTimeRecovery: bool | *false
	deleteProtection:    bool | *true
	etc?:                string
}
#TableKeyDef: {
	type: "string" | "number"
	name: string
}

#TableDef: {
	name: string
	meta: #Tab1eMetaDef
	key: {
		partitionKey: #TableKeyDef
		sortKey?:     #TableKeyDef & {
			name: !=partitionKey.name
		}
	}
}

Table: #TableDef
table: {
	name: "test"
	meta: {
		billingmode: "onDemand"
	}
	key: {
		partitionKey: {
			type: "string"
			name: "1"
		}
		sortKey: {
			type: "number"
			name: "2"
		}
	}
}
