/*
 * Copyright (c) Thomas Nägele and contributors. All rights reserved.
 * Licensed under the MIT license. See LICENSE file in the project root for details.
*/

package nl.ru.sws.connectordsl.scoping

import nl.ru.sws.connectordsl.connectorDSL.ComponentReference
import nl.ru.sws.connectordsl.connectorDSL.ConditionalType
import nl.ru.sws.connectordsl.connectorDSL.Container
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.Scopes

import static nl.ru.sws.connectordsl.connectorDSL.ConnectorDSLPackage.Literals.*


class ConnectorDSLScopeProvider extends AbstractConnectorDSLScopeProvider {
	
	override getScope(EObject context, EReference reference) {
        if (context instanceof ConditionalType)
            return getScope(context, reference)
        if (context instanceof ComponentReference)
            return getScope(context, reference)
        return super.getScope(context, reference)
    }
    
    def getScope(ConditionalType condType, EReference ref) {
        var dt = condType.eContainer
        while (!(dt instanceof Container))
            dt = dt.eContainer
        val t = dt as Container
        if (t.responds !== null)
            return Scopes.scopeFor(t.responds.components)
        return super.getScope(condType, ref)
    }
    
    def getScope(ComponentReference compRef, EReference ref) {
        if (ref == COMPONENT_REFERENCE__COMPONENT)
            if (compRef.container !== null && compRef.container.components !== null)
                return Scopes.scopeFor(compRef.container.components)
        return super.getScope(compRef, ref)
    }

}
