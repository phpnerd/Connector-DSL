/*
 * Copyright (c) Thomas Nägele and contributors. All rights reserved.
 * Licensed under the MIT license. See LICENSE file in the project root for details.
*/

package nl.ru.sws.connectordsl.generator.python

import nl.ru.sws.connectordsl.connectorDSL.BuiltinDataType
import nl.ru.sws.connectordsl.connectorDSL.Component
import nl.ru.sws.connectordsl.connectorDSL.ComponentType
import nl.ru.sws.connectordsl.connectorDSL.ConditionalType
import nl.ru.sws.connectordsl.connectorDSL.Container
import nl.ru.sws.connectordsl.connectorDSL.DataType

import static nl.ru.sws.connectordsl.generator.util.Utils.*;

class Utils {
	
	static def String toStructType(Container container) {
        var s = new StringBuilder()
        for (c : container.components) {
            if (isBuiltinType(c) && !requiresCount(c) && !requiresLength(c)) {
                var type = toStructType((c.type as DataType).dataType)
                if (type.empty)
                    return s.toString
                s.append(type)
            } else
                return s.toString
        }
        return s.toString
    }
    
    static def String toStructType(BuiltinDataType dt) {
        switch (dt) {
            case UINT8: return "B"
            case USHORT: return "H"
            case UINT: return "I"
            case ULONG: return "Q"
            case INT8: return "b"
            case SHORT: return "h"
            case INT: return "i"
            case LONG: return "q"
            case FLOAT: return "f"
            case BOOLEAN: return "?"
            case BYTES: return ""
            case STRING: return ""
            case NONE: return ""
        }
    }
    
    static def String toPyType(BuiltinDataType dt) {
        switch (dt) {
            case UINT8: return "int"
            case USHORT: return "int"
            case UINT: return "int"
            case ULONG: return "int"
            case INT8: return "int"
            case SHORT: return "int"
            case INT: return "int"
            case LONG: return "int"
            case FLOAT: return "float"
            case BOOLEAN: return "str_to_bool"
            case BYTES: return "bytes"
            case STRING: return "str"
            case NONE: return ""
        }
    }
    
    static def String fromBytes(ComponentType type, String target, Component count, String identifier) {
        if (isConditionalType(type)) {
            return fromBytes(type as ConditionalType, target, count, identifier)
        } else {
            if (count === null)
                return '''«target», _buffer = «fromBytes(type as DataType, null)»'''
            else
                return 
'''«target» = []
for _ in range(«toUnderscore(count.name)»):
    e, _buffer = «fromBytes(type as DataType, null)»
    «target».append(e)
'''
        }
    }
    
    static def String fromBytes(ConditionalType type, String target, Component count, String identifier) {
        return
'''«target» = None
«FOR c : type.conditions»
if «IF identifier !== null»_request_cache[«toUnderscore(identifier)»].«ENDIF»«toUnderscore(type.component.name)» == «c.value»:
    «fromBytes(c.type, target, count, identifier)»
«ENDFOR»'''
    }
    
    static def String fromBytes(DataType type, String identifier) {
        if (isBuiltinType(type)) {
            if (type.dataType == BuiltinDataType.BYTES)
                return '''_buffer'''
            else if (type.dataType == BuiltinDataType.STRING)
                return '''bytes_to_string(_buffer)'''
            else if (type.dataType == BuiltinDataType.NONE)
                return '''None, _buffer'''
            else
                return '''from_bytes('«toStructType(type.dataType)»', _buffer)'''
        } else {
            return '''«type.container.name».from_bytes«IF type.container.fromSocket»_socket(_socket«ELSE»(_buffer«ENDIF»«IF type.container.responds !== null», «toUnderscore(type.container.identifier.component.name)»«ENDIF»)'''
        }
    }
    
    static def String fromBytes(DataType type, String src1, String src2, int offset) {
        return fromBytes(type, src1, src2, offset.toString)
    }
    
    static def String fromBytes(DataType type, String src1, String src2, String offset) {
        if (isBuiltinType(type)) {
            if (type.dataType == BuiltinDataType.NONE)
                return '''None'''
            else if (type.dataType == BuiltinDataType.BYTES)
                return '''«src2»[«offset»:]'''
            else if (type.dataType == BuiltinDataType.STRING) 
                return '''str(«src2»[«offset»+2:«offset»+struct.unpack('h', «src2»[«offset»:«offset»+2])[0]], 'utf-8)'''
            else
                return '''«src1»[«offset»]'''
        }
        return '''«type.container.name».from_bytes«IF type.container.fromSocket»_socket(«src2»)«ELSE»(«src2»«IF offset != "0"»[«offset»:]«ENDIF»)«ENDIF»'''        
    }
    
