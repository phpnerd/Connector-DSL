/*
 * Copyright (c) Thomas Nägele and contributors. All rights reserved.
 * Licensed under the MIT license. See LICENSE file in the project root for details.
*/

package nl.ru.sws.connectordsl.generator.python

import java.util.List
import nl.ru.sws.connectordsl.connectorDSL.ComType
import nl.ru.sws.connectordsl.connectorDSL.Configuration
import nl.ru.sws.connectordsl.connectorDSL.Container
import nl.ru.sws.connectordsl.connectorDSL.Handler
import nl.ru.sws.connectordsl.connectorDSL.Protocol

import static nl.ru.sws.connectordsl.generator.python.Utils.*;
import static nl.ru.sws.connectordsl.generator.util.Utils.*;

class PythonModelGenerator {
	
	static def generate(Configuration config, List<Container> containers, Handler handler)
'''
#!/usr/bin/python3

import argparse
import socket
import threading
from json import JSONEncoder, JSONDecoder
from distutils.util import strtobool
import time
«basicMethods»


«basicSerializerClass»


«IF containers.exists[c | c.responds !== null]»
_request_cache = {}


«ENDIF»
«containers.map[generate].join("\n\n")»

«mainGenerator(config, handler)»
'''
	
	static def generate(Container container)
'''
class «container.name»(Serializable):
    «generateInit(container)»

    «IF container.fromSocket»
    «generateFromBytesSocket(container)»
    «ELSE»
    «generateFromBytes(container)»
    «ENDIF»

    «generateToBytes(container)»

    «generateFromDict(container)»

    «generateToDict(container)»
'''

    static def generateInit(Container container)
'''
def __init__(self, «container.components.map[c | toUnderscore(c.name)].join(", ")»):
    «container.components.map[c | '''self.«toUnderscore(c.name)» = «toUnderscore(c.name)»'''].join("\n")»
'''

    static def generateFromBytes(Container container) {
        var identifier = null as String;
        if (container.responds !== null)
            identifier = container.identifier.component.name
'''
@staticmethod
def from_bytes(_buffer«IF identifier !== null», «toUnderscore(identifier)»«ENDIF»):
    «FOR c : container.components»
    «fromBytes(c.type, toUnderscore(c.name), c.count, identifier)»
    «ENDFOR»
    return «container.name»(«container.components.map[c | toUnderscore(c.name)].join(", ")»), _buffer
'''
    }

    static def generateFromBytesSocket(Container container) {
        var identifier = null as String;
        if (container.responds !== null)
            identifier = container.identifier.component.name
'''
@staticmethod
def from_bytes_socket(_socket«IF identifier !== null», «toUnderscore(identifier)»«ENDIF»):
    _buffer = _socket.read_bytes(length('«toStructType(container)»'))
    «FOR c : container.components»
    «IF requiresLength(c)»
    _buffer = _socket.read_bytes(«toUnderscore(c.byteCount.name)»)
    «ENDIF»
    «fromBytes(c.type, toUnderscore(c.name), c.count, identifier)»
    «ENDFOR»
    return «container.name»(«container.components.map[c | toUnderscore(c.name)].join(", ")»), _buffer
'''
    }

    static def generateToBytes(Container container) {
'''
def to_bytes(self):
    «FOR c : container.components.filter[c | !isByteCount(c, container)]»
    «IF isCount(c, container)»
    self.«toUnderscore(c.name)» = len(self.«toUnderscore(getCountTarget(c, container).name)»)
    «ENDIF»
    «toUnderscore(c.name)» = «toBytes(c)»
    «ENDFOR»
    «FOR c : container.components.filter[c | isByteCount(c, container)]»
    self.«toUnderscore(c.name)» = len(«toUnderscore(getByteCountTarget(c, container).name)»)
    «toUnderscore(c.name)» = «toBytes(c)»
    «ENDFOR»
    return b''.join([«container.components.map[c | toUnderscore(c.name)].join(", ")»])
'''
    }

    static def generateFromDict(Container container) {
        var identifier = null as String;
        if (container.responds !== null)
            identifier = container.identifier.component.name
'''
@staticmethod
def from_dict(_json«IF identifier !== null», «toUnderscore(identifier)»«ENDIF»):
    «FOR c : container.components»
    «fromDict(c.type, "_json", toUnderscore(c.name), requiresCount(c), isOptional(c))»
    «ENDFOR»
    return «container.name»(«container.components.map[c | toUnderscore(c.name)].join(", ")»)
'''
    }

    static def generateToDict(Container container)
'''
def to_dict(self):
    return «toDict(container)»
'''

    static def generateRepr(Container container)
'''
def __repr__(self):
    return str(self.to_dict())
'''
	
	static def basicSerializerClass()
'''
class Serializable:
    @staticmethod
    def from_bytes(_buffer):
        print('\'from_bytes\' is not yet implemented')
        raise NotImplementedError

    @staticmethod
    def from_bytes_socket(_socket):
        print('\'from_bytes_socket\' is not yet implemented')
        raise NotImplementedError

    def to_bytes(self):
        print('\'to_bytes\' is not yet implemented')
        return b''

    @staticmethod
    def from_dict(_json):
        print('\'from_dict\' is not yet implemented')
        raise NotImplementedError

    def to_dict(self):
        print('\'to_dict\' is not yet implemented')
        return '{}'

    def __repr__(self):
        return str(self.__class__.__name__) + ' ' + str(self.to_dict())
'''

