/*
 * Copyright (c) Thomas Nägele and contributors. All rights reserved.
 * Licensed under the MIT license. See LICENSE file in the project root for details.
*/

package nl.ru.sws.connectordsl.generator.util

import com.google.common.base.CaseFormat
import nl.ru.sws.connectordsl.connectorDSL.Component
import nl.ru.sws.connectordsl.connectorDSL.ComponentType
import nl.ru.sws.connectordsl.connectorDSL.ConditionalType
import nl.ru.sws.connectordsl.connectorDSL.Container
import nl.ru.sws.connectordsl.connectorDSL.DataType

class Utils {
	
	static def toUnderscore(String s) {
        return CaseFormat.UPPER_CAMEL.to(CaseFormat.LOWER_UNDERSCORE, s);
    }
    
    static def boolean isBuiltinType(Component component) {
        return isBuiltinType(component.type)
    }
    
    static def boolean isBuiltinType(ComponentType type) {
        return type instanceof DataType && (type as DataType).container === null
    }
    
    static def boolean requiresLength(Component component) {
        return component.byteCount !== null
    }
    
    static def boolean requiresCount(Component component) {
        return component.count !== null
    }
    
    static def isConditionalType(Component component) {
        return isConditionalType(component.type)
    }
    
    static def isConditionalType(ComponentType type) {
        return type instanceof ConditionalType
    }
    
    static def isOptional(Component component) {
        return component.optional
    }
    
    static def isCount(Component component, Container container) {
        for (c : container.components)
            if (c.count == component)
                return true
        return false
    }
    
    static def isByteCount(Component component, Container container) {
        for (c : container.components)
            if (c.byteCount == component)
                return true
        return false
    }
    
    static def getCountTarget(Component component, Container container) {
        for (c : container.components)
            if (c.count == component)
                return c
        return null
    }
    
    static def getByteCountTarget(Component component, Container container) {
        for (c : container.components)
            if (c.byteCount == component)
                return c
        return null
    }
	
}
