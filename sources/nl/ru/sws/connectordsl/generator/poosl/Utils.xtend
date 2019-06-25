/*
 * Copyright (c) Thomas Nägele and contributors. All rights reserved.
 * Licensed under the MIT license. See LICENSE file in the project root for details.
*/

package nl.ru.sws.connectordsl.generator.poosl

import nl.ru.sws.connectordsl.connectorDSL.BuiltinDataType
import nl.ru.sws.connectordsl.connectorDSL.Component
import nl.ru.sws.connectordsl.connectorDSL.ComponentType
import nl.ru.sws.connectordsl.connectorDSL.ConditionalType
import nl.ru.sws.connectordsl.connectorDSL.DataType

import static nl.ru.sws.connectordsl.generator.util.Utils.*;

class Utils {
	
	static def String toType(Component component) {
        if (component.count !== null)
            return "Sequence"
        val type = component.type
        if (type instanceof DataType) {
            if (isBuiltinType(type)) {
                switch (type.dataType) {
                    case UINT8: return "Integer"
                    case USHORT: return "Integer"
                    case UINT: return "Integer"
                    case ULONG: return "Integer"
                    case INT8: return "Integer"
                    case SHORT: return "Integer"
                    case INT: return "Integer"
                    case LONG: return "Integer"
                    case FLOAT: return "Real"
                    case BOOLEAN: return "Boolean"
                    case STRING: return "String"
                    case BYTES: return "Array"
                    case NONE: return "Nil"
                }
            } else
                return type.container.name
        } else
            return "Object"
    }
    
    static def String toMap(Component component, String counter, boolean responds) {
        val name = component.name
        if (requiresCount(component)) {
            if (isConditionalType(component) || !isBuiltinType(component))
                return 
'''«name»_ := new(Array) resize(«name» size);
«counter» := 1;
while i <= «name»_ size do
    «name»_ putAt(i, «name» at(i) toMap);
    i := i + 1
od'''
            else
                return '''«name»_ := «name» toArray'''
        } else if (isConditionalType(component) || !isBuiltinType(component)) {
            return 
'''if «name» = nil then
    «name»_ := nil
else
    «IF responds»
    «name»_ := «name» toMap
    «ELSE»
    «setter(component.type, name + "_", name, true, false)»
    «ENDIF»
fi'''
        } else {
            return '''«name»_ := «name»'''
        }
    }
   
    static def String toMapType(Component component) {
        if (requiresCount(component))
            return "Array"
        if (isConditionalType(component) || !isBuiltinType(component))
            return "Map"
        else
            return toType(component)
    }
    
    static def String setter(ComponentType type, String target, String src, boolean nested, boolean fromMap) {
        var i = 0
        if (isConditionalType(type)) {
            val t = type as ConditionalType
            return
'''«FOR c : t.conditions»
if «t.component.name»_ = «c.value» then
    «setter(c.type, target, src, true, fromMap)»
fi«IF !nested || (i++ < t.conditions.size-1)»;«ENDIF»«ENDFOR»
'''
        } else {
            if (isBuiltinType(type))
                return '''«target» := «IF (type as DataType).dataType == BuiltinDataType.NONE»nil«ELSE»«src»«ENDIF»'''
            else
                return '''«target» := «IF fromMap»new(«(type as DataType).container.name») fromMap(«src»)«ELSE»«src» toMap«ENDIF»'''
        }
    }
    
}