    static def basicMethods()
'''
import struct


def length(fmt):
    return struct.calcsize('>' + fmt)


def from_bytes(fmt, buffer):
    l = length(fmt)
    res = struct.unpack('>' + fmt, buffer[0:l])
    return res[0] if len(fmt) == 1 else res, buffer[l:]


def to_bytes(fmt, *values):
    return struct.pack('>' + fmt, *values)


def list_to_bytes(fmt, list):
    return b''.join([to_bytes(fmt, i) for i in list])


def bytes_to_string(buffer):
    l, buffer = from_bytes('h', buffer)
    return str(buffer[0:l], 'utf-8'), buffer[l:]


def string_to_bytes(s):
    l = to_bytes('h', len(s))
    s_ = s.encode('utf-8')
    return l + s_


def str_to_bool(s):
    return bool(strtobool(str(s)))
'''

    static def mainGenerator(Configuration config, Handler handler)
'''

class Socket:
    def __init__(self, name, port, hostname=None, verbose=False):
        self.name = name
        self.port = port
        self.hostname = hostname
        self.verbose = verbose
        self.socket = None
        self.server = None
        self.is_server = hostname is None
        self.cache = b''

    def connect(self, udp=False):
        if self.socket is None:
            if self.is_server:
                self.server = socket.socket(socket.AF_INET, socket.SOCK_STREAM if not udp else socket.SOCK_DGRAM)
                self.server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                print('Waiting for connection on port ' + str(self.port) + '...')
                self.server.bind(('localhost', self.port))
                self.server.listen(5)
                (client, addr) = self.server.accept()
                self.socket = client
                print('Connected to ' + str(addr))

            else:
                print('Connecting to ' + self.hostname + ':' + str(self.port) + '...')
                while True:
                    try:
                        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                        self.socket.connect((self.hostname, self.port))
                        break
                    except ConnectionRefusedError:
                        time.sleep(1)
                print('Connected to ' + self.hostname + ':' + str(self.port))

    def close(self):
        self.socket.close()
        if self.is_server:
            self.server.close()

    def write_bytes(self, bs):
        self.socket.send(bs)
        if self.verbose:
            print('>> ' + self.name + ': ' + str(bs.hex()))

    def write_line(self, s):
        self.write_bytes(bytes(s, 'utf-8') + b'\n')

    def read_bytes(self, nr_of_bytes):
        bs = self.socket.recv(nr_of_bytes)
        if self.verbose:
            print('<< ' + self.name + ': ' + str(bs.hex()))
        return bs

    def read_line(self):
        buffer = [self.cache]
        while b'\n' not in b''.join(buffer):
            buffer.append(self.socket.recv(4096))
        line, self.cache = b''.join(buffer).split(b'\n', 1)
        st = line.decode('utf-8')
        if self.verbose:
            print('<< ' + self.name + ': ' + st)
        return st


def handle(«val bName = toUnderscore(config.base.name)»«bName», source, destination):
    «IF handler === null || handler.handler === null»
    return True
    «ELSE»
    «handler.handler»
    «ENDIF»


def run(source, destination, to_json=True, verbose=False):
    try:
        while True:
            if to_json:
                «bName», _ = «config.base.name».from_bytes_socket(source)
                if verbose:
                    print(' < ' + source.name + ': ' + str(«bName»))
                if handle(«bName», source, destination):
                    «bName»_json = JSONEncoder().encode(«bName».to_dict())
                    destination.write_line(«bName»_json)
            else:
                line = source.read_line()
                «bName»_json = JSONDecoder().decode(line)
                «bName» = «config.base.name».from_dict(«bName»_json)
                if verbose:
                    print(' < ' + source.name + ': ' + str(«bName»))
                if handle(«bName», source, destination):
                    «bName»_bytes = «bName».to_bytes()
                    destination.write_bytes(«bName»_bytes)
                    if verbose:
                        print(' > ' + destination.name + ': ' + str(«bName»_bytes.hex()))
    except ConnectionError:
        return
    except NotImplementedError:
        return

«val cName = config.client.name.toLowerCase»
«val sName = config.server.name.toLowerCase»

parser = argparse.ArgumentParser(description='Connect «cName» with «sName» via sockets speaking different protocols.')
parser.add_argument('-c', '--«cName»', type=int, dest='«cName»_port', required=True,
                    help='The port that should listen for the «config.client.name» connection')
parser.add_argument('-s', '--«sName»', type=str, dest='«sName»_host', required=True,
                    help='The hostname of «config.server.name» to connect to')
parser.add_argument('-p', '--«sName»_port', type=int, dest='«sName»_port', required=True,
                    help='The port of «config.server.name» to connect to')
parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', default=False)
parser.add_argument('-d', '--debug', dest='debug', action='store_true', default=False)
args = parser.parse_args()

# Connect to «config.server.name»
«sName»_socket = Socket('«config.server.name»', args.«sName»_port, args.«sName»_host, verbose=args.debug)
«sName»_socket.connect(udp=«(config.server.protocol == Protocol.UDP).toString.toFirstUpper»)
# Wait for «config.client.name»
«cName»_socket = Socket('«config.client.name»', args.«cName»_port, verbose=args.debug)
«cName»_socket.connect(udp=«(config.client.protocol == Protocol.UDP).toString.toFirstUpper»)

«sName.toFirstLower»_thread = threading.Thread(target=run, args=[«sName»_socket, «cName»_socket, «(config.client.type == ComType.JSON).toString.toFirstUpper», args.verbose], daemon=True)
«sName.toFirstLower»_thread.start()

try:
    run(«cName»_socket, «sName»_socket, to_json=«(config.server.type == ComType.JSON).toString.toFirstUpper», verbose=args.verbose)
    «sName»_socket.close()
    «cName»_socket.close()
except KeyboardInterrupt:
    «sName»_socket.close()
    «cName»_socket.close()
'''
	
}
