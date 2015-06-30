package pragma.events {

	import flash.utils.getQualifiedClassName;
	
	import pragma.interfaces.$IListener;
	import pragma.namespaces.pragma;
	import pragma.utils.Loop;
	import pragma.utils.classUtils.singleton;
		
	public class EventDispatcher implements IEventDispatcher {
		
		private var _listeners:Vector.<Listener> = new Vector.<Listener>();
		protected function get loop():Loop {return singleton(Loop)}
	    
	    public function addEventListener ($type:String, $handler:Function, $useCapture:Boolean = false, $priority:int = 0, $useWeakReference:Boolean = false):void {
			//trace('EventDispatcher::addEventListener');
	        if ($useWeakReference) {
	            // we can't do this properly with our current data structure (just ignore for now?)
	            throw new Error("we can't do \"useWeakReference\" properly with our current data structure");            
	        }
			var listener:Listener = new Listener(this, $type, $handler, $useCapture, $priority);
	        _listeners.push(listener); 
	    }
	
	    public function removeEventListener ($type: String, $handler: Function, $useCapture: Boolean = false):void {
			//trace('EventDispatcher::removeEventListener',arguments);
			var listener:Listener;
			var i:int = _listeners.length-1;
			for(i; i>=0; i--) {
				listener = _listeners[i];
				if (listener.type == $type && listener.handler === $handler && listener.useCapture === $useCapture) {
					_listeners.splice(i,1);
					return;
				}
			}
	    }
	
	    public function dispatchEvent (event :Event) :Boolean {
			//trace('EventDispatcher::dispatchEvent');
			if (event.target) {
				event=event.clone();
			}
			event.pragma::target = this;
			var listener:Listener;
			var i:int = _listeners.length-1;
			_listeners.sort(function(first:Listener,second:Listener):int{ //implement priority
				return first.priority-second.priority;
			});
			for(i; i>=0; i--) {
				if (i<_listeners.length) { // because can unsubscribe some listeners while apply handlers
					listener = _listeners[i];
					if (listener.type == event.type) {
						if (listener.useCapture) {
							//useCapture - listeners will be called immediatly
							pragma::applyEvent(listener, event); //listener.handler.call(null,event);
						} else {
							//useCapture - listeners will be called on next Loop tick
							loop.pragma::applyListenersQueue(listener, event);
						}
					}
				}
			}
			
	        return !event.isDefaultPrevented();
	    }
		
	    pragma function applyEvent(listener: $IListener, event: Event):void {
			listener.handler.call(null,event);
		}
	
	    public function hasEventListener ($type :String) :Boolean {
			//trace('EventDispatcher::hasEventListener');
			var listener:Listener;
			var i:int;
			for(i=_listeners.length-1; i>=0; i--) {
				listener = _listeners[i];
				if (listener.type == $type) {
					return true;
				}
			}
	        return false;
	    }
	
	    public function toString () :String {
	        return "[EventDispatcher "+getQualifiedClassName(this)+"]";
	    }
	
	}

	internal class Listener implements $IListener {
		

		public function get handler():Function {return _handler;}
		public function set handler(value:Function):void {_handler = value;}
		public function get type():String {return _type;}
		public function set type(value:String):void {_type = value;}
		public function get useCapture():Boolean {return _useCapture;}
		public function set useCapture(value:Boolean):void {_useCapture = value;}
		public function get priority():int {return _priority;}
		public function set priority(value:int):void {_priority = value;}
		public function get dispatcher():IEventDispatcher {return _dispatcher;}
		public function set dispatcher(value:IEventDispatcher):void {_dispatcher = value;}
		private var _dispatcher:IEventDispatcher;
		private var _handler:Function;
		private var _type:String;
		private var _useCapture:Boolean;
		private var _priority:int;
	
		protected function get loop():Loop {return singleton(Loop)}
	
		public function Listener($dispatcher:IEventDispatcher, $type:String, $handler:Function, $useCapture:Boolean, $priority: int) {
			super();
			dispatcher = $dispatcher;
			handler = $handler;
			type = $type;
			useCapture = $useCapture;
			priority = $priority;
		}
		
		public function toString():String {
			return "[Listener:"+type+"]"; 
		}
	}
}

