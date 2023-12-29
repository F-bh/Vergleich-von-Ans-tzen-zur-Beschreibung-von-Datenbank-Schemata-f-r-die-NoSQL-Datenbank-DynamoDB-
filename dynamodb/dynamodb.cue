package dynamodb

import (
	"list"
	"strings"
)

#DynamoName: string
#DynamoName: =~"[a-zA-Z0-9._-]"
#DynamoName: strings.MinRunes(1)

#DynamoIndexName: #DynamoName & strings.MinRunes(3) & strings.MaxRunes(255)

// we know that each code point is 1byte long since we are only allowed to use ASCII characters  for index names
#DynamoAttributeName:          #DynamoName & strings.MaxRunes(64Ki-1) //minRunes(min-1) = min required
#DynamoSecondaryAttributeName: #DynamoName & strings.MaxRunes(255)

#DynamoNumber:     "N"
#DynamoString:     "S"
#DynamoNull:       "NULL"
#DynamoBinary:     "B"
#DynamoBoolean:    "BOOL"
#DynamoStringSet:  "SS"
#DynamoNumberSet:  "NS"
#DynamoBinarySet:  "BS"
#_DynamoTypeUnion: #DynamoNumber | #DynamoString | #DynamoNull | #DynamoBinary | #DynamoBoolean | #DynamoStringSet | #DynamoNumberSet | #DynamoBinarySet

#_DynamoNumberValueConstraint: >=1e-130 &
	<=9.9999999999999999999999999999999999999e+125 |
	>=-9.9999999999999999999999999999999999999e+125 &
	<=-1e-130 | 0

//DynamoDB supports both floats and integers with the same datatype
#DynamoNumberValue: {
	DynamoNumber!: number & #_DynamoNumberValueConstraint
}

#DynamoStringValue: {
	DynamoString!: string
}
#DynamoNullValue: {
	DynamoNull!: true
}
#DynamoBinaryValue: {
	DynamoBinary!: bytes
}
#DynamoBooleanValue: {
	DynamoBoolean!: bool
}

#_DynamoValueUnion:
	#DynamoNumberValue |
	#DynamoStringValue |
	#DynamoNullValue |
	#DynamoBinaryValue |
	#DynamoBooleanValue |
	#DynamoMapValue |
	#DynamoListValue |
	#DynamoSetValue

#DynamoScalarValue: #DynamoNumberValue | #DynamoStringValue | #DynamoNullValue | #DynamoBinaryValue | #DynamoBooleanValue

#DynamoUnixTime: #DynamoNumberValue: #DynamoNumber: >=-31536000 //https://en.wikipedia.org/wiki/Unix_time

#DynamoStringSetValue: {
	DynamoString!: [#DynamoStringValue, ...]

	DynamoString: list.UniqueItems //may not be correct still WIP
}
#DynamoNumberSetValue: {
	DynamoNumber!: [#DynamoNumberValue, ...]
	DynamoNumber: list.UniqueItems
}
#DynamoBinarySetValue: {
	DynamoBinary!: [#DynamoBinaryValue, ...]
	DynamoBinary: list.UniqueItems
}

#DynamoSetValue: #DynamoStringSetValue | #DynamoNumberSetValue | #DynamoBinarySetValue

// duplicate keys are allowed,
// but only the last one in the map will be created during a put item operation
// so they are permissable
// checked via manual testing with DynamoDB
#DynamoMapValue: {
	DynamoMap!: [#_DynamoMapElem, ...] | []
}

#DynamoListValue: {
	DynamoList!: [#_DynamoValueUnion, ...] | []
}

#_DynamoMapElem: {
	#DynamoAttributeName!: #_DynamoValueUnion
}

#DynamoTag: {
	Key!: string
	Key!: strings.MaxRunes(128)
	Key!: =~"[a-zA-Z0-9._:=+/ -]" 

	Value!: string
	Value!: strings.MaxRunes(256)
	Value!: =~"[a-zA-Z0-9._:=+/ -]"
	//helper methods like has Prefix extremely useful for replacing complex regex
	if strings.HasPrefix(Key, "aws:") == true { 
		_|_
	}
}

#TablePrimaryKey: {
	partitionKey: {
		name!: #DynamoIndexName
		// no checks against bytes/string size sind we can't constrain their length in bytes properly in cue
		type!:   #DynamoString | #DynamoBinary | #DynamoNumber | #DynamoBoolean
		keyType: "HASH"
	}
	sortKey?: {
		name!:   #DynamoIndexName
		keyType: "RANGE"
		type!:   #DynamoString | #DynamoBinary | #DynamoNumber | #DynamoBoolean
	}
	if sortKey != _|_  {
		if sortKey.name == partitionKey.name {
			_keyEqual: _|_
		}
	}
}

#TableAttribute: {
	name!: #DynamoAttributeName
	type?: #_DynamoTypeUnion
}

#TableLSI: {
	indexName!: #DynamoIndexName
	sortKey!: {
		name!: #DynamoSecondaryAttributeName
		type!: #DynamoString | #DynamoBinary | #DynamoNumber
	}
	projection!: {
		projectionType: *"KEYS_ONLY" | "ALL" | "INCLUDE"
		if projectionType == "INCLUDE" {
			nonKeyAttributes!: [#DynamoAttributeName & strings.MaxRunes(255), ...]
			nonKeyAttributes!: list.MinItems(1)
		}
	}
}

#TableGSI: {
	indexName!: #DynamoIndexName
	#TablePrimaryKey
	provisionedThroughput?: {
		readCapacityUnits!:  number & >0
		writeCapacityUnits!: number & >0
	}
	projection!: {
		projectionType: *"KEYS_ONLY" | "ALL" | "INCLUDE"
		if projectionType == "INCLUDE" {
			nonKeyAttributes!: [#DynamoAttributeName & strings.MaxRunes(255), ...]
			nonKeyAttributes!: list.MinItems(1)
		}
	}
}

#Table: {
	#TablePrimaryKey
	name!: #DynamoIndexName
	lsis?: [#TableLSI, ...] & list.MaxItems(5)
	gsis?: [#TableGSI, ...] & list.MaxItems(20)
	extraAttributes?: [#TableAttribute, ...]

	//constraints
	_lsiAllAttributes:
	[ for lsi in lsis
		if lsi.attributes.include != _|_ {
			[ for attr in lsi.attributes.include {attr}]
		},
	]
	_gsiAllAttributes:
	[ for gsi in gsis
		if gsi.attributes.include != _|_ {
			[ for attr in gsi.attributes.include {attr}]
		},
	]
	_allSIAttributes: list.Concat([_lsiAllAttributes, _gsiAllAttributes])
	_allSIUniqueAttributes: [
		for x, attr in _allSIAttributes
			if !list.Contains(list.Drop(_allSIAttributes, x+1), attr){
				attr
			}
	]
	_allSIUniqueAttributes: list.UniqueItems()
	_allSIUniqueAttributes: list.MaxItems(100) //max 100 attributes between alls GSI's and LSI's https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ServiceQuotas.html#limits-secondary-indexes
}