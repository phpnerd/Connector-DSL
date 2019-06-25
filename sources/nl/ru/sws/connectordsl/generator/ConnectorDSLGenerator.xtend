/*
 * Copyright (c) Thomas Nägele and contributors. All rights reserved.
 * Licensed under the MIT license. See LICENSE file in the project root for details.
*/

package nl.ru.sws.connectordsl.generator

import nl.ru.sws.connectordsl.connectorDSL.Configuration
import nl.ru.sws.connectordsl.connectorDSL.Container
import nl.ru.sws.connectordsl.connectorDSL.Handler
import nl.ru.sws.connectordsl.generator.poosl.PooslModelGenerator
import nl.ru.sws.connectordsl.generator.python.PythonModelGenerator
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext


class ConnectorDSLGenerator extends AbstractGenerator {

  override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
    val configuration = resource.allContents.findFirst[c | c instanceof Configuration] as Configuration
    val handler = resource.allContents.findFirst[c | c instanceof Handler] as Handler
    val containers = resource.allContents.filter(Container).toList
    fsa.generateFile(configuration.server.name.toLowerCase + "Connector.py", PythonModelGenerator.generate(configuration, containers, handler))
    fsa.generateFile(configuration.server.name + "-lib.poosl", PooslModelGenerator.generate(containers, configuration))
  }
}
