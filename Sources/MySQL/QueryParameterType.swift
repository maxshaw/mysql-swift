//
//  QueryParameterType.swift
//  MySQL
//
//  Created by Yusuke Ito on 12/28/15.
//  Copyright © 2015 Yusuke Ito. All rights reserved.
//

import SQLFormatter
import Foundation

public protocol QueryParameter {
    func queryParameter(option: QueryParameterOption) throws -> QueryParameterType
    var omitOnQueryParameter: Bool { get }
}

public extension QueryParameter {
    var omitOnQueryParameter: Bool {
        return false
    }
}

public protocol QueryParameterDictionaryType: QueryParameter {
    func queryParameter() throws -> QueryDictionary
}

public extension QueryParameterDictionaryType {
    func queryParameter(option: QueryParameterOption) throws -> QueryParameterType {
        return try queryParameter().queryParameter(option: option)
    }
}

public protocol QueryParameterOptionType {
}


public struct QueryParameterNull: QueryParameter, ExpressibleByNilLiteral {
    
    public init() {
        
    }
    public init(nilLiteral: ()) {
        
    }
    public func queryParameter(option: QueryParameterOption) -> QueryParameterType {
        return QueryParameterWrap( "NULL" )
    }
}

public struct QueryDictionary: QueryParameter {
    let dict: [String: QueryParameter?]
    public init(_ dict: [String: QueryParameter?]) {
        self.dict = dict
    }
    public func queryParameter(option: QueryParameterOption) throws -> QueryParameterType {
        var keyVals: [String] = []
        for (k, v) in dict {
            if v == nil || v?.omitOnQueryParameter == false {
                keyVals.append("\(SQLString.escapeId(string: k)) = \(try QueryOptional(v).queryParameter(option: option).escaped())")
            }
        }
        return QueryParameterWrap( keyVals.joined(separator:  ", ") )
    }
}

//extension Dictionary: where Value: QueryParameter, Key: StringLiteralConvertible { }
// not yet supported
// extension Array:QueryParameter where Element: QueryParameter { }


protocol QueryArrayType: QueryParameter {
    
}

public struct QueryArray: QueryParameter, QueryArrayType {
    let arr: [QueryParameter?]
    public init(_ arr: [QueryParameter?]) {
        self.arr = arr
    }
    public init(_ arr: [QueryParameter]) {
        self.arr = arr.map { Optional($0) }
    }
    public func queryParameter(option: QueryParameterOption) throws -> QueryParameterType {
        return QueryParameterWrap( try arr.filter({ val in
            if let valid = val {
                return valid.omitOnQueryParameter == false
            }
            return true
        }).map({
            if let val = $0 as? QueryArrayType {
                return "(" + (try val.queryParameter(option: option).escaped()) + ")"
            }
            return try QueryOptional($0).queryParameter(option: option).escaped()
        }).joined(separator: ", ") )
    }
}



extension Optional: QueryParameter {
    
    public func queryParameter(option: QueryParameterOption) throws -> QueryParameterType {
        guard let value = self else {
            return QueryParameterNull().queryParameter(option: option)
        }
        guard let val = value as? QueryParameter else {
            throw QueryFormatError.castError(actual: "\(value.self)", expected: "QueryParameter", key: "")
        }
        return try val.queryParameter(option: option)
    }
    public var omitOnQueryParameter: Bool {
        guard let value = self else {
            return false
        }
        guard let val = value as? QueryParameter else {
            return false
        }
        return val.omitOnQueryParameter
    }
}


struct QueryOptional: QueryParameter {
    let val: QueryParameter?
    init(_ val: QueryParameter?) {
        self.val = val
    }
    func queryParameter(option: QueryParameterOption) throws -> QueryParameterType {
        guard let val = self.val else {
            return QueryParameterNull().queryParameter(option: option)
        }
        return try val.queryParameter(option: option)
    }
    var omitOnQueryParameter: Bool {
        return val?.omitOnQueryParameter ?? false
    }
}