    static def String toBytes(Component component) {
        val name = toUnderscore(component.name)
        return toBytes(component.type, name, requiresCount(component))
    }
    
    static def String toBytes(ComponentType componentType, String name, boolean requiresCount) {
        if (isConditionalType(componentType)) {
            return '''b'' if self.«name» is None else self.«name».to_bytes()'''
//            val type = componentType as ConditionalType
//            var s = ''''''
//            for (c : type.conditions) {
//                s += '''«toBytes(c.type, name, requiresCount)» if self.«toUnderscore(type.component.name)» == «c.value» else '''
//            }
//            s += "b''"
//            return s
        } else {
            return toBytes(componentType as DataType, name, requiresCount)
        }
    }
    
    static def String toBytes(DataType type, String name, boolean requiresCount) {
        if (isBuiltinType(type)) {
                if (requiresCount) {
                    if (type == BuiltinDataType.STRING)
                        return '''b''.join([string_to_bytes(s) for s in self.«name»])'''
                    else
                        return '''list_to_bytes('«toStructType(type.dataType)»', self.«name»)'''
                } else {
                    if (type == BuiltinDataType.BYTES)
                        return '''self.«name»'''
                    else if (type == BuiltinDataType.STRING)
                        return '''b'' if self.«name» is None else string_to_bytes(self.«name»)'''
                    else
                        return '''b'' if self.«name» is None else to_bytes('«toStructType(type.dataType)»', self.«name»)'''
                }
            } else {
                if (requiresCount) {
                    return '''b''.join([i.to_bytes() for i in self.«name»])'''
                } else {
                    return '''b'' if self.«name» is None else self.«name».to_bytes()'''
                }
            }
    }
    
    static def String toDict(Container container) {
        return 
'''{
    «container.components.map[c | ''''«toUnderscore(c.name)»': «toDict(c, toUnderscore(c.name))»'''].join(",\n")»
}'''
    }
    
    static def String toDict(Component component, String name) {
        if (requiresCount(component))
            return '''[«toDict(component.type, "_" + name)» for _«name» in self.«name»]'''
        return '''«toDict(component.type, name, "self.")»«IF isConditionalType(component.type)» if self.«name» is not None else {}«ENDIF»'''
        
    }
    
    static def String toDict(ComponentType type, String name) {
        return toDict(type, name, null)
    }
    
    static def String toDict(ComponentType type, String name, String prefix) {
        if (isConditionalType(type)) {
            return '''self.«name».to_dict()'''
//            val t = type as ConditionalType
//            var s = ''''''
//            for (c : t.conditions) {
//                s += '''«toDict(c.type, name, prefix)» if self.«toUnderscore(t.component.name)» == «c.value» else '''
//            }
//            s += '''{}'''
//            return s
        } else
            return toDict(type as DataType, name, prefix)
    }
    
    static def String toDict(DataType type, String name) {
        return toDict(type, name, null)
    }
    
    static def String toDict(DataType type, String name, String prefix) {
        val _type = type as DataType
        if (_type.container === null)
            return '''«prefix ?: ''''''»«toUnderscore(name)»'''
        return '''«prefix ?: ''''''»«toUnderscore(name)».to_dict()'''
    }
    
    static def String fromDict(ComponentType componentType, String src, String target, boolean requiresCount, boolean isOptional) {
        if (!isConditionalType(componentType)) {
            val type = componentType as DataType
            if (requiresCount) {
                if (isBuiltinType(type))
                    return '''«target» = [«toPyType(type.dataType)»(e) for e in «src»['«target»']] «IF isOptional» if «src»['«target»'] is not None else None«ENDIF»'''
                else
                    return '''«target» = [«type.container.name».from_dict(e«IF type.container.responds !== null», «toUnderscore(type.container.identifier.component.name)»«ENDIF») for e in «src»['«target»']]«IF isOptional» if «src»['«target»'] is not None else None«ENDIF»'''
            } else {
                if (isBuiltinType(type)) {
                    if (type.dataType == BuiltinDataType.NONE)
                        return '''«target» = None'''
                    else
                        return '''«target» = «toPyType(type.dataType)»(«src»['«target»'])«IF isOptional» if «src»['«target»'] is not None else None«ENDIF»'''
                } else
                    return '''«target» = «type.container.name».from_dict(«src»['«target»']«IF type.container.responds !== null», «toUnderscore(type.container.identifier.component.name)»«ENDIF»)«IF isOptional» if «src»['«target»'] is not None else None«ENDIF»'''
            }
        } else {
            val type = componentType as ConditionalType
            return
'''«target» = None
«FOR c : type.conditions»
if «toUnderscore(type.component.name)» == «c.value»:
    «fromDict(c.type, src, target, false, isOptional)»
«ENDFOR»
'''
        }
    }
	
}
