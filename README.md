# Connector DSL
The Connector DSL is a domain specific language to quickly specify a protocol.
It is meant for the connection of two sockets where one end communicates using raw bytes, while the other communicates using JSON strings.
From a protocol specification, POOSL classes and a Python connector are generated.
The Connector DSL was created using [Xtext](https://www.eclipse.org/Xtext/) and [Xtend](https://www.eclipse.org/xtend/) for [Eclipse](https://www.eclipse.org/).

**Disclaimer** The sources included in this project are provided as-is. These sources are currently still lacking proper comments and documentation. This may be added in the future. Also, this README is known to be incomplete.

## Structure
The structure of this repository is as follows.

* **plugin** contains the compressed plugin file that could be installed in Eclipse.
* **examples** contains one SimpleChat example project for a very basic protocol.
* **sources** contains the sources of the DSL itself.

## Installation
The Connector DSL project can be imported by creating a new Xtext project having the name ```nl.ru.sws.connectordsl``` with extension "cdsl".

The Connector DSL extension for Eclipse can be installed by adding the repository as software source to Eclipse.
The repository location is [https://files.thomasnagele.nl/cdsl/plugin/](https://files.thomasnagele.nl/cdsl/plugin/).
After having added this repository, the latest version of the Connector DSL can be installed from it.
Alternatively, the plugin can be installed from the compressed file located in the *plugin* folder.