struct QueryParameterWrap: QueryParameterType {
    let val: String
    init(_ val: String) {
        self.val = val
    }
    func escaped() -> String {
        return val
    }
}

extension String: QueryParameterType {
    public func escaped() -> String {
        return SQLString.escape(string: self)
    }
}

extension String: QueryParameter {
    public func queryParameter(option: QueryParameterOption) -> QueryParameterType {
        return QueryParameterWrap( SQLString.escape(string: self) )
    }
}

extension Int: QueryParameter {
    public func queryParameter(option: QueryParameterOption) -> QueryParameterType {
        return QueryParameterWrap( String(self) )
    }
}

extension UInt: QueryParameter {
    public func queryParameter(option: QueryParameterOption) -> QueryParameterType {
        return QueryParameterWrap( String(self) )
    }
}

extension Int64: QueryParameter {
    public func queryParameter(option: QueryParameterOption) -> QueryParameterType {
        return QueryParameterWrap( String(self) )
    }
}

extension Int32: QueryParameter {
    public func queryParameter(option: QueryParameterOption) -> QueryParameterType {
        return QueryParameterWrap( String(self) )
    }
}

extension Int16: QueryParameter {
    public func queryParameter(option: QueryParameterOption) -> QueryParameterType {
        return QueryParameterWrap( String(self) )
    }
}

extension Int8: QueryParameter {
    public func queryParameter(option: QueryParameterOption) -> QueryParameterType {
        return QueryParameterWrap( String(self) )
    }
}

extension UInt64: QueryParameter {
    public func queryParameter(option: QueryParameterOption) -> QueryParameterType {
        return QueryParameterWrap( String(self) )
    }
}

extension UInt32: QueryParameter {
    public func queryParameter(option: QueryParameterOption) -> QueryParameterType {
        return QueryParameterWrap( String(self) )
    }
}

extension UInt16: QueryParameter {
    public func queryParameter(option: QueryParameterOption) -> QueryParameterType {
        return QueryParameterWrap( String(self) )
    }
}

extension UInt8: QueryParameter {
    public func queryParameter(option: QueryParameterOption) -> QueryParameterType {
        return QueryParameterWrap( String(self) )
    }
}

extension Double: QueryParameter {
    public func queryParameter(option: QueryParameterOption) -> QueryParameterType {
        return QueryParameterWrap( String(self) )
    }
}

extension Float: QueryParameter {
    public func queryParameter(option: QueryParameterOption) -> QueryParameterType {
        return QueryParameterWrap( String(self) )
    }
}

extension Bool: QueryParameter {
    public func queryParameter(option: QueryParameterOption) -> QueryParameterType {
        return QueryParameterWrap( self ? "true" : "false" )
    }
}

extension Decimal: QueryParameter {
    public func queryParameter(option: QueryParameterOption) -> QueryParameterType {
        return QueryParameterWrap( String(describing: self) )
    }
}

/// MARK: Codable support

fileprivate struct QueryParameterEncoder: Encoder {
    let codingPath = [CodingKey]()
    
    let userInfo = [CodingUserInfoKey : Any]()
    
    final class Storage {
        init() {
            
        }
        var dict: [String: QueryParameter?] = [:]
    }
    let storage = Storage()
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(QueryParameterKeyedEncodingContainer<Key>(encoder: self))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("not supported unkeyedContainer in QueryParameter")
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError("not supported singleValueContainer in QueryParameter")
    }
    
}

fileprivate final class QueryParameterSingleValueEncoder: Encoder {
    let codingPath = [CodingKey]()
    
    let userInfo = [CodingUserInfoKey : Any]()
    
    var storage: QueryParameter? = nil
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        fatalError("not supported unkeyedContainer in QueryParameterSingleValueEncoder")
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("not supported unkeyedContainer in QueryParameterSingleValueEncoder")
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return QueryParameterSingleValueEncodingContainer(encoder: self)
    }
    
}


