package pragma.net {

	import flash.errors.IOError;
	import flash.net.ObjectEncoding;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import C.arpa.inet.htonl;
	import C.arpa.inet.htons;
	import C.arpa.inet.inet_ntoa;
	import C.errno.CError;
	import C.errno.errno;
	import C.netdb.gethostbyname;
	import C.netdb.hostent;
	import C.netinet.IPPROTO_TCP;
	import C.netinet.sockaddr_in;
	import C.stdlib.EXIT_FAILURE;
	import C.stdlib.exit;
	import C.sys.select.FD_SET;
	import C.sys.select.FD_ZERO;
	import C.sys.select.fd_set;
	import C.sys.select.timeval;
	import C.sys.socket.AF_INET;
	import C.sys.socket.AF_UNIX;
	import C.sys.socket.SHUT_RDWR;
	import C.sys.socket.SOCK_RAW;
	import C.sys.socket.SOCK_SEQPACKET;
	import C.sys.socket.SOCK_STREAM;
	import C.sys.socket.connect;
	import C.sys.socket.recv;
	import C.sys.socket.sendall;
	import C.sys.socket.shutdown;
	import C.sys.socket.sockaddr;
	import C.sys.socket.socket;
	import C.unistd.sleep;
	
	import pragma.events.Event;
	import pragma.events.EventDispatcher;
	import pragma.events.IOErrorEvent;
	import pragma.events.ProgressEvent;
	import pragma.events.TimerEvent;
	import pragma.interfaces.$ILoopEntry;
	import pragma.namespaces.pragma;
	import pragma.utils.Loop;
	import pragma.utils.Timer;
	import pragma.utils.classUtils.singleton;
	
	import shell.Program;
	import shell.Runtime;
	
	public class Socket extends EventDispatcher implements IDataInput, IDataOutput, $ILoopEntry {
		
		public function notifyRegister($loop:Loop):void {
			//trace(this,"Socket::notifyRegister");
			//Runtime.eval('trace(this,"Socket::notifyRegister");');
		}
		public function notifyUnregister($loop:Loop):void {
			////Logger.debug(this,"Socket::notifyUnregister");
		}
		
		private var _socketID:int = -1;
		
	    public function Socket (host :String = null, port :int = 0)
	    {
	    	//trace("Making socket.");
	    	
	        _state = ST_VIRGIN;
			
	        if (host != null && port > 0) {
	            connect(host, port);
	        }
			
	    }
	    
	    public function connect (host: String, port: int) :void
	    {
	    	//trace("Connecting for some reason");
	
	        _host = host;
	        _port = port;
			
			nb_connect();
			
	//        if (!host) {
	//            throw new IOError("No host specified in connect()");
	//        }
	//
	//        if (_state == ST_WAITING) {
	//            return;
	//        }
	//
	//        if (_state == ST_CONNECTED) {
	//            close();
	//        }
	//
	//        _host = host;
	//        _port = port;
	//
	//        _state = ST_WAITING;
	//        trace("Socket:connect() switching to ST_WAITING...");
	    }
	
	    public function close () :void
	    {
	
	//    	trace("Closing for some reason");
	        if (_state != ST_CONNECTED) 
	        {
	            throw new IOError("Socket was not open");
	        }
	        nb_disconnect();
	        _state = ST_VIRGIN;
	        // do not dispatch CLOSE for an explicit close-down
	    }
	
	    public function heartbeat ():Boolean
	    {
	       var e:Event = null;
	       
	        switch(_state) {
	        case ST_BROKEN:
	        case ST_VIRGIN:
	            break;
	
	        case ST_CONNECTED:
	            //trace("Processing connected socket.");
	            _oBuf.position = _oPos;
	            var wrote :int = 0;
	
	            var read :int = nb_read(_iBuf);
	            if (read < 0) 
	            {
	                if (read == -1) 
	                {
	                    e = new IOErrorEvent(IOErrorEvent.IO_ERROR);
//	                    e.target = this;
	                    dispatchEvent(e);
	                }
	                
	                // if read == -2, the other end disconnected
	                nb_disconnect();
	                _state = ST_VIRGIN;
	                
	                // dispatch the CLOSE event
					////Logger.debug(this,"socket was disconnected.");
					
	                e = new Event(Event.CLOSE);
//	                e.target = this;
	                dispatchEvent(e);
	                return this.connected;
	            }
	            
	            // Data to write!
	            if (_oPos < _oBuf.length)
	                wrote = nb_write(_oBuf);
	            
	
	            //if (read > 0 || wrote > 0) {
	            //    trace("Socket:heartbeat() read " + read + ", wrote " + wrote);
	            //}
	
	            _iBuf = massageBuffer(_iBuf);
	            _oBuf = massageBuffer(_oBuf);
	
	            _oPos = _oBuf.position;
	
	            if (read > 0) 
	            {
	                _bytesTotal += read;
	                e = new ProgressEvent(ProgressEvent.SOCKET_DATA);
//	                e.target = this;
	                dispatchEvent(e);
	            }
	
	            break;
	
	        case ST_WAITING:
	            switch(nb_connect(/*_host, _port*/)) {
	            case -1:
	            	e = new IOErrorEvent(IOErrorEvent.IO_ERROR);
//	            	e.target = this;
	                dispatchEvent(e);
	                _state = ST_VIRGIN;
	                break;
	            case 0:
					////Logger.debug(this,"Socket:heartbeat() trying to connect...");

	                break;
	            case 1:
					////Logger.debug(this,"Socket:heartbeat() connected!");
	                _state = ST_CONNECTED;
	                
	                e = new Event(Event.CONNECT);
//	                e.target = this;
	                dispatchEvent(e);
	                
	                break;
	            }
	        }
			return this.connected;
	    }
	
	    private function nb_disconnect():void
		{
	////		TODO
	//		throw new Error("try to call not implemented method 'nb_disconnect'");
			////Logger.debug(this,"Socked::nb_disconnect()");
			shutdown(_socketID,SHUT_RDWR);
			
//			var loop:Loop = singleton(Loop);
			loop.pragma::removeEntry(this);
		}
	
	    /** Returns -1 for error, 0 for keep trying, 1 for success. */
	    private function nb_connect (/*host :String, port :int*/):int {
			////Logger.debug(this,"Socked::nb_connect()");
			var sockfd:int = socket( AF_INET, SOCK_STREAM, 0 );
			if( sockfd < 0 ) {
				////Logger.error(this,"socket error" );
				////Logger.error(this, new CError( "", errno ).toString() );
				exit( EXIT_FAILURE );
			}
			
			var he:hostent = gethostbyname( _host );
			
			var my_addr:sockaddr_in = new sockaddr_in();
			my_addr.sin_family = AF_INET;
			my_addr.sin_port = htons( _port );
			//my_addr.sin_addr.s_addr = inet_addr( "10.12.110.57" ); // directly input the IP
			my_addr.sin_addr = he.h_addr; // reuse the 1st IP from hostent
			
			var ip:String = inet_ntoa( my_addr.sin_addr );
			////Logger.debug(this,"Connecting to " + ip );
			
			var conn:int = C.sys.socket.connect( sockfd, my_addr );
			if( conn < 0 ) {
				////Logger.error(this,"connection error" );
				////Logger.error(this,new CError( "", errno ).toString() );
				//close( sockfd );
				exit( EXIT_FAILURE );
			}
			
			_socketID = sockfd;
			_state = ST_CONNECTED;
			
//			var loop:Loop = singleton(Loop);
			loop.pragma::addEntry(this);
			
			dispatchEvent(new Event(Event.CONNECT));
				
			return 1;
		}
	
	    /** Returns -1 for error, else the number of bytes read. */
	    private function nb_read (iBuf :ByteArray):int
		{
			//TODO
	//		throw new Error("try to call not implemented method 'nb_read'");
	//		return 0;
			var len:int = 4096;
			var flags:int = 0;
			var total:uint = 0; // how many bytes we received
			var n:int;
			var b:ByteArray = new ByteArray();
			var run:Boolean = true;
			var rfd:fd_set = new fd_set();
			var tv:timeval = new timeval(0,0);
			var _prePosition:int = _iBuf.position;
			FD_ZERO(rfd);
			
			outerLoop: while( run ) {
				b.clear();
				
				FD_SET(_socketID,rfd);
				var sl:int = C.sys.select.select( _socketID+1, rfd, null, null, tv );
				switch(sl) {
					case -1: 
						//error
	//					trace('**** exit on "select == -1"');
						run = false;
						break outerLoop;
					case 0: 
						//no data
	//					trace('**** exit on no data');
						break outerLoop;
					case 1: 
						//data available
	//					trace('**** recieve data');
						n = recv( _socketID, b, len, flags );
						total += n;
						b.position=0;
						_iBuf.writeBytes( b );
						if( n == 0 ) {
							run = false;
							break outerLoop;
						}
						if( n == -1 ) {
							run = false;
							break outerLoop;
						}
						break;
				}
			}
			
			FD_ZERO(rfd);
			_iBuf.position=_prePosition;
			return total;
		}
	
	    /** Returns -1 for error, else the number of bytes written. */
	    private function nb_write (oBuf :ByteArray):int {
			oBuf.position=0;
			var to:String = "" ;//test output
			for (var i:int=0; i<oBuf.length; i++) {
				oBuf.position=i;
				to+=oBuf.readUTFBytes(1);
			}
			////Logger.debug(this,"DEBUG [SEND "+to.length+"]: " + to);
	
			
			oBuf.position=0;
			sendall( _socketID, oBuf);
			var l:int = oBuf.length;
			oBuf.clear();
			return l;
		}
	    
	    public function listen(port:int):Boolean {
			//TODO
			throw new Error("try to call not implemented method 'listen'");
			return false;
		}
	    public function accept():Socket
		{
			//TODO
			throw new Error("try to call not implemented method 'accept'");
			return null;
		}
	    public function hasConnection():Boolean
		{
			return false;
		}
	
	    public function flush () :void
	    {
	        // TODO: we should probably respect flush somehow...
	    }
	
	    public function get connected () :Boolean
	    {
	        return _state == ST_CONNECTED;
	    }
	
		public function get endian(): String
	    {
	        return _iBuf.endian;
	    }
	
		public function set endian(type: String) :void
	    {
	        _iBuf.endian = type;
	        _oBuf.endian = type;
	    }
	
	    public function get bytesAvailable () :uint
	    {
	        return _iBuf.bytesAvailable;
	    }
	
	    public function set objectEncoding (encoding :uint) :void
	    {
	        if (encoding != ObjectEncoding.AMF3) {
	            throw new Error("Only AMF3 supported");
	        }
	    }
	
	    public function get objectEncoding () :uint
	    {
	        return ObjectEncoding.AMF3;
	    }
	
	    // IDataInput
	    public function readBytes(bytes :ByteArray, offset :uint=0, length :uint=0) :void
	    {
	        return _iBuf.readBytes(bytes, offset, length);
	    }
	
	    public function readBoolean() :Boolean
	    {
	        return _iBuf.readBoolean();
	    }
	
	    public function readByte() :int
	    {
	        return _iBuf.readByte();
	    }
	
	    public function readUnsignedByte() :uint
	    {
	        return _iBuf.readUnsignedByte();
	    }
	
	    public function readShort() :int
	    {
	        return _iBuf.readShort();
	    }
	
	    public function readUnsignedShort() :uint
	    {
	        return _iBuf.readUnsignedShort();
	    }
	
	    public function readInt() :int
	    {
	        return _iBuf.readInt();
	    }
	
	    public function readUnsignedInt() :uint
	    {
	        return _iBuf.readUnsignedInt();
	    }
	
	    public function readFloat() :Number
	    {
	        return _iBuf.readFloat();
	    }
	
	    public function readDouble() :Number
	    {
	        return _iBuf.readDouble();
	    }
	
	    public function readUTF() :String
	    {
	        return _iBuf.readUTF();
	    }
	
	    public function readUTFBytes(length :uint) :String
	    {
	        return _iBuf.readUTFBytes(length);
	    }
	
	    // IDataOutput
	    public function writeBytes(bytes :ByteArray, offset :uint = 0, length :uint = 0) :void
	    {
	        _oBuf.writeBytes(bytes, offset, length);
	    }
	
	    public function writeBoolean(value :Boolean) :void
	    {
	        _oBuf.writeBoolean(value);
	    }
	
	    public function writeByte(value :int) :void
	    {
	        _oBuf.writeByte(value);
	    }
	
	    public function writeShort(value :int) :void
	    {
	        _oBuf.writeShort(value);
	    }
	
	    public function writeInt(value :int) :void
	    {
	        _oBuf.writeInt(value);
	    }
	
	    public function writeUnsignedInt(value :uint) :void
	    {
	        _oBuf.writeUnsignedInt(value);
	    }
	
	    public function writeFloat(value :Number) :void
	    {
	        _oBuf.writeFloat(value);
	    }
	
	    public function writeDouble(value :Number) :void
	    {
	        _oBuf.writeDouble(value);
	    }
	
	    public function writeUTF(value :String) :void
	    {
	        _oBuf.writeUTF(value);
	    }
	
	    public function writeUTFBytes(value :String) :void
	    {
	        _oBuf.writeUTFBytes(value);
	    }
	
	    // AMF3 bits
	    public function readObject () :*
	    {
			//TODO
			throw new Error("try to read AMF object: not implemented");
	        //return AMF3Decoder.decode(this);
	    }
	
	    public function writeObject (object :*) :void
	    {
			//TODO
			throw new Error("try to write AMF object: not implemented");
	        //AMF3Encoder.encode(this, object);
	    }
		
		public function readMultiByte(length:uint, charSet:String):String
		{
			//TODO
			throw new Error("try to read MultiByte: not implemented");
			return "";
		}
		public function writeMultiByte(value:String, charSet:String):void
		{
			//TODO
			throw new Error("try to write MultiByte: not implemented");
		}
	
	    protected function massageBuffer (buffer :ByteArray) :ByteArray
	    {
	        // we only switch buffers if we're wasting 25% and at least 64k
	        if (buffer.position < 0x10000 || 4*buffer.position < buffer.length) 
	        {
	            return buffer;
	        }
	
	        var newBuffer :ByteArray = new ByteArray();
	
	        if (buffer.bytesAvailable > 0) {
	            buffer.readBytes(newBuffer, 0, buffer.bytesAvailable);
	        }
	        return newBuffer;
	    }
	
	    private var _state :int = ST_BROKEN;
	    private var _host :String;
	    private var _port :int;
	
	    private var _iBuf :ByteArray = new ByteArray();
	    private var _oBuf :ByteArray = new ByteArray();
	
	    // we have to keep our own position in oBuf because writing changes it (?!)
	    private var _oPos :int = 0;
	
	    private var _bytesTotal :int = 0;
	
	    private static const ST_BROKEN :int = 0;
	    private static const ST_VIRGIN :int = 1;
	    private static const ST_WAITING :int = 2;
	    private static const ST_CONNECTED :int = 3;
		
		public override function toString () :String
		{
			return "[Socket]";
		}
	}
}
