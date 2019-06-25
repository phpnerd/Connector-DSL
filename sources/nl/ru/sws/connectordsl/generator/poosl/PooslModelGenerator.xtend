/*
 * Copyright (c) Thomas Nägele and contributors. All rights reserved.
 * Licensed under the MIT license. See LICENSE file in the project root for details.
*/

package nl.ru.sws.connectordsl.generator.poosl

import java.util.List
import nl.ru.sws.connectordsl.connectorDSL.Configuration
import nl.ru.sws.connectordsl.connectorDSL.Container
import nl.ru.sws.connectordsl.connectorDSL.DataType

import static nl.ru.sws.connectordsl.generator.poosl.Utils.*;
import static nl.ru.sws.connectordsl.generator.util.Utils.*;

class PooslModelGenerator {
	
	static def generate(List<Container> containers, Configuration config)
'''
import "structures.poosl"
import "json.poosl"

«containers.map[generate].join("\n\n")»
'''

    static def generate(Container container) {
        val listComps = container.components.filter[c | c.count !== null]
        val nonListComps = container.components.filter[c | c.count === null]
        val conditionalComps = container.components.filter[c | isConditionalType(c)]
'''
data class «container.name» extends Object
variables
    «FOR c : container.components»
    «c.name» : «toType(c)»
    «ENDFOR»
methods
    «FOR c : container.components»
    get«c.name.toFirstUpper» : «toType(c)»
        return «c.name»
    set«c.name.toFirstUpper»(«c.name»_ : «toType(c)») : «container.name»
        «c.name» := «c.name»_;
        return self
    «ENDFOR»
    
    set(«container.components.map[c | c.name + "_ : " + toType(c)].join(", ")») : «container.name»
        «FOR c : container.components»
        «c.name» := «c.name»_;
        «ENDFOR»
        return self
    
    «IF container.responds === null»
    fromMap(json : Map) : «container.name»«IF !listComps.empty || !conditionalComps.empty» | «IF !listComps.empty»«listComps.map[c | c.name + "List"].join(", ")» : Sequence, i : Integer, «ENDIF»«nonListComps.map[c | c.name + "_ : " + toType(c)].join(", ")» |«ENDIF»
        «IF listComps.empty && conditionalComps.empty»
        return self set(«container.components.map[c | {
            if (isConditionalType(c)) {
                return ''''''
            } else {
                val type = c.type as DataType
                if (isBuiltinType(c))
                    return '''json at("«toUnderscore(c.name)»")'''
                else
                    return '''new(«type.container.name») fromMap(json at("«toUnderscore(c.name)»"))'''
            }
        }].join(", ")»)
        «ELSE»
        «FOR c : nonListComps»
        «c.name»_ := «IF isConditionalType(c)»nil«ELSE»json at("«toUnderscore(c.name)»")«ENDIF»;
        «ENDFOR»
        «FOR c : conditionalComps»
        «setter(c.type, '''«c.name»_''', '''json at("«toUnderscore(c.name)»")''', false, true)»
        «ENDFOR»
        «FOR c : listComps»
        «c.name»List := new(Sequence)«IF isBuiltinType(c)» fromArray(json at("«toUnderscore(c.name)»"))«ENDIF»;
        «IF !isBuiltinType(c) && !isConditionalType(c)»
        i := 1;
        while i <= «c.count.name»_ do
            «c.name»List append(new(«(c.type as DataType).container.name») fromMap(json at("«toUnderscore(c.name)»") at(i)));
            i := i + 1
        od;
        «ENDIF»
        «ENDFOR»
        return self set(«container.components.map[c | {
            if (c.count === null)
                return c.name + "_"
            else
                return c.name + "List"
        }].join(", ")»)
        «ENDIF»
    «ENDIF»
    
    toMap : Map | json : Map, «container.components.map[c | '''«c.name»_ : «toMapType(c)»'''].join(", ")»«IF !listComps.empty», i : Integer«ENDIF» |
        json := new(Map);
        «container.components.map[c | toMap(c, "i", container.responds !== null)].join(";\n")»;
        json «container.components.map[c | '''putAt("«toUnderscore(c.name)»", «c.name»_)'''].join(" ")»;
        return json
    
    printString : String
        return self toMap printString
'''
    }
	
}