fileprivate struct QueryParameterSingleValueEncodingContainer: SingleValueEncodingContainer {
    let codingPath = [CodingKey]()
    
    var encoder: QueryParameterSingleValueEncoder
    
    mutating func encodeNil() throws {
        fatalError()
    }
    
    mutating func encode(_ value: Bool) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int) throws {
        encoder.storage = value
    }
    
    mutating func encode(_ value: Int8) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int16) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int32) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Int64) throws {
        encoder.storage = value
    }
    
    mutating func encode(_ value: UInt) throws {
        encoder.storage = value
    }
    
    mutating func encode(_ value: UInt8) throws {
        fatalError()
    }
    
    mutating func encode(_ value: UInt16) throws {
        fatalError()
    }
    
    mutating func encode(_ value: UInt32) throws {
        fatalError()
    }
    
    mutating func encode(_ value: UInt64) throws {
        encoder.storage = value
    }
    
    mutating func encode(_ value: Float) throws {
        fatalError()
    }
    
    mutating func encode(_ value: Double) throws {
        fatalError()
    }
    
    mutating func encode(_ value: String) throws {
        encoder.storage = value
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        fatalError()
    }
    
    
}

fileprivate struct QueryParameterKeyedEncodingContainer<Key : CodingKey> : KeyedEncodingContainerProtocol {
    let codingPath = [CodingKey]()
    
    let encoder: QueryParameterEncoder
    
    var storage: QueryParameterEncoder.Storage {
        return encoder.storage
    }
    
    mutating func encodeNil(forKey key: Key) throws {
        storage.dict[key.stringValue] = nil
    }
    
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        storage.dict[key.stringValue] = value
    }
    
    mutating func encode(_ value: Int, forKey key: Key) throws {
        storage.dict[key.stringValue] = value
    }
    
    mutating func encode(_ value: Int8, forKey key: Key) throws {
        storage.dict[key.stringValue] = value
    }
    
    mutating func encode(_ value: Int16, forKey key: Key) throws {
        storage.dict[key.stringValue] = value
    }
    
    mutating func encode(_ value: Int32, forKey key: Key) throws {
        storage.dict[key.stringValue] = value
    }
    
    mutating func encode(_ value: Int64, forKey key: Key) throws {
        storage.dict[key.stringValue] = value
    }
    
    mutating func encode(_ value: UInt, forKey key: Key) throws {
        storage.dict[key.stringValue] = value
    }
    
    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        storage.dict[key.stringValue] = value
    }
    
    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        storage.dict[key.stringValue] = value
    }
    
    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        storage.dict[key.stringValue] = value
    }
    
    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        storage.dict[key.stringValue] = value
    }
    
    mutating func encode(_ value: Float, forKey key: Key) throws {
        storage.dict[key.stringValue] = value
    }
    
    mutating func encode(_ value: Double, forKey key: Key) throws {
        storage.dict[key.stringValue] = value
    }
    
    mutating func encode(_ value: String, forKey key: Key) throws {
        storage.dict[key.stringValue] = value
    }
    
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        if value is Date {
            storage.dict[key.stringValue] = value as! Date
        } else if value is Data {
            storage.dict[key.stringValue] = value as! Data
        }
        let singleValueEncoder = QueryParameterSingleValueEncoder()
        try value.encode(to: singleValueEncoder)
        storage.dict[key.stringValue] = singleValueEncoder.storage
        
        //fatalError("not supported type \(T.self)")
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError("nestedContainer in query parameter is not supported.")
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        fatalError("nestedUnkeyedContainer in query parameter is not supported.")
    }
    
    mutating func superEncoder() -> Encoder {
        fatalError("superEncoder in query parameter is not supported.")
    }
    
    mutating func superEncoder(forKey key: Key) -> Encoder {
        fatalError("superEncoder(forKey:) in query parameter is not supported.")
    }
    
    
}

extension Encodable where Self: QueryParameter {
    public func queryParameter(option: QueryParameterOption) throws -> QueryParameterType {
        let encoder = QueryParameterEncoder()
        try self.encode(to: encoder)
        return try QueryDictionary(encoder.storage.dict).queryParameter(option: option)
    }
}
